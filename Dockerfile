FROM ubuntu:22.04
EXPOSE 80
EXPOSE 443

RUN apt-get update && apt-get install -y apt-utils curl sudo systemd xxd lsof gawk  iproute2

ENV TERM xterm
ENV TZ Etc/UTC
ENV DEBIAN_FRONTEND noninteractive

USER root
WORKDIR /opt/hiddify-manager/
COPY . .

RUN mkdir -p /hiddify-data/ssl/ && \
    rm -rf /opt/hiddify-manager/ssl && \
    ln -sf /hiddify-data/ssl /opt/hiddify-manager/ssl 
    
# RUN mkdir -p ~/.ssh && echo "StrictHostKeyChecking no " > ~/.ssh/config
ENV HIDDIFY_PANLE_SOURCE_DIR=/opt/hiddify-manager/hiddify-panel/src/
ENV DOCKER_MODE=true
ENV USE_VENV=true
RUN bash install.sh install-docker --no-gui
RUN cp /opt/hiddify-manager/other/docker/*y /usr/bin/ 



    
ENTRYPOINT ["/bin/bash","-c", "./apply_configs.sh --no-gui && tail -f /opt/hiddify-manager/log/system/*"]
