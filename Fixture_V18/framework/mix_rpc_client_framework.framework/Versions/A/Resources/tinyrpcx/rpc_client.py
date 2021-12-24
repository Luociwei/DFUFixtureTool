import zmq
import logging
from publisher import NoOpPublisher
from tinyrpc.protocols.jsonrpc import JSONRPCProtocol
from tinyrpc.transports.zmq import ZmqClientTransport
from tinyrpc import RPCClient

'''
# initializing logging.
logging.basicConfig(filename='log/rpc_server.log',
                    level=logging.DEBUG,
                    format='%(asctime)s:%(levelname)s:%(message)s',
                    )

# define a new Handler to log to console as well
console = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s:%(levelname)s:%(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)
'''


class RPCClientWrapper(object):
    def __init__(self, transport, publisher=None, ctx=None, protocol=None):
        self.ctx = ctx if ctx else zmq.Context().instance()
        if isinstance(transport, ZmqClientTransport):
            self.transport = transport
        else:
            if 'tcp' not in str(transport):
                transport = "tcp://*:" + str(transport)
            self.transport = ZmqClientTransport.create(self.ctx, transport)

        self.protocol = protocol if protocol else JSONRPCProtocol()
        self.publisher = publisher if publisher else NoOpPublisher()
        self.transport.publisher = self.publisher

        self.rpc_client = RPCClient(self.protocol, self.transport,
                                    self.publisher)
        self.proxy = self.get_proxy()

    def get_proxy(self, prefix=''):
        return self.rpc_client.get_proxy(prefix)

    def hijack(self, mock, func=None):
        self.rpc_client._send_and_handle_reply = mock

    def __getattr__(self, attr):
        logging.info('RPC call: {}'.format(attr))
        return getattr(self.proxy, attr)

    def set_profile(self, *args, **kwargs):
        return self.rpc_client.set_profile(*args, **kwargs)

    def clear_profile_stats(self, *args, **kwargs):
        return self.rpc_client.clear_profile_stats(*args, **kwargs)

    def send_file(self, *args, **kwargs):
        return self.rpc_client.send_file(*args, **kwargs)

    def get_file(self, *args, **kwargs):
        return self.rpc_client.get_file(*args, **kwargs)

    def get_and_write_file(self, *args, **kwargs):
        return self.rpc_client.get_and_write_file(*args, **kwargs)
