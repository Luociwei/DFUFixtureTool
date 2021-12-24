import time
from tinyrpc.dispatch import public


class DummyRPCService(object):
    def __init__(self, name='utility'):
        self.name = name

    @public
    def measure(self, value):
        return value

    @public('args_test')
    def args_test(self, *args, **kwargs):
        print 'measure: ', args, kwargs
        return args, kwargs

    @public('sleep')
    def test_delay(self, second):
        now = time.time()
        msg = '[{}] worker: start to sleep for {} second'.format(time.time(), second)
        print msg

        time.sleep(float(second))
        print '[{}] worker: end sleep for {} second'.format(time.time(), second)
        return 'server time cost for {} second sleep: {}'.format(second, time.time() - now)

    @public('exception_test')
    def test_exception(self):
        time.sleep(1)
        print 'raises exception on purpose'
        raise Exception('Test Exception, raises exception on purpose')


# test driver class; only for demo & testing
class driver(object):
    def __init__(self):
        self.bus = bus()
        self.axi = axi()

    @public
    def echo(self, a):
        if len(a) > 128:
            msg = a[:125] + '...'
        else:
            msg = a
        print('Echoing {} back to client.'.format(msg))
        return a

    @public
    def fun(self, a=None, b=None):
        if not a and not b:
            ret = 'calling driver.fun()'
        elif a and b:
            ret = 'calling driver.fun({}, {})'.format(a, b)
        return ret

    @public
    def fun_kwargs(self, a, b):
        ret = 'calling driver.fun_kwargs(a={}, b={})'.format(a, b)
        return ret

    def driver_private_fun(self):
        ret = 'driver private fun'
        return ret


class bus(object):
    def __init__(self):
        self.axi = axi()

    @public
    def fun(self):
        ret = 'calling driver.bus.fun()'
        return ret

    def bus_private_fun(self):
        ret = 'bus private fun'
        return ret


class axi(object):
    def __init__(self):
        pass

    @public
    def fun(self):
        ret = 'calling axi.fun()'
        return ret

    def axi_private_fun(self):
        ret = 'axi private fun'
        return ret
