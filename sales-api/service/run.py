import grpc


def _engage():
    pass


if __name__ == '__main__':

    try:
        _engage()
    except KeyboardInterrupt:
        print('Exiting')
    except:
        if True:
            print('Whoops! Problem in server:', file=sys.stderr)
            traceback.print_exc(file=sys.stderr)
        sys.exit(1)

    # assuming everything went right, exit gracefully
    sys.exit(0)
