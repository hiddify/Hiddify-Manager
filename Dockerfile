FROM ubuntu:20.04

COPY . /opt/hiddify-config/
WORKDIR /opt/hiddify-config/
ENV TERM xterm
ENV TZ Etc/UTC
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y dialog apt-utils curl sudo systemd python2 xxd lsof

#RUN curl -L https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py -o /usr/bin/systemctl
RUN bash -c "$(cat config.env.docker) $(cat install.sh)"