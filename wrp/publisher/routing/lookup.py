import publisher.resources.hello as hello


# lookup routing table

lookup_routing  = [

    # ( Resource  , *urls ) , **kwargs

    ( ( hello.Greeting , '/' ) , {} ),
]
