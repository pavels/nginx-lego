FROM alpine:3.4

ENV GOPATH /go

RUN apk update && apk add ca-certificates go git && \
    rm -rf /var/cache/apk/* && \
    go get -u github.com/xenolf/lego && \
    cd /go/src/github.com/xenolf/lego && \
    go build -o /usr/bin/lego . && \
    go get -u github.com/anarcher/go-cron && \
    cd /go/src/github.com/anarcher/go-cron && \
    go build -o /usr/bin/go-cron . && \
    apk del go git && \
    rm -rf /var/cache/apk/* && \
    rm -rf /go

RUN apk update && apk add nginx supervisor gettext bash && rm -rf /var/cache/apk/*

ADD nginx.conf /
ADD supervisord.conf /
ADD crontab /etc/

ADD renew.sh /
ADD entrypoint.sh /

RUN chmod 775 /renew.sh && chmod 775 /entrypoint.sh

RUN chmod 600 /etc/crontab

RUN mkdir -p /var/lego
RUN mkdir -p /public

VOLUME /var/lego

ENTRYPOINT [ "/entrypoint.sh" ]