FROM alpine:latest AS downloader

ARG DOWNLOAD_URL

RUN mkdir -p /opt/temp \
    && wget -O /opt/temp/cli.tar.gz "$DOWNLOAD_URL" \
    && tar x -f /opt/temp/cli.tar.gz -C /opt/temp \
    && chmod 755 /opt/temp/infisical \
    && chown 1100:1100 /opt/temp/infisical

FROM alpine:latest
RUN addgroup -g 1100 user \
    && adduser -h /home/user -s /bin/sh -G user -u 1100 -D user \
    && apk update && apk upgrade && apk add tini && rm -fr /var/cache/apk/* \
    && mkdir /home/user/.bin && chown user:user /home/user/.bin && chmod 755 /home/user/.bin

COPY --from=downloader /opt/temp/infisical /home/user/.bin

USER user
WORKDIR /home/user
ENV PATH="/home/user/.bin:$PATH" \
    INFISICAL_TELEMETRY=false

ENTRYPOINT  [ "/sbin/tini", "--", "/home/user/.bin/infisical" ]
