FROM nginx:1.17.9-alpine

ARG HUGO_VERSION=0.69.0

RUN apk add --update wget ca-certificates && \
    cd /tmp/ && \
    wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz && \
    tar xzf hugo_${HUGO_VERSION}_Linux-64bit.tar.gz && \
    rm -r hugo_${HUGO_VERSION}_Linux-64bit.tar.gz && \
    mv hugo /usr/bin/hugo && \
    apk del wget ca-certificates && \
    rm /var/cache/apk/*

WORKDIR /website
COPY website .
COPY config/nginx.conf /etc/nginx/conf.d/default.conf

RUN hugo -v -s /website -d /usr/share/nginx/html

EXPOSE 80