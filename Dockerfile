FROM alpine AS libs

RUN apk add cmake curl gcc git libc-dev linux-headers make openssl-dev perl

ARG LIBSSH2_VERSION=1.9.0
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

ARG OPENSSL_MAJOR_VERSION=1.1.1
ARG OPENSSL_PATCH_RELEASE=e
RUN cd /tmp \
 && curl -sL https://www.openssl.org/source/old/${OPENSSL_MAJOR_VERSION}/openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_PATCH_RELEASE}.tar.gz | tar xz \
 && cd openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_PATCH_RELEASE} \
 && ./config \
 && make \
 && mv libcrypto.a libssl.a /tmp/ \
 && cd /tmp \
 && rm /tmp/openssl-${OPENSSL_MAJOR_VERSION}${OPENSSL_PATCH_RELEASE} -fR

FROM crystallang/crystal:0.33.0-alpine AS builder
COPY --from=libs /tmp/libcrypto.a /tmp/libssl.a /tmp/libssh2.a /tmp/
WORKDIR /usr/src/app
COPY shard.yml shard.lock ./
RUN shards install
COPY . .
RUN crystal build src/swm.cr  --static --cross-compile \
 && cc 'swm.o' -o 'swm' -rdynamic -static /tmp/libssh2.a /tmp/libcrypto.a /tmp/libssl.a  /usr/lib/libpcre.a /usr/lib/libgc.a /usr/share/crystal/src/ext/libcrystal.a /usr/lib/libevent.a

FROM scratch
COPY --from=builder /usr/src/app/swm /
ENTRYPOINT ["/swm"]
