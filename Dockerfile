FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

RUN mkdir -p /app/code /app/pkg
WORKDIR /app/code

# renovate: datasource=github-releases depName=mattermost/mattermost-push-proxy versioning=semver extractVersion=^v(?<version>.+)$
ARG PUSH_PROXY_VERSION=6.4.6

# Download and extract push proxy
RUN curl -L https://github.com/mattermost/mattermost-push-proxy/releases/download/v${PUSH_PROXY_VERSION}/mattermost-push-proxy-linux-amd64.tar.gz | tar -zxf - -C /app/code && \
    chown -R cloudron:cloudron /app/code

COPY config.json.template start.sh /app/pkg/

CMD [ "/app/pkg/start.sh" ]
