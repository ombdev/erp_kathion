from flask import Flask
from flask_restful import Api


class PublisherServer(object):

    def __init__(self, router_conf_handler):

        self._app = Flask(__name__)
        self._api = router_conf_handler(Api(self._app))


    def __call__(self, *args, **kwargs):

        self._app.run(*args, **kwargs)
