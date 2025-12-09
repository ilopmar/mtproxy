# Dockerfile created from manual instructions to compile an install at https://gist.github.com/rameerez/8debfc790e965009ca2949c3b4580b91

FROM photon:5.0 AS build

WORKDIR /app

RUN tdnf update -y && \
    tdnf install -y git curl build-essential openssl-devel zlib-devel && \
    tdnf clean all

RUN curl -s https://core.telegram.org/getProxySecret -o proxy-secret && \
    curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

RUN git clone https://github.com/GetPageSpeed/MTProxy

WORKDIR /app/MTProxy

# Add missing flags based on an unmerged PR and fix architecture detection
RUN sed s/'-fwrapv -DAES=1'/'-fwrapv -fcommon -DAES=1'/g -i Makefile && \
    sed s/'-lpthread -lcrypto'/'-lpthread -lcrypto -fcommon'/g -i Makefile && \
    sed 's/HOST_ARCH := $(shell arch)/HOST_ARCH := $(shell uname -m)/g' -i Makefile

RUN make

FROM photon:5.0

RUN tdnf update -y && \
    tdnf install -y curl vim shadow gawk iproute2 && \
    tdnf clean all

RUN groupadd -r mtproxy && useradd -r -g mtproxy -d /opt/MTProxy -s /sbin/nologin -c "MTProxy User" mtproxy

WORKDIR /opt/MTProxy

COPY --from=build /app/MTProxy/objs/bin/mtproto-proxy /opt/MTProxy
COPY --from=build /app/proxy-secret /opt/MTProxy
COPY --from=build /app/proxy-multi.conf /opt/MTProxy

RUN chown -R mtproxy:mtproxy /opt/MTProxy

COPY start.sh /opt/MTProxy/start.sh
RUN chmod +x /opt/MTProxy/start.sh

USER mtproxy

EXPOSE 8443 8888

ENTRYPOINT ["/opt/MTProxy/start.sh"]
