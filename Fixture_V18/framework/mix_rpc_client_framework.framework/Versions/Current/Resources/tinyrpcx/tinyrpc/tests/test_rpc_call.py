import time
import pytest
import ujson as json
import ctypes
import re
import os
import uuid
from threading import Thread
from threading import Event
from publisher import *
from tinyrpc.config import THREAD_POOL_WORKERS
from tinyrpc.exc import RPCError
from tinyrpc.dispatch import public
from rpc_client import RPCClientWrapper
from rpc_server import RPCServerWrapper
from DummyRPCService import DummyRPCService
from DummyRPCService import driver
from tinyrpc import RUNNING, DONE, TIMEOUT, ERROR
from tinyrpc.protocols.jsonrpc import JSONRPCRequest
from tinyrpc.protocols.jsonrpc import JSONRPCMethodNotFoundError
from mock import patch
from mock import mock_open


ENDPOINT_SERVER = {'receiver': 'tcp://127.0.0.1:8889', 'replier': 'tcp://127.0.0.1:18889'}
ENDPOINT_CLIENT = {'requester': 'tcp://127.0.0.1:8889', 'receiver': 'tcp://127.0.0.1:18889'}

ENDPOINT_NO = {'requester': 'tcp://127.0.1.1:7777', 'receiver': 'tcp://127.0.1.1:17777'}

ENDPOINT_CLIENT_SHUTDOWN = {'requester': 'tcp://127.0.0.1:7778', 'receiver': 'tcp://127.0.0.1:17778'}
ENDPOINT_SERVER_SHUTDOWN = {'receiver': 'tcp://127.0.0.1:7778', 'replier': 'tcp://127.0.0.1:17778'}
msg_list = []
publisher = TestPublisher('TestPublisher', msg_list)


@pytest.fixture
def loop_request():
    request = JSONRPCRequest()
    request.method = 'loop'
    request.args = []
    request.sync = True
    request.kwargs = {'timeout_ms': 3000}
    return request

@pytest.fixture
def sleep_request():
    request = JSONRPCRequest()
    request.method = 'sleep'
    request.args = [3]
    request.sync = True
    request.kwargs = {'timeout_ms': 6000}
    return request

@pytest.fixture(params=[[1], [1.0], ['1.2'], [[1, 1.0, '1.2']], [{'test1': 1, 'test2': 1.0, 'test3': '1.2'}]])
def method_args(request):
    return request.param

@pytest.fixture(params=[{'test1': 1, 'test2': 1.0, 'test3': '1.2'}])
def method_kwargs(request):
    return request.param

@pytest.fixture(scope='module')
def rpc_service_single():
    rs = DummyRPCService()
    return rs


@pytest.fixture(scope='module')
def rpc_service_list():
    ss_dict = {'dummy': DummyRPCService(), 'driver': driver()}
    return ss_dict


@pytest.fixture(scope='module')
def rpc_client_wrapper(request):
    wrapper = RPCClientWrapper(ENDPOINT_CLIENT, publisher)

    def fin():
        wrapper.rpc_client.stop()
    time.sleep(0.5)
    request.addfinalizer(fin)
    return wrapper


@pytest.fixture(scope='module')
def rpc_server_wrapper(rpc_service_single, request):
    wrapper = RPCServerWrapper(ENDPOINT_SERVER, publisher)
    wrapper.register_instance(rpc_service_single)
    # wrapper.rpc_server.redir.shutdown()

    def fin():
        wrapper.rpc_server.serving = False
        del wrapper.rpc_server
        # time.sleep(2)
    time.sleep(0.5)
    request.addfinalizer(fin)
    return wrapper

def exception_handle(f, *args, **kwargs):
    try:
        return f(*args, **kwargs)
    except Exception as e:
        pytest.fail(e.message)

def set_rpc_default_timeout(client, timeout_ms):
    client.rpc_client.transport.default_timeout_ms = timeout_ms

def get_rpc_default_timeout(client):
    return client.rpc_client.transport.default_timeout_ms

def test_sync_rpc(rpc_client_wrapper, rpc_server_wrapper):
    client = rpc_client_wrapper.get_proxy()
    now = time.time()
    ret = exception_handle(client.sleep, 1, timeout_ms=2000)
    assert 'server time cost for 1 second sleep:' in ret
    time_cost = time.time() - now
    assert 0.8 < time_cost < 1.5

