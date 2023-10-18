FROM ubuntu:22.04
EXPOSE 80
EXPOSE 443

RUN apt-get update && apt-get install -y whiptail apt-utils curl sudo systemd python2 xxd lsof

ENV TERM xterm
ENV TZ Etc/UTC
ENV DEBIAN_FRONTEND noninteractive

USER root
WORKDIR /opt/hiddify-manager/
COPY . .
# RUN mkdir -p ~/.ssh && echo "StrictHostKeyChecking no " > ~/.ssh/config
RUN bash install.sh install-docker
RUN curl -L https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py -o /usr/bin/systemctl
ENTRYPOINT ["/bin/bash","-c", "./apply_configs.sh && tail -f /opt/hiddify-manager/log/system/*"]
