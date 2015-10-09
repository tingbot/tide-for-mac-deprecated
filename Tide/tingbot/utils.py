
class Struct(object):
    def __init__(self, **kwds):
        self.__dict__.update(kwds)


class CallbackList(object):
    def __init__(self):
        self._list = []

    def __call__(self):
        for callback in self._list:
            callback()

    def add(self, callback):
        self._list.append(callback)


# cached_property from werkzeug
_missing = object()

class cached_property(object):
    """A decorator that converts a function into a lazy property.  The
    function wrapped is called the first time to retrieve the result
    and then that calculated result is used the next time you access
    the value::

        class Foo(object):

            @cached_property
            def foo(self):
                # calculate something important here
                return 42

    The class has to have a `__dict__` in order for this property to
    work.
    """

    # implementation detail: this property is implemented as non-data
    # descriptor.  non-data descriptors are only invoked if there is
    # no entry with the same name in the instance's __dict__.
    # this allows us to completely get rid of the access function call
    # overhead.  If one choses to invoke __get__ by hand the property
    # will still work as expected because the lookup logic is replicated
    # in __get__ for manual invocation.

    def __init__(self, func, name=None, doc=None):
        self.__name__ = name or func.__name__
        self.__module__ = func.__module__
        self.__doc__ = doc or func.__doc__
        self.func = func

    def __get__(self, obj, type=None):
        if obj is None:
            return self
        value = obj.__dict__.get(self.__name__, _missing)
        if value is _missing:
            value = self.func(obj)
            obj.__dict__[self.__name__] = value
        return value


def call_with_optional_arguments(func, **kwargs):
    '''
    calls a function with the arguments **kwargs, but only those that the function defines.
    e.g.

    def fn(a, b):
        print a, b

    call_with_optional_arguments(fn, a=2, b=3, c=4)  # because fn doesn't accept `c`, it is discarded
    '''

    import inspect
    function_arg_names = inspect.getargspec(func).args

    for arg in kwargs.keys():
        if arg not in function_arg_names:
            del kwargs[arg]

    func(**kwargs)