def test_client_timeout(rpc_client_wrapper, rpc_server_wrapper):
    client = rpc_client_wrapper.get_proxy()
    t = get_rpc_default_timeout(rpc_client_wrapper)
    set_rpc_default_timeout(rpc_client_wrapper, 500)
    now = time.time()
    with pytest.raises(Exception) as e:
        client.sleep(1)
    assert e.typename == 'RPCError' and '[RPCError] Timeout waiting for response from server' in str(e)
    time_cost = time.time() - now
    assert 0.5 < time_cost < 1

    with pytest.raises(Exception) as e:
        client.exception_test()
    assert e.typename == 'RPCError' and '[RPCError] Timeout waiting for response from server' in str(e)
    # restore default timeout
    set_rpc_default_timeout(rpc_client_wrapper, t)
    time.sleep(2)


def test_register_rpc_service(rpc_client_wrapper, rpc_server_wrapper, rpc_service_list):
    dispatcher = rpc_server_wrapper.rpc_server.dispatcher

    assert 'sleep' in dispatcher.subdispatchers[''][0].__dict__['method_map']
    assert 'measure' in dispatcher.subdispatchers[''][0].__dict__['method_map']

    rpc_server_wrapper.register_instance(rpc_service_list)

    client = rpc_client_wrapper.get_proxy()
    client_driver = rpc_client_wrapper.get_proxy('driver')
    client_dummy = rpc_client_wrapper.get_proxy('dummy')
    assert exception_handle(client.driver_fun) == 'calling driver.fun()'

    # with args
    assert exception_handle(client_driver.fun, 1, 2) == 'calling driver.fun(1, 2)'

    # with kwargs
    assert exception_handle(client_driver.fun_kwargs, a=1, b=2) == 'calling driver.fun_kwargs(a=1, b=2)'

    # with kwargs and timeout
    assert exception_handle(client_driver.fun_kwargs, a=1, b=2, timeout_ms=10000) == 'calling driver.fun_kwargs(a=1, b=2)'
    assert exception_handle(client_driver.bus_fun) == 'calling driver.bus.fun()'
    assert exception_handle(client_driver.axi_fun) == 'calling axi.fun()'
    assert exception_handle(client_driver.bus_axi_fun) == 'calling axi.fun()'
    assert exception_handle(client_dummy.sleep, 0.1).startswith('server time cost for 0.1 second sleep: ')

    # test dispatch invalid method
    with pytest.raises(RPCError) as e:
        client_driver.invalid_method()
    assert '[RPCError] Method not found: driver_invalid_method' in str(e)

    # test calling invalid service
    with pytest.raises(RPCError) as e:
        client_service = client_driver = rpc_client_wrapper.get_proxy('invalid_service')
        client_service.sleep()
    assert e.typename == 'RPCError'

    # test exception if double registering same driver w/ same prefix
    with pytest.raises(RPCError) as e:
        rpc_server_wrapper.register_instance({'dummy': DummyRPCService()})
    assert "Name set(['exception_test', 'args_test', 'sleep', 'measure']) already registered in subdispather dummy_" in str(e)
    with pytest.raises(RPCError) as e:
        rpc_server_wrapper.register_instance(DummyRPCService())
    assert "Name set(['exception_test', 'args_test', 'sleep', 'measure']) already registered in subdispather" in str(e)

def test_server_worker_unavailble(rpc_client_wrapper, rpc_server_wrapper):
    def thread_worker():
        no_publisher = NoOpPublisher()
        client = RPCClientWrapper(ENDPOINT_CLIENT, no_publisher)
        client.sleep(3)
        client.rpc_client.stop()

    threads = []
    for i in range(THREAD_POOL_WORKERS):
        thread = Thread(target=thread_worker)
        threads.append(thread)
    for thread in threads:
        thread.start()

    # sleep to make sure all threadpool jobs are actually running;
    # without the sleep it is possible that measure run before sleep() in thread

    time.sleep(1)
    with pytest.raises(RPCError) as e:
        print rpc_client_wrapper.measure(1)
    assert e.typename == 'RPCError' and 'No available worker in thread pool' in str(e)
    # wait for all threads to finish for next test.
    for thread in threads:
        thread.join()

