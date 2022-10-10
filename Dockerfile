FROM arm64v8/golang:alpine3.13 AS builder

RUN apk update
RUN apk add make git wget
RUN wget https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_arm.tar.gz -O - |\
    tar xz && mv yq_linux_arm /usr/bin/yq
    
ADD . /root

WORKDIR /root/lnd

RUN make -j24 install tags="autopilotrpc signrpc walletrpc chainrpc invoicesrpc routerrpc watchtowerrpc"

FROM alpine:3.12 as runner

RUN apk update
RUN apk add tini curl sshpass jq openssh-client bash vim

COPY --from=builder /go/bin /usr/local/bin
COPY --from=builder /usr/bin/yq /usr/local/bin/yq
ADD ./configurator/target/aarch64-unknown-linux-musl/release/configurator /usr/local/bin/configurator
ADD ./health-check/target/aarch64-unknown-linux-musl/release/health-check /usr/local/bin/health-check
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD ./actions/import-umbrel.sh /usr/local/bin/import-umbrel.sh
RUN chmod a+x /usr/local/bin/import-umbrel.sh
ADD ./actions/add-watchtower.sh /usr/local/bin/add-watchtower.sh
RUN chmod a+x /usr/local/bin/add-watchtower.sh

WORKDIR /root

EXPOSE 9735 8080

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
