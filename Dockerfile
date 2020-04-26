FROM golang:1.14 as builder

WORKDIR /go/src/mikefarah/yq

# cache devtools
COPY ./scripts/devtools.sh /go/src/mikefarah/yq/scripts/devtools.sh
RUN ./scripts/devtools.sh

COPY . /go/src/mikefarah/yq

RUN CGO_ENABLED=0 make local build \
    && apt-get -q update && apt-get -qy install patch \
    && patch '/go/pkg/mod/gopkg.in/yaml.v3@v3.0.0-20200313102051-9f266ea9e77c/apic.go' <yaml3-feature-nobr-emitter.patch \
    && rm -rf /var/lib/apt/lists/* \
    && CGO_ENABLED=0 make local build

# Choose alpine as a base image to make this useful for CI, as many
# CI tools expect an interactive shell inside the container
FROM alpine:3.8 as production

COPY --from=builder /go/src/mikefarah/yq/yq /usr/bin/yq
RUN chmod +x /usr/bin/yq

ARG VERSION=none
LABEL version=${VERSION}

WORKDIR /workdir
