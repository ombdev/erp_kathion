#!/usr/bin/python3

from publisher.server import PublisherServer
from publisher.routing.helpers import init_routers
from publisher.routing.lookup import lookup_routing


if __name__ == '__main__':

    server = PublisherServer(lambda api: init_routers(api, lookup_routing))
    server(host='0.0.0.0', debug=True)
