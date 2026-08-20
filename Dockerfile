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

# python-systemctl must be a real file in /usr/bin (a relative symlink from
# WORKDIR breaks). data/ is not in the git tree.
RUN apt-get update && apt-get install -y --no-install-recommends python3 ca-certificates \
    && chmod +x /opt/hiddify-manager/services/docker/systemctl /opt/hiddify-manager/services/docker/journalctl \
    && cp /opt/hiddify-manager/services/docker/systemctl /usr/bin/systemctl \
    && cp /opt/hiddify-manager/services/docker/journalctl /usr/bin/journalctl \
    && mkdir -p /opt/hiddify-manager/data \
    && bash ./scripts/common/hiddify_installer.sh docker --no-gui --no-log \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

ENTRYPOINT ["./scripts/docker-init.sh"]