def test_rpc_service_exception(rpc_client_wrapper, rpc_server_wrapper):
    client_dummy = rpc_client_wrapper.get_proxy('dummy')
    with pytest.raises(Exception) as e:
        client_dummy.exception_test()
    assert 'Test Exception, raises exception on purpose' in str(e)

def test_rpc_rpc_test(rpc_client_wrapper, rpc_server_wrapper, method_args, method_kwargs):
    client_dummy = rpc_client_wrapper.get_proxy('')
    assert client_dummy.args_test(*method_args, **method_kwargs) == [method_args] + [method_kwargs]

def test_server_is_ready(rpc_client_wrapper, rpc_server_wrapper):
    client = rpc_client_wrapper.get_proxy()
    print 'testing accessible server'
    assert 'normal' == client.server_mode()

def test_multiple_client(rpc_client_wrapper, rpc_server_wrapper):
    print 'testing non-accessible server'
    no_publisher = NoOpPublisher()
    clients = []
    uuids = []

    # sync RPC
    for i in range(5):
        client = RPCClientWrapper(ENDPOINT_CLIENT, no_publisher)
        clients.append(client)

    start = time.time()
    for client in clients:
        ret = client.sleep(1)
        # assert(ret.startswith('server time cost for 1 second sleep: 1'))

    time_cost = time.time() - start
    print 'sync time_cost: ', time_cost
    for client in clients:
        client.rpc_client.stop()

    # sync RPC, time cost should be within about N*1s sleep + 0.08 estimated max overhead
    assert (4 < time_cost < 7)

    '''
    # async RPC
    clients = {}
    for i in range(5):
        client = RPCClientWrapper(ENDPOINT_CLIENT, no_publisher)
        clients[client] = None

    start = time.time()
    for client in clients:
        tmp_uuid = client.sleep(1, asynchronize=True)
        clients[client] = tmp_uuid

    for client, uuid in clients.items():
        client.wait_for_task(uuid)
        assert(client.get_result(uuid)[uuid][1].startswith('server time cost for 1 second sleep: 1'))

    time_cost = time.time() - start
    print 'async time_cost: ', time_cost
    for client, uuid in clients.items():
        client.rpc_client.receiver.stop()
        client.rpc_client.transport.hutdown()
    # async RPC, time cost should be within about 1s sleep + 0.08 estimated max overhead
    assert (1 < time_cost < 1.08)
    '''

