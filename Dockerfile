FROM ubuntu:18.04
MAINTAINER Tomasz Jankowski

WORKDIR /root

RUN apt-get update && \
    apt-get install --no-install-recommends -yy build-essential perl libxml2-dev zlib1g-dev libxml2-utils clang llvm-dev bison flex wget git python python3 && \
    apt-get clean && \
    apt-get autoclean

RUN wget --no-check-certificate https://omnetpp.org/omnetpp/send/30-omnet-releases/2321-omnetpp-5-2-1-linux --referer=https://omnetpp.org/omnetpp -O omnetpp-5.2.1.tgz --progress=dot:giga; exit 0
RUN tar xf omnetpp-5.2.1.tgz && \
    rm omnetpp-5.2.1.tgz

RUN wget --no-check-certificate https://github.com/inet-framework/inet/releases/download/v3.6.3/inet-3.6.3-src.tgz -O inet.tgz; echo 0
RUN tar xf inet.tgz && \
    rm inet.tgz

WORKDIR /root/omnetpp-5.2.1
RUN echo "CXXFLAGS_RELEASE='-std=c++14 -O3 -DNDEBUG=1 -D_XOPEN_SOURCE'" >> configure.user
ENV PATH /root/omnetpp-5.2.1/bin:$PATH
ENV LD_LIBRARY_PATH=/root/omnetpp-5.2.1/lib:$LD_LIBRARY_PATH
RUN ls -lah; ./configure WITH_TKENV=no WITH_QTENV=no WITH_OSG=no WITH_OSGEARTH=no && \
    make -j $(nproc) MODE=release
    
WORKDIR /root/inet
RUN make makefiles && \
    make -j $(nproc) MODE=release
