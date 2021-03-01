import os
import re
import zmq
import time
import uuid
import pstats
import ujson as json
import base64
import logging
import logging.handlers
import platform
import tarfile
import cProfile
import traceback
from logger import RPCLogger
from publisher import NoOpPublisher
from tinyrpc.protocols.jsonrpc import JSONRPCProtocol
from tinyrpc.transports.zmq import ZmqServerTransport
from tinyrpc.server import RPCServer
from tinyrpc.dispatch import RPCDispatcher
from tinyrpc.config import ALLOWED_FOLDER_SEND_FILE
from tinyrpc.config import ALLOWED_FOLDER_GET_FILE
from tinyrpc.config import MIX_FW_VERSION_FILE
from logging import NOTSET, DEBUG, INFO, WARNING, ERROR, FATAL


class RPCServerWrapper(object):
    '''
    RPC Server Wrapper to create a server in 1 line of code with given transport/endpoint and publisher.

    :param transport: 2 kind of input supported:
        1. dict describing server endpoint

        .. code-block:: python

            {'receiver':'tcp://127.0.0.1:5556', 'replier':'127.0.0.1:15556'}

        for backword compatibility, a single string is also accepted as receiver endpoint:

        .. code-block:: python

            'tcp://127.0.0.1:5556'

        In this case, replier endpoint will using same IP and given port + 10000; it is equal to the dictionary above.

        Supported endpoint format:

        .. code-block:: python

            'tcp://127.0.0.1:5556'
            '127.0.0.1:5556'
            '*:5556'

        Not supported:

        .. code-block:: python

            '5556'

        2. RPCTransport instance.

    :param ctx: ZMQ Context; used when multiple RPC server share same ZMQ Context.
    :param protocol: not used.
    :param dispatcher: not used.
    :param log_level: log level for log file; log below this will not be saved to log file.
    :param log_folder_path: log folder for rpc log.
                            If None, use log/ which is same level of logger/
    :param name: rpc server name; used in log file name.
                 If None, it will be 'ip_port' from rpc server IP and receiver port.

    :server services: Defined as selected functions in class "rpc_public_api" variable;
                       All functions in the list will be exposed as RPC service.
                       But only the selected will run in main dispatching thread
                       instead of run in threadpool.
                       This means they will run a little bit faster (threadpool cost 550us more),
                       and is able to run even when threadpool is full.
                       Guidelines to make RPC service a 'server service':

                           1. function that works at end of current server life cycle
                                reboot/reset
                           2. time-sensitive RPC service
                                'mode' that will be used before every RPC by PhoneQT.

                       Server services are in whitelist defined in config.py.
    '''
    rpc_public_api = ['reset', 'stop', 'all_methods', 'mode', 'fwup', 'reboot',
                      'reset_log', 'set_logging_level',
                      'profile_enable', 'clear_profile_stats', 'get_profile_stats',
                      'get_file', 'send_file', 'get_rtc', 'set_rtc',
                      'set_ntp_server', 'fw_version']

    def __init__(self, transport, publisher=None, ctx=None, protocol=None,
                 dispatcher=None, log_level=INFO, log_folder_path=None, name=None):

        self.ctx = ctx if ctx else zmq.Context().instance()
        self.protocol = protocol if protocol else JSONRPCProtocol()
        self.dispatcher = dispatcher if dispatcher else RPCDispatcher()
        self.publisher = publisher if publisher else NoOpPublisher()
        if isinstance(transport, dict):
            # dictionary:
            if 'receiver'in transport and 'replier' in transport:
                self.endpoints = transport
            else:
                msg = 'endpoint dictionary {} should contains receiver and replier'
                raise Exception(msg.format(transport))
            self.endpoint = self.endpoints['receiver']
        elif isinstance(transport, basestring):
            # only 1 endpoint is provided; create endpoint for replier by adding port by 10000
            pattern = '(tcp://)?((?P<ip>[0-9.*]+):)?(?P<port>[0-9]+)'
            re_groups = re.match(pattern, transport.strip())
            if not re_groups:
                raise Exception('Invalid transport format {}; '
                                'expecting tcp://IP:PORT or IP:PORT'.format(transport))
            replier_port = int(re_groups.group('port')) + 10000
            ip = re_groups.group('ip') if re_groups.group('ip') else '*'
            receiver_endpoint = 'tcp://{}:{}'.format(ip, replier_port)
            replier_endpoint = 'tcp://{}:{}'.format(ip, replier_port)
            self.endpoints = {'receiver': transport,
                              'replier': replier_endpoint}
            self.endpoint = self.endpoints['receiver']

        else:
            # existing transport instance
            self.endpoints = transport
            self.endpoint = transport.endpoint['receiver']

        if name:
            # name should be string.
            err_msg = 'RPC server name ({}) shall be string.'.format(name)
            assert isinstance(name, basestring), err_msg
            err_msg = 'RPC server name ({}) shall not contain .'.format(name)
            assert '.' not in name, err_msg
            err_msg = 'RPC server name ({}) shall not contain {}'.format(name, os.sep)
            assert os.sep not in name, err_msg
            logger_name = name
        else:
            # use port as name.
            pattern = 'tcp://(?P<ip>[0-9.*]+):(?P<port>[0-9]+)'
            re_groups = re.match(pattern, self.endpoint)
            logger_name = re_groups.group('port')
        self.logger = RPCLogger(name=logger_name, level=log_level, log_folder_path=log_folder_path)
        # logger for registered instance, like drivers and test functions
        self.service_logger = RPCLogger(logger_name + '_service', level=log_level, log_folder_path=log_folder_path)

        self.init_server(self.endpoints)
        self.server_mode = 'normal'

    def init_server(self, transport):
        '''
        Internal function that should not be called explicitly.
        :param transport: dict like {'receiver': transport, 'receiver': replier_endpoint}
        :param logger: RPCLogger instance
        '''
        if isinstance(transport, ZmqServerTransport):
            self.transport = transport
        else:
            # dict like {'receiver': transport, 'receiver': replier_endpoint}
            for key in transport:
                if 'tcp' not in str(transport[key]):
                    transport[key] = "tcp://" + str(transport[key])
            self.transport = ZmqServerTransport.create(self.ctx, transport)

        self.transport.publisher = self.publisher

        self.rpc_server = RPCServer(self.transport, self.protocol,
                                    self.dispatcher)
        self.rpc_server.set_logger(self.logger)
        self.register_instance({'server': self})
        self.rpc_server.dispatcher.logger = self.service_logger
        self.rpc_server.start()
        self.logger.info('rpc server {} started.'.format(self.endpoint))

    def register_instance(self, obj={}):
        '''
        Register instance as RPC service provided to the RPC server.

        :param obj: a dictionary with the following format:

            value: instance that provide functions as RPC service

            key: a string as the prefix of all RPC services belongs to the instance in value.

        Example code for client to send "driver1_measure()" RPC to call driver1.measure()
        and driver2_measure() to call driver2.measure() on server:

        .. code-block:: python

            # Driver() class has a public function measure()
            driver1 = Driver()
            driver2 = Driver()
            server.register_instance({'driver1': driver1, 'driver2': driver2})

        '''
        self.rpc_server.dispatcher.register_instance(obj)

    def reset(self):
        self.rpc_server.shutdown()
        self.init_server(self.endpoints)
        return True

    def stop(self):
        self.rpc_server.shutdown()
        return True

    def all_methods(self):
        '''
        Wrapper for dispatcher.all_methods()
        '''
        return self.rpc_server.dispatcher.all_methods()

    def mode(self):
        '''
        Client will use this as
        1. server accessibility, like network disconnection
        2. server mode check; only continue testing in 'normal' mode;
        Server will put mode into 'dfu' during fwup in the future.
        '''
        return self.server_mode

    def fwup(self):
        '''
        Do the actual update job.
        Currently just reboot Xavier to let shell script work.
        Could update to do more in the future.
        '''
        self.reboot()

    def reboot(self):
        '''
        On Xavier, reboot the whole Xavier linux.
        On non-Xavier, which means in test environment, simulate an 5s reboot.
        '''
        os_str = platform.platform().lower()
        # Xavier: Linux-4.0.0.02-xilinx-armv7l-with-Ubuntu-14.04-trusty
        if 'xilinx' in os_str and 'linux' in os_str:
            os.system('reboot')
        else:
            for i in range(5):
                print 'Simulating rebooting; ', i
                time.sleep(1)

    def reset_log(self):
        self.logger.reset()
        self.service_logger.reset()
        return '--PASS--'

    def get_file(self, target):
        '''
        target could be folder path or file path on xavier; '~' is allowed.
        folder of target (file folder or folder itself) should be in whitelist;
        any request outside of whitelist will be rejected.

        Specially:
            target '#log' mean to get all log files of current rpc
            server (in a tmp folder).
            target 'log' mean to get the whole rpc log folder

        :return: 2-item tuple ('PASS', data) or (errmsg, '')
            errmsg should be a string about failure reason.
            data is encoded in base64; client will be responsible
            for decoding it into origin data.
        '''
        # check whitelist
        log_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'log')
        if log_folder not in ALLOWED_FOLDER_GET_FILE:
            ALLOWED_FOLDER_GET_FILE.append(log_folder)

        if not target:
            return 'Invalid target {} to get from server'.format(target), ''

        # handle trailing '/'
        target = target.rstrip(os.path.sep)

        if target == 'log':
            target = log_folder

        tmp_folder = ''
        if target == '#log':
            # get all log files of current rpc server.
            # put them into a temp folder inside of log
            # pack into tgz and return back to client.
            log_folder = self.logger.log_folder
            tmp_folder = os.path.join(log_folder, 'rpc_server_log_{}_{}'.format(self.logger.name, uuid.uuid4().hex))
            os.mkdir(tmp_folder)
            for f in self.logger.files() + self.service_logger.files():
                dst = os.path.join(tmp_folder, os.path.basename(f))
                os.rename(f, dst)

            # for rpc_default.log which host non-rpc_server log
            other_log = os.path.join(log_folder, 'rpc_default.log')
            if os.path.exists(other_log):
                dst = os.path.join(tmp_folder, 'rpc_default.log')
                with open(other_log, 'rb') as f_in:
                    with open(dst, 'wb') as f_out:
                        f_out.write(f_in.read())
            target = tmp_folder

            # restart server logger after removing log files.
            # without this there will be no log in log file after previous log file being removed.
            self.reset_log()

        # handle "~" in target file/folder
        target = os.path.expanduser(target)

        folder = os.path.dirname(target)
        fn = os.path.basename(target)

        # handle "~" in white list.
        tgz_fn = ''
        allowed_folder = [os.path.expanduser(i) for i in ALLOWED_FOLDER_GET_FILE]
        if os.path.isfile(target):
            # for file, check if it is in allowed folder.
            if folder not in allowed_folder:
                msg = 'Invalid folder {} to get file from; supporting one in {}'
                return msg.format(folder, ALLOWED_FOLDER_GET_FILE), ''
        elif os.path.isdir(target):
            # for folder, check if it is one of the allowed folder.
            if target not in allowed_folder and os.path.dirname(target) not in allowed_folder:
                msg = 'Invalid folder {} to get file from; supporting one in {}'
                return msg.format(folder, ALLOWED_FOLDER_GET_FILE), ''
            # zip folder into tgz file: ~/aaa --> ~/aaa.tgz, /opt/seeing/log --> ~/log.tgz
            home = os.path.expanduser('~')
            os.chdir(folder)
            tgz_fn = os.path.join(home, '{}_{}.tgz'.format(fn, uuid.uuid4().hex))
            with tarfile.open(tgz_fn, 'w') as tgz:
                tgz.add(fn)
            # the actual file to transfer is the tgz file.
            target = tgz_fn
        elif not os.path.exists(target):
            return 'Target item to retrieve does not exist: {}'.format(target), ''
        else:
            return 'Target item to retrieve exists but is neither a folder nor a file: {}'.format(target), ''

        with open(target, 'rb') as f:
            data = f.read()

        # cleanup: remove tmp tgz file for folder.
        if tgz_fn:
            os.remove(tgz_fn)

        # cleanup: remove tmp_folder for creating tgz.
        if tmp_folder:
            for f in os.listdir(tmp_folder):
                os.remove(os.path.join(tmp_folder, f))
            os.rmdir(tmp_folder)

        return 'PASS', base64.b64encode(data)

    def send_file(self, fn, data, folder):
        '''
        send file from RPC client to RPC server;
        fn should be filename in string;
        data should be base64 encoded raw binary file content.
        the function will write the file into file at predefined location with filename==fn.
        '''
        len_data = len(data)
        if not folder:
            raise Exception('Destination folder not provided.')
        if len_data > 1024 * 1024 * 500:
            # image larger than 500M is highly possible an mistake;
            # usually should be within 100MB wo fs and within 200MB with fs.
            raise Exception('Invalid file size {}; should be smaller than 500MB.'.format(len_data))

        # prevent fn like '../../root/xxx'
        if not fn == os.path.basename(fn):
            raise Exception('Invalid file name {}; should not include any path info.'.format(fn))

        # prevent arbitrary file write.
        folder = folder.rstrip(os.path.sep)
        if folder not in ALLOWED_FOLDER_SEND_FILE:
            msg = 'Invalid destination folder {}; supporting one in {}'
            msg = msg.format(folder, ALLOWED_FOLDER_SEND_FILE)
            raise Exception(msg)

        # expand to full path for ~
        folder = os.path.expanduser(folder)

        with open(os.path.join(folder, fn), 'wb') as f:
            data = base64.b64decode(data)
            # TODO: handle base64 decode error
            f.write(data)

        return 'PASS'

    def get_rtc(self):
        return time.time()

    def set_rtc(self, timestamp):
        '''
        placeholder for the moment. Will be replaced with real set_rtc code later on.

        This function will set Xavier Linux system RTC to give value
        And set FPGA RTC to the same give value.

        :param timestamp: should be seconds from 1970/1/1 in float or int.
        :return: string 'PASS' when succeed; Error string in case of any error.
        :example: client.server_set_rtc(time.time()) will set xavier RTC to current time.
                    timestamp = 1538296130  #2018-09-30 16:28:50 CST
                    client.server_set_rtc(timestamp)
        '''
        self.logger.info('Setting RTC to {}'.format(timestamp))

        os_str = platform.platform().lower()
        # Xavier: Linux-4.0.0.02-xilinx-armv7l-with-Ubuntu-14.04-trusty

        if not ('xilinx' in os_str and 'linux' in os_str):
            self.logger.info('Skip Setting RTC to {} on host.'.format(timestamp))
            return '--PASS--'

        try:
            timestamp = float(timestamp)
        except:
            raise ValueError('timestamp value should be float or int!')

        assert timestamp >= 0

        if 0 != os.system('date -s @' + str(timestamp)):
            return '--FAIL--'

        def save_rtc_to_fpga(second, millisecond):
            from drivers.standard.common.ntp import AXI4UTC
            fpga_rtc = AXI4UTC()
            fpga_rtc.set_rtc(second, millisecond)

        seconds = int(timestamp)
        milliseconds = int((timestamp - seconds) * 1000)
        save_rtc_to_fpga(seconds, milliseconds)

        return '--PASS--'

    def set_ntp_server(self, host_addr):
        '''
        Synchronizing date with host by NTP(Network Time Protocol) server

        :param    host_addr:    str(<IP>),     IPv4 address, as '64.236.96.53'
        :return:   '--PASS--' or Assert failure
        :example:
                    host_addr = '210.72.145.44'
                    xavier.set_ntp_server(host_addr)
        '''
        def set_server_ip(host_addr):
            ntp_conf_file = '/etc/ntp.conf'

            def is_addr_exist():
                with open(ntp_conf_file, 'r') as f:
                    datas = f.readlines()
                    for line in datas:
                        if line.startswith('server ' + str(host_addr) + ' '):
                            return True
                    return False

            def addr_append():
                with open(ntp_conf_file, 'a') as f:
                    f.writelines('\nserver ' + str(host_addr) + ' ')

            if not is_addr_exist():
                addr_append()

            return True

        # assert is_valid_host(host_addr), 'valid host addr fail.'
        assert (0 == os.system('service ntp stop')), 'ntp service stop fail'
        assert (0 == os.system('ntpdate ' + host_addr)), 'ntpdate get date fail'
        set_server_ip(host_addr)
        assert (0 == os.system('service ntp start')), 'ntp service start fail'

        return '--PASS--'

    def fw_version(self):
        '''
        return dictionary of mix firmware;
        mix fw version is defined in a json file;
        Currently in /mix/version.json (MIX_FW_VERSION_FILE).
        '''
        if not MIX_FW_VERSION_FILE:
            raise Exception('MIX_FW_VERSION_FILE not defined.')
        with open(MIX_FW_VERSION_FILE, 'rb') as f:
            data = f.read()
        return json.loads(data)

    def set_logging_level(self, level):
        '''
        Setting RPC server logging level;

        :param level: string in given list, string of level
                      case insensitive; must be one of
                      "NOTSET", "INFO", "DEBUG", "WARNING", "ERROR", "FATAL"
        '''
        level = level.lower()
        levels = {
            'notset': NOTSET,
            'debug': DEBUG,
            'info': INFO,
            'warning': WARNING,
            'error': ERROR,
            'fatal': FATAL}
        if level not in levels:
            msg = 'Unexpected level {}; should be in {}'.format(level, levels.keys())
            raise Exception(msg)

        # logging.seLevel accepts ints, not string.
        self.logger.setLevel(levels[level])
        self.service_logger.setLevel(levels[level])
        return 'done'

    def profile_enable(self, breakdown=True, rtt=True):
        '''
        Enable/disable server profiling;
        Both for total handle time and function breakdown

        :param breakdown: bool, default True; controls whether to profile server handle function
                          and generate breakdown data for each function call
        :param rtt: bool, default True; controls whether to calculate total server handle time;
        :example:
                 client.server_profile_enable()             # server profile will be enabled
                 client.server_profile_enable(False, False) # server profile will be disabled
        :return: 'done' for successfully setting. Do not explicitly return other value.
        '''
        self.rpc_server.set_profile(breakdown, rtt)
        return 'done'

    def clear_profile_stats(self):
        self.rpc_server.clear_profile_result()
        return 'done'

    def get_profile_stats(self):
        '''
        return profile statistics to client.

        :return: Tuple, (breakdown, profile_result)
            breakdown: dict; server main thread's cProfile stats; {} if not enabled.
            profile_result: dict; end-to-end time of each phase data
            format of breakdown dict:

                key: function name including file path, like /root/zmq.py:send
                value: dict{

                    'ncall': int, number of function call profiled,

                    'tot_avg': average time of the function, not including sub-func call

                    'cum_avg': average time of the function, including sub-func call

                    }

            format of profile_result: dict{

                'keys': list, keys in time sequence, like [start, step1, step2, step3]

                'start': [t_rpc1, t_rpc2, ...]      # t_rpc is float() from time.time()

                'step1': [t_rpc1, t_rpc2, ...]
                ...

                }

                User software could use this dict to do further calculation,
                like avg, rms, etc.
        '''
        stats_server = []
        breakdown = {}
        if self.rpc_server.profiler:
            try:
                stats_server = pstats.Stats(self.rpc_server.profiler).stats
                # profile breakdown
                breakdown = {
                    pstats.func_std_string(k): {
                        'ncall': v[1],
                        'tot_avg': float(v[2]) / v[1],
                        'cum_avg': float(v[3]) / v[0]}
                    for k, v in stats_server.items()}
            except:
                self.logger.info(traceback.format_exc())
                stats_server = []
                breakdown = {}

        profile_result = self.rpc_server.generate_profile_result()
        # overall server handling time
        return breakdown, profile_result

    def get_event(self):
        '''
        API for user software to get system event, like light curtain event and system hot.

        :return: a list of error code in string like this:

                    ret = client.server_get_event()

                    # ret == ['[Server 7801] Light curtain triggered', '[Server 7802] PROCHOT']

                 Empty list [] will returned if no event available.

        :notes:
            Event is global variable shared by all RPC server;
                Any server will return all events of all server.
            Event from each server will have identity in header like '[Server 7802]';
                This means this event is generated by Server with port 7802; normally DUT2.

            Events are cleared after got by client.
        '''
        pass


if __name__ == '__main__':
    from publisher import ZmqPublisher
    server = RPCServerWrapper("tcp://127.0.0.1:7777", ZmqPublisher(zmq.Context(), "tcp://127.0.0.1:6665", '101'))
    from drivers.driver import *
    service = driver()
    server.register_instance(service)
    raw_input()
