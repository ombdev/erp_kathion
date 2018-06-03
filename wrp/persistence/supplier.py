from urllib.parse import urlparse
from persistence.mongoadapter import MongoAdapter
from persistence.mockadapter import MockAdapter


class Supplier(object):

    __SUPPORTED = { 'mongodb': MongoAdapter, 'mockdb': MockAdapter }

    @staticmethod
    def get(logger, uri):

        def resolve(n):
            ic = Supplier.__SUPPORTED.get(n.scheme.lower(), None)
            if ic is not None:
                return ic(logger, uri)
            else:
                raise Exception("Such uri is not supported yet")

        uri_parsed = urlparse(uri)
        return resolve(uri_parsed)