def test_log_file(rpc_client_wrapper, rpc_server_wrapper):
    client = rpc_client_wrapper.get_proxy('')
    # send msg to server and server will send it back
    msg = 'log to test log'
    ret = client.measure(msg)
    assert msg == ret
    # sleep to ensure log are flushed to file
    time.sleep(1)
    log_file = rpc_server_wrapper.logger.file_path

    with open(log_file, 'rb') as f:
        log = f.read()
        assert ret in log

        # make sure there are received event log for the 'measure' rpc like the one below
        # 2018-09-07 11:53:08,228:INFO:[1536292388.23] received: cf65bc7281b84c4a9a9fd5be674d0124 {"args": ["log to test log"], "jsonrpc": "2.0", "method": "measure", "id": "883821b3b25111e889c4784f4367a8fb"}
        pattern_uuid = r'[0-9A-Za-z]{32}'
        pattern_received = r'INFO:.*:received: '
        pattern_received += pattern_uuid
        pattern_received += r' {"args":\["log to test log"\],"jsonrpc":"2.0",'
        pattern_received += r'"method":"measure","id":"'
        pattern_received += pattern_uuid
        pattern_received += r'"}'
        assert re.search(pattern_received, log)

        # check for sent event
        # 2018-09-07 11:53:08,229:INFO:[1536292388.23] sent: cf65bc7281b84c4a9a9fd5be674d0124 {"jsonrpc": "2.0", "id": "883821b3b25111e889c4784f4367a8fb", "result": "log to test log"}
        pattern_sent = r'INFO:.*:sent: '
        pattern_sent += pattern_uuid
        pattern_sent += r' {"jsonrpc":"2.0","id":"'
        pattern_sent += pattern_uuid
        pattern_sent += r'","result":"log to test log"}'
        assert re.search(pattern_sent, log)

    # setting logging level to ERROR and verify no INFO log in file
    client.server_set_logging_level('error')
    msg = 'log to test no log'
    ret = client.measure(msg)
    with open(log_file, 'rb') as f:
        log = f.read()
        assert ret not in log

    # enable the log again
    client.server_set_logging_level('debug')
    msg = 'log to test enable log again'
    ret = client.measure(msg)
    # sleep to ensure log are flushed to file
    time.sleep(1)
    with open(log_file, 'rb') as f:
        log = f.read()
        assert ret in log

        # make sure there are received event log for the 'measure' rpc like the one below
        # 2018-09-07 11:53:08,228:INFO:[1536292388.23] received: cf65bc7281b84c4a9a9fd5be674d0124 {"args": ["log to test enable log again"], "jsonrpc": "2.0", "method": "measure", "id": "883821b3b25111e889c4784f4367a8fb"}
        pattern_uuid = r'[0-9A-Za-z]{32}'
        pattern_received = r'INFO:.*:received: '
        pattern_received += pattern_uuid
        pattern_received += r' {"args":\["log to test enable log again"\],"jsonrpc":"2.0",'
        pattern_received += r'"method":"measure","id":"'
        pattern_received += pattern_uuid
        pattern_received += r'"}'
        assert re.search(pattern_received, log)

        # check for sent event
        # 2018-09-07 11:53:08,229:INFO:[1536292388.23] sent: cf65bc7281b84c4a9a9fd5be674d0124 {"jsonrpc": "2.0", "id": "883821b3b25111e889c4784f4367a8fb", "result": "log to test enable log again"}
        pattern_sent = r'INFO:.*:sent: '
        pattern_sent += pattern_uuid
        pattern_sent += r' {"jsonrpc":"2.0","id":"'
        pattern_sent += pattern_uuid
        pattern_sent += r'","result":"log to test enable log again"}'
        assert re.search(pattern_sent, log)

    # test server_reset_log() will remove old log file and create a new log file
    client.server_reset_log()
    assert not os.path.exists(log_file)
    # current log file should be updated
    assert log_file != rpc_server_wrapper.logger.file_path

    ret = client.measure(msg)
    log_file = rpc_server_wrapper.logger.file_path
    assert os.path.exists(log_file)
    with open(log_file, 'rb') as f:
        log = f.read()
        assert ret in log

def test_send_file(rpc_client_wrapper, rpc_server_wrapper):
    '''
    test for send_image and fwup api.
    '''
    client = rpc_client_wrapper.get_proxy()

    # None destination folder
    with pytest.raises(Exception) as e:
        client.server_send_file('dummy_file_name', 'aaaa', None)
    assert 'Destination folder not provided' in str(e)

    # invalid destination folder
    with pytest.raises(Exception) as e:
        client.server_send_file('dummy_file_name', 'aaaa', '/alksjdfl')
    assert 'RPCError: [RPCError] Invalid destination folder' in str(e)

    # invalid filename (including path)
    with pytest.raises(Exception) as e:
        client.server_send_file('../dummy_file_name', 'aaaa', '/opt/seeing/tftpboot')
    assert 'RPCError: [RPCError] Invalid file name ../dummy_file_name; should not include any path info.' in str(e)

    binary = '\x1f\x8b\x08\x00\xe5\x25\x1e\x5b'
    text = 'abcdefg'
    file_data = [binary, text]
    for data in file_data:
        fn = 'test_{}'.format(uuid.uuid4().hex)
        with open(fn, 'wb') as f:
            f.write(data)

        # write to '~' which is writeable on either xavier or mac.
        ret = rpc_client_wrapper.send_file(fn, '~')
        os.remove(fn)

        new_file_path = os.path.join(os.path.expanduser('~'), fn)
        assert ret == 'PASS'
        assert os.path.isfile(new_file_path)

        with open(new_file_path, 'rb') as f:
            read_data = f.read()
        os.remove(new_file_path)

        assert read_data == data

    # None file name
    assert 'Source file None invalid' == rpc_client_wrapper.send_file(None, '~')

    # file does not exist
    fn = 'DONOTEXIST'
    assert 'Source file DONOTEXIST is not accessible as a file' == rpc_client_wrapper.send_file(fn, '~')

