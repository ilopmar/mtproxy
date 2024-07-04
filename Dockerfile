# Dockerfile created from manual instructions to compile an install at https://gist.github.com/rameerez/8debfc790e965009ca2949c3b4580b91

FROM ubuntu:24.04 AS build

WORKDIR /app

RUN apt update && \
    apt install git curl build-essential libssl-dev zlib1g-dev -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN curl -s https://core.telegram.org/getProxySecret -o proxy-secret && \
    curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

RUN git clone https://github.com/GetPageSpeed/MTProxy

WORKDIR /app/MTProxy

# Add missing flags based on an unmerged PR
RUN sed s/'-fwrapv -DAES=1'/'-fwrapv -fcommon -DAES=1'/g -i Makefile && \
    sed s/'-lpthread -lcrypto'/'-lpthread -lcrypto -fcommon'/g -i Makefile

RUN make

FROM ubuntu:24.04

RUN apt update && \
    apt install curl xxd -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

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
