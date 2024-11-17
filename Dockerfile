FROM ubuntu:22.04
EXPOSE 80
EXPOSE 443

ENV TERM xterm
ENV TZ Etc/UTC
ENV DEBIAN_FRONTEND noninteractive

USER root
WORKDIR /opt/hiddify-manager/
COPY . .


RUN apt-get update && apt-get install -y apt-utils curl sudo systemd xxd lsof gawk  iproute2 &&\
    mkdir -p /hiddify-data/ssl/ && \
    rm -rf /opt/hiddify-manager/ssl && \
    ln -sf /hiddify-data/ssl /opt/hiddify-manager/ssl &&\
    bash install.sh install-docker --no-gui &&\
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

COPY other/docker/ /usr/bin/

ENTRYPOINT ["./docker-init.sh"]
