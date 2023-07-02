FROM ubuntu:bionic

# base packages
RUN apt update && apt install -y --no-install-recommends wget curl unzip zip jq git ca-certificates

# install go
ENV PATH="$PATH:/usr/local/go/bin"
RUN wget https://golang.org/dl/go1.15.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.15.5.linux-amd64.tar.gz \
    && go version

# install bazel
RUN curl -L -o bazel-installer.sh https://github.com/bazelbuild/bazel/releases/download/3.7.0/bazel-3.7.0-installer-linux-x86_64.sh \
    && chmod +x bazel-installer.sh \
    && ./bazel-installer.sh \
    && rm bazel-installer.sh

# clone code
RUN git clone https://github.com/v2fly/v2ray-core.git \
    && cd v2ray-core \
    && git checkout $(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | jq .tag_name -r) \
    && go mod download

WORKDIR /v2ray-core

# build release
RUN bazel build --action_env=PATH=$PATH \
    --action_env=GOPATH=$(go env GOPATH) \
    --action_env=GOCACHE=$(go env GOCACHE) \
    --action_env=SPWD=$(pwd) \
    --spawn_strategy local \
    //release:all

# fetch latest files
RUN mkdir -p origin-releases \
    && cd origin-releases \
    && curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest \
    | jq ".assets[] | {browser_download_url, name}" -c \
    | jq ".browser_download_url" -r \
    | wget -i - \
    && rm *.dgst Release Release.unsigned

# ready diff
ENTRYPOINT [ "diff", "-s", "--exclude=<derived root>", "./bazel-bin/release/", "./origin-releases"]
