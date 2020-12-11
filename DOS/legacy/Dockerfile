FROM dockette/jessie
MAINTAINER eplauchu@agnux.com

RUN apt-get update

# JDK 7 and more to build war
RUN apt-get install -y wget openjdk-7-jdk default-jdk maven \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME="/usr/lib/jvm/default-java"


# Build R1 project
COPY erp-quimicos /erp-quimicos
COPY bbgum-impt /bbgum-impt
COPY bbgum-jcli /bbgum-jcli
COPY r1 /r1
COPY service /service
WORKDIR /r1
RUN mvn clean install -DskipTests


WORKDIR /service

RUN mv ../erp-quimicos/target/agnux.war ./
RUN stat agnux.war


CMD ["/bin/bash"]
