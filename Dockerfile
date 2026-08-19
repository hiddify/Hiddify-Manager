FROM ubuntu:24.04
EXPOSE 80
EXPOSE 443

ENV TERM=xterm
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV HIDDIFY_DISABLE_UPDATE=true
USER root
WORKDIR /opt/hiddify-manager/

COPY . .

RUN cp services/docker/* /usr/bin/ && \
    mkdir -p /hiddify-data/ssl/ && \
    rm -rf /opt/hiddify-manager/data/ssl && \
    ln -sf /hiddify-data/ssl /opt/hiddify-manager/data/ssl && \
    bash -c "./scripts/common/hiddify_installer.sh docker --no-gui" &&\
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/* 

ENTRYPOINT ["./scripts/docker-init.sh"]
