import os
import sys
import time
import traceback
import logging
import cProfile
from ..exc import RPCError
from threading import Thread
from threading import Lock
from ..protocols.jsonrpc import *
# from debugger import rpdb, RedirectStd
from concurrent.futures import ThreadPoolExecutor
from .. import HEARTBEAT_INTERVAL_S, THREAD_POOL_WORKERS
from ..config import DONE, TIMEOUT, ERROR
from ..config import SERVER_SERVICES, DBG_CHANNEL
# from ..config import DEBUGGER_REP_ENDPOINT, DEBUG_ENABLE
from ..config import PROFILE_SERVER
from ..config import PROFILE_SERVER_RTT


class RPCServer(Thread):
    '''High level RPC server.

    :param transport: The :py:class:`~tinyrpc.transports.RPCTransport` to use.
    :param protocol: The :py:class:`~tinyrpc.RPCProtocol` to use.
    :param dispatcher: The :py:class:`~tinyrpc.dispatch.RPCDispatcher` to use.
    '''
    def __init__(self, transport, protocol, dispatcher):
        super(RPCServer, self).__init__()
        self.setDaemon(True)
        self.transport = transport
        self.protocol = protocol
        self.dispatcher = dispatcher
        self.threadpool = ThreadPoolExecutor(THREAD_POOL_WORKERS)
        # lock to protect shared tasks object among threads
        self.lock = Lock()
        self.tasks = {}
        # by default do not profile to avoid 200us overhead per RPC
        self.profile = False
        self.profile_rtt = False
        self.profile_result = {}
        self.profiler = cProfile.Profile()

        self.serving = True
        # logger: use global default as initial
        self.logger = logging.getLogger()

        # default no profile; use non-profiling version of function pointer
        self.handle_message = self.handle_message_no_profile
        self.handle_request = self.handle_request_with_reply

        # if DEBUG_ENABLE:
        #     self.redir = RedirectStd()
        #     self.debugger = rpdb(self.redir, self.redir, user_rawinput=0)

    def profile_wrapper(self, f):
        '''
        wrapper function to generated a profiled-version of given function.
        '''
        def wrapped(*args, **kwargs):
            try:
                self.profiler.enable()
                return f(*args, **kwargs)
            finally:
                self.profiler.disable()
        return wrapped

    def set_profile(self, breakdown, rtt):
        '''
        :param breakdown: whether to profile each func call using cProfile
        :param rtt: whether record start and end of server handling time.

        Do not return anything.
        '''
        if breakdown:
            # profile; use profiling version of function pointer
            self.profiler = cProfile.Profile()
            self.handle_message = self.profile_wrapper(self.handle_message_no_profile)
            self.handle_request = self.profile_wrapper(self.handle_request_with_reply)
        else:
            # no profile; use non-profiling version of function pointer
            self.handle_message = self.handle_message_no_profile
            self.handle_request = self.handle_request_with_reply

        self.profile_rtt = rtt

    def clear_profile_result(self):
        self.profiler = cProfile.Profile()
        self.profile_result = {}

    def generate_profile_result(self):
        '''
        Generate a dict of profile result including RTT and each phase data

        input:

            self.profile_result

            format: {

                        'uid1': {'start': time1, 'create_request', time2, ...},

                        'uid2': {'start': time1, 'create_request', time2, ...},

                        ,...

                    }

        process: get list of sorted key by sorting the time to determine sequence;
                    like [start, create_request, serialize, transport, parse_reply]

                 Then calculate each stage time by minus action:

                        t_create_request = result['create_request'] - result['start']

                        t_serialize = result['serialize'] - result['create_request']

        output: dict as follow so user could calculate avg/rms/other statistics.

            {

                'keys': [SORTED_POINT1, SORTED_POINT2, ...],

                'POINT1': [DATA1, DATA2, ...],

                'POINT2': [DATA1, DATA2, ...],

            }

        '''
        # filter valid profile results; skip those incomplete ones from profile_enable.
        full_key = []
        for v in self.profile_result.values():
            if len(full_key) < len(v):
                full_key = v.keys()
        valid_profile_result = [v for v in self.profile_result.values() if v.keys() == full_key]

        # no data
        if not valid_profile_result:
            return {}
        ret = {}
        first_data = valid_profile_result[0]
        # sorted key by value so key is in time sequence
        key_list = sorted(first_data.keys(), key=lambda k: first_data[k])
        # 1st is start time, no need to report.
        ret['keys'] = key_list[1:]
        for key in ret['keys']:
            ret[key] = []
        for data in valid_profile_result:
            for i, key in enumerate(key_list):
                # 'start'
                if i == 0:
                    continue
                # us as unit.
                ret[key].append((data[key_list[i]] - data[key_list[i - 1]]) * 1000 * 1000)
        return ret

    def set_logger(self, logger):
        self.logger = logger
        self.transport.logger = logger
        self.protocol.logger = logger
        self.dispatcher.logger = logger

    def shutdown(self):
        self.serving = False
        while self.is_alive():
            time.sleep(0.1)
        self.threadpool.shutdown()
        del self.threadpool
        self.transport.shutdown()
        # if DEBUG_ENABLE:
        #     self.redir.shutdown()

    def handle_request_with_reply(self, context, request):
        response = self.dispatcher._dispatch(request)
        uid = request.unique_id
        if self.profile_rtt and uid in self.profile_result:
            self.profile_result[uid]['dispatch'] = time.time()

        payload = response.serialize()
        if self.profile_rtt and uid in self.profile_result:
            self.profile_result[uid]['serialize'] = time.time()
        self.transport.send_reply_with_lock(context, payload)
        self.lock.acquire()
        self.tasks.pop(uid, None)
        self.lock.release()

    def handle_message_no_profile(self, context, msg):
        '''Handle received message supporting parallel task in threadpool.
        This function parses the msg first, and submit task to threadpool.
        The threadpool worker dispatches the method in daemon thread.

        :param context: string, zmq socket channel id
        :param msg: string, mag string, is a serialized string from JSONRPCRequest format data
        '''
        if self.profile_rtt:
            start = time.time()
        request = None
        try:
            request = self.protocol.parse_request(msg)
            timeout = request.kwargs.pop('timeout_ms', sys.maxint) / 1000.0
            uid = request.unique_id
            if len(self.tasks) == THREAD_POOL_WORKERS:
                raise JSONRPCServerWorkerUnavailableError()
            if self.profile_rtt:
                self.profile_result[uid] = {}
                self.profile_result[uid]['start'] = start
                self.profile_result[uid]['parse_request'] = time.time()

            if context == 'DBG' or request.method in SERVER_SERVICES:
                response = self.dispatcher._dispatch(request)
                payload = response.serialize()
                self.transport.send_reply_with_lock(context, payload)
            else:
                # only create record to calculate concurrent job number.
                self.lock.acquire()
                self.tasks[uid] = None
                self.lock.release()
                self.threadpool.submit(self.handle_request, context, request)
        except Exception, e:
            self.logger.error('%s %s %s', e.message, os.linesep, traceback.format_exc())
            if not isinstance(e, RPCError):
                e = JSONRPCServerError(e.message)
            response = self.protocol.error_respond(e, request)
            payload = response.serialize()
            self.transport.send_reply_with_lock(context, payload)
            self.lock.acquire()
            self.tasks.pop(uid, None)
            self.lock.release()

    def run(self):
        '''Handle requests forever.

        Starts the server loop in which the transport will be polled for a new
        message.

        After a new message has arrived,
        :py:func:`~tinyrpc.server.RPCServer._spawn` is called with a handler
        function and arguments to handle the request.

        The handler function will try to decode the message using the supplied
        protocol, if that fails, an error response will be sent. After decoding
        the message, the dispatcher will be asked to handle the resultung
        request and the return value (either an error or a result) will be sent
        back to the client using the transport.

        After calling :py:func:`~tinyrpc.server.RPCServer._spawn`, the server
        will fetch the next message and repeat.
        '''
        # self.transport.heartbeat_at = time.time() + HEARTBEAT_INTERVAL_S
        while self.serving:
            self.process_one_message()
            # self.transport.check_heartbeat()

        self.transport.shutdown()

    def process_one_message(self):
        context, message = self.transport.receive_message()

        if context and message:
            # assuming protocol is threadsafe and dispatcher is theadsafe, as
            # long as its immutable
            # if context == DBG_CHANNEL:
            #     self.debugger.runcall(self.handle_message, context, message)
            # else:
            #     self.handle_message(context, message)
            self.handle_message(context, message)

