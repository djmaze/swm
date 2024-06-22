FROM alpine AS libs

RUN apk add cmake curl gcc git libc-dev linux-headers make openssl-dev perl

ARG LIBSSH2_VERSION=1.11.0
RUN cd /tmp \
 && git clone -b libssh2-${LIBSSH2_VERSION} --single-branch https://github.com/libssh2/libssh2.git \
 && cd libssh2 \
 && mkdir bin \
 && cd bin \
 && cmake -DCRYPTO_BACKEND=OpenSSL .. \
 && cmake --build . \
 && mv /tmp/libssh2/bin/src/libssh2.a /tmp/ \
 && cd /tmp \
 && rm /tmp/libssh2 -fR

ARG OPENSSL_MAJOR_VERSION=3.3.0
ARG OPENSSL_PATCH_RELEASE=
RUN cd /tmp \
 && curl -sL https://www.openssl.org/source/openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_PATCH_RELEASE}.tar.gz | tar xz \
 && cd openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_PATCH_RELEASE} \
 && ./config \
 && make \
 && mv libcrypto.a libssl.a /tmp/ \
 && cd /tmp \
 && rm /tmp/openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_PATCH_RELEASE} -fR

FROM crystallang/crystal:1.12-alpine AS builder
COPY --from=libs /tmp/libcrypto.a /tmp/libssl.a /tmp/libssh2.a /tmp/
WORKDIR /usr/src/app
COPY shard.yml shard.lock ./
RUN shards install
COPY . .
RUN CC_CMD="$(crystal build src/swm.cr  --static --cross-compile)"  \
 && echo "$CC_CMD" | sed 's/-lssh2/\/tmp\/libssh2.a/' | sh

FROM scratch
COPY --from=builder /usr/src/app/swm /
ENTRYPOINT ["/swm"]
