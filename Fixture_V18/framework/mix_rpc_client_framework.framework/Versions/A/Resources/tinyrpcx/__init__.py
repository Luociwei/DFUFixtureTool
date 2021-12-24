from functools import wraps


def public(name=None):
    """Set RPC name on function.

    This function decorator will set the ``_rpc_public_name`` attribute on a
    function, causing it to be picked up if an instance of its parent class is
    registered using
    :py:func:`~tinyrpc.dispatch.RPCDispatcher.register_instance`.

    ``@public`` is a shortcut for ``@public()``.

    :param name: The name to register the function with.
    """
    # called directly with function
    if callable(name):
        f = name
        f._rpc_public_name = f.__name__
        return f

    def _(f):
        f._rpc_public_name = name or f.__name__
        return f

    return _


def var_params_list(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        import inspect
        useful_kwargs = {}
        args_info = inspect.getargspec(f)
        args_list = args_info.args
        for arg in args_list:
            if arg in kwargs:
                useful_kwargs[arg] = kwargs[arg]
        return f(*args, **useful_kwargs)
    return wrapper