def test_get_file(rpc_client_wrapper, rpc_server_wrapper):
    '''
    test for get_file api.
    '''
    client = rpc_client_wrapper.get_proxy()

    # None file
    ret, data = rpc_client_wrapper.get_file(None)
    assert 'Invalid target None to get from server' == ret
    assert data == ''

    # non-existing file
    # remove first to make sure the file does not exist;
    non_existing_fn = '~/NONEXISTINGFILE'
    try:
        os.remove(non_existing_fn)
    except:
        pass
    ret, data = rpc_client_wrapper.get_file(non_existing_fn)
    assert 'Target item to retrieve does not exist:' in ret
    assert data == ''

    binary = '\x1f\x8b\x08\x00\xe5\x25\x1e\x5b'
    text = 'abcdefg'
    file_data = [binary, text]
    for data in file_data:
        # create temp file to get
        fn = 'test_{}'.format(uuid.uuid4().hex)
        new_file_path = os.path.join(os.path.expanduser('~'), fn)
        with open(new_file_path, 'wb') as f:
            f.write(data)

        # write to '~' which is writeable on either xavier or mac.
        ret, file_data = rpc_client_wrapper.get_file('~/{}'.format(fn))
        assert ret == 'PASS'
        assert file_data == data
        os.remove(new_file_path)

    # get log folder
    ret, data = rpc_client_wrapper.get_file('log')
    assert ret == 'PASS'
    assert data

    # get from invalid folder
    ret, data = rpc_client_wrapper.get_file('/etc/passwd')
    assert 'Invalid folder /etc to get file from' in ret
    assert data == ''

    # get log folder and write to local file as tgz
    fn = 'rpc_log_{}.tgz'.format(uuid.uuid4().hex)
    new_file_path = os.path.join(os.path.expanduser('~'), fn)
    ret = rpc_client_wrapper.get_and_write_file('log', new_file_path)
    assert ret == 'PASS'
    assert os.path.isfile(new_file_path)
    os.remove(new_file_path)

def test_fw_version(rpc_client_wrapper, rpc_server_wrapper):
    '''
    test for fw_version() api.
    Check if fw_version() could return the correct version dict().
    '''
    client = rpc_client_wrapper.get_proxy()

    mock_fw_version_file = mock_open(read_data='{"fw_component": "0.0.0"}')
    with patch('__builtin__.open', mock_fw_version_file) as p:
        # patch open() so server_fw_version is actually use the mocked file content
        ver_dict = client.server_fw_version()
        expect = {'fw_component': '0.0.0'}
        assert ver_dict == expect

def test_server_shutdown():
    '''
    shutdown server through server(func) and client (rpc)
    '''
    server = RPCServerWrapper(ENDPOINT_SERVER_SHUTDOWN, publisher)
    client = RPCClientWrapper(ENDPOINT_CLIENT_SHUTDOWN, publisher)
    set_rpc_default_timeout(client, 500)
    # rpc server work
    ret = client.server_mode()
    assert ret == 'normal'
    assert server.stop_server() is True

    # server does not work after shutdown
    with pytest.raises(Exception) as e:
        client.server_mode()
    assert e.typename == 'RPCError' and '[RPCError] Timeout waiting for response from server' in str(e)
    client.rpc_client.stop()

    server = RPCServerWrapper(ENDPOINT_SERVER_SHUTDOWN, publisher)
    client = RPCClientWrapper(ENDPOINT_CLIENT_SHUTDOWN, publisher)
    set_rpc_default_timeout(client, 500)
    # rpc server work
    ret = client.server_mode()
    assert ret == 'normal'
    with pytest.raises(Exception) as e:
        client.server_stop()
    assert e.typename == 'RPCError' and '[RPCError] Timeout waiting for response from server' in str(e)

    # server does not work after shutdown
    with pytest.raises(Exception) as e:
        client.server_mode()
    assert e.typename == 'RPCError' and '[RPCError] Timeout waiting for response from server' in str(e)

