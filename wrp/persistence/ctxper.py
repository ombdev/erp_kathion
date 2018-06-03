class CtxPerException(Exception):

    def __init__(self, msg = None):
        self.message = msg

    def __str__(self):
        return self.message


class CtxPer(object):
    """
    Context persistence wrapper
    """
    _adapter = None

    def __init__(self, adapter):
        self._adapter = adapter

    def __getattribute__(self, name):
        a = object.__getattribute__(self, '_adapter')
        return  getattr(a, name)
