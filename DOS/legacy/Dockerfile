FROM dockette/jessie AS legacy-builder
MAINTAINER eplauchu@agnux.com

RUN apt-get update

# JDK 7 and more to build war
RUN apt-get install -y wget openjdk-7-jdk default-jdk maven \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME="/usr/lib/jvm/default-java"


WORKDIR /yield/r1

CMD ["mvn"]