def test_feature_profile(rpc_client_wrapper, rpc_server_wrapper):
    '''
    Test client and server profile function itself
    not to profile rpc performance
    '''
    num_rpc = 20

    client = rpc_client_wrapper
    # all profile should be disabled by default:
    # send 20 rpc to generate profile data
    for i in range(num_rpc):
        client.measure(1)

    assert not client.rpc_client.profile_result
    assert not client.rpc_client.profiler.getstats()
    breakdown, profile_result = client.server_get_profile_stats()
    assert not breakdown
    assert not profile_result

    # enable client and server profiling
    # enable both cProfile breakdown and rtt measurment
    assert 'done' == client.rpc_client.set_profile(True, True)
    assert 'done' == client.server_profile_enable()

    for i in range(num_rpc):
        client.measure(1)

    assert client.rpc_client.profile_result
    # valid list of data in client profiler stats
    assert client.rpc_client.profiler.getstats()
    breakdown, profile_result = client.server_get_profile_stats()
    # valid list of data in server profiler stats
    assert breakdown
    assert profile_result
    # profile_result should be a dict of {'keys': [sorted list of keys], 'step1':[lst of time]...}
    assert 'keys' in profile_result
    for key in profile_result['keys']:
        assert key in profile_result
        # each should have 20 data for 20 rpc.
        assert len(profile_result[key]) == num_rpc

    # disable profiling, clear client and server stats
    assert 'done' == client.server_profile_enable(False, False)
    assert 'done' == client.server_clear_profile_stats()
    assert 'done' == client.rpc_client.set_profile(False, False)
    assert 'done' == client.rpc_client.clear_profile_stats()

    # server stats should be empty again
    breakdown, profile_result = client.server_get_profile_stats()
    assert not breakdown
    assert not profile_result

    # enable rtt measuring, disable cProfile breakdown
    client.rpc_client.set_profile(False, True)
    assert 'done' == client.server_profile_enable(False, True)
    # get rid of impact of server_get_profile_stats and server_profile_enable
    assert 'done' == client.rpc_client.clear_profile_stats()

    for i in range(num_rpc):
        client.measure(1)

    assert client.rpc_client.profile_result
    profile_result_client = client.rpc_client.generate_profile_result()
    # valid list of data in client profiler stats
    assert not client.rpc_client.profiler.getstats()
    breakdown, profile_result = client.server_get_profile_stats()
    # valid list of data in server profiler stats
    assert not breakdown
    assert profile_result
    # profile_result should be a dict of {'keys': [sorted list of keys], 'step1':[lst of time]...}
    assert 'keys' in profile_result
    keys = profile_result.pop('keys')
    assert [u'parse_request', u'dispatch', u'serialize'] == keys
    for key in keys:
        assert key in profile_result
        # each should have 20 data for 20 rpc.
        assert len(profile_result[key]) == num_rpc

    # verify profile statistics at client side. The format is same as client:
    #    {
    #        'keys': [SORTED_POINT1, SORTED_POINT2, ...],
    #        'POINT1': [DATA1, DATA2, ...],
    #        'POINT2': [DATA1, DATA2, ...],
    #    }
    assert 'keys' in profile_result_client
    keys = profile_result_client.pop('keys')
    assert ['create_request', 'serialize', 'reply_got', 'parse_reply', 'return'] == keys
    assert 'create_request' in profile_result_client
    assert 'serialize' in profile_result_client
    assert 'reply_got' in profile_result_client
    assert 'parse_reply' in profile_result_client
    assert 'return' in profile_result_client
    # 20 valid data point
    for v in profile_result_client.values():
        assert len(v) == num_rpc

    # disable server profiling
    assert 'done' == client.server_profile_enable(False, False)
    # new rpc should not generate any profile data in server
    assert 1 == client.measure(1)
    assert 'normal' == client.server_mode()

    breakdown, profile_result = client.server_get_profile_stats()
    # valid list of data in server profiler stats
    assert not breakdown
    # previous data not cleared, still valid
    assert profile_result

    # data should increase by 1 because server_get_profile_stats();
    # should not increase due to the measure() rpc.
    assert 'keys' in profile_result
    for key in profile_result['keys']:
        assert key in profile_result
        assert len(profile_result[key]) == num_rpc + 1

    assert 'done' == client.server_clear_profile_stats()
    client.rpc_client.clear_profile_stats()

# TODO test for retry request
# TODO test client reconnect
