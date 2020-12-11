# The name coined to address the builder image
BIMG=legacy-builder

# User and group identifiers expected
EXPUID=$(shell id -u)
EXPGID=$(shell id -g)

all: image clean
	docker run -it --rm -v$(shell pwd):/yield --user ${EXPUID}:${EXPGID} ${BIMG} mvn package -DskipTests

clean:
	docker run -it --rm -v$(shell pwd):/yield --user ${EXPUID}:${EXPGID} ${BIMG} mvn clean

image:
	docker build . -t ${BIMG}
