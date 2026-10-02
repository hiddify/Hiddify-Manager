# --- Admin V2 UI -------------------------------------------------------------
# Built in a throwaway stage: only its output reaches the final image, which has
# no Node.js. The output is plain JS/CSS, so build it on the build machine's own
# platform even for arm64 images (no QEMU emulation).
FROM --platform=$BUILDPLATFORM node:20-bookworm-slim AS panel-ui
WORKDIR /panel/hiddifypanel/admin_v2
COPY services/panel/src/hiddifypanel/admin_v2/package.json services/panel/src/hiddifypanel/admin_v2/package-lock.json ./
RUN npm ci --no-audit --no-fund --loglevel=error
COPY services/panel/src/hiddifypanel/admin_v2/ ./
COPY services/panel/src/hiddifypanel/translations.i18n/ /panel/hiddifypanel/translations.i18n/
# vite writes to ../static/admin-v2 (/panel/hiddifypanel/static/admin-v2)
RUN npm run build

# --- Hiddify Manager ------------------------------------------------------------
FROM ubuntu:24.04
EXPOSE 80
EXPOSE 443

ENV TERM=xterm
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV HIDDIFY_DISABLE_UPDATE=true
ENV DOCKER_MODE=true
USER root
WORKDIR /opt/hiddify-manager/

COPY . .
COPY --from=panel-ui /panel/hiddifypanel/static/admin-v2/ ./services/panel/src/hiddifypanel/static/admin-v2/

# python-systemctl must be a real file in /usr/bin (a relative symlink from

RUN mkdir -p /etc/sudoers.d/ && \
    apt-get update && apt-get install -y --no-install-recommends python3 ca-certificates && \
    mkdir -p /opt/hiddify-manager/data && \
    bash ./scripts/common/hiddify_installer.sh docker --no-gui --no-log && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/* && \
    echo "Defaults:hiddify-panel !requiretty" >/etc/sudoers.d/hiddify && \
    echo "hiddify-panel ALL=(root) NOPASSWD: /opt/hiddify-manager/scripts/common/commander.py" >>/etc/sudoers.d/hiddify && \
    chmod 440 /etc/sudoers.d/hiddify



ENTRYPOINT ["./scripts/docker-init.sh"]
