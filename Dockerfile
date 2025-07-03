#check=skip=SecretsUsedInArgOrEnv
FROM docker:dind AS base

# Set environment variables in a single layer
ARG DIR_NAME
ENV DIR_NAME=${DIR_NAME} \
    CUR_PROJECT=${DIR_NAME//\//-} \
    CACHES=/caches \
    ACTOR=tester \
    TOKEN=xK9#mP2a \
    WORKFLOWS=/caches/${DIR_NAME//\//-}@main

COPY docker /docker
COPY target/.ssh /root/.ssh

# Install dependencies and act, and prepare volume directories
RUN apk add --no-cache curl bash git gettext jq yq rsync && \
    ACT_VERSION=$(curl -s https://api.github.com/repos/nektos/act/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    curl -Lo act.tar.gz https://github.com/nektos/act/releases/download/${ACT_VERSION}/act_Linux_x86_64.tar.gz && \
    tar -xf act.tar.gz && \
    mv act /usr/local/bin/ && \
    chmod +x /usr/local/bin/act && \
    mkdir -p /workflows /test ${WORKFLOWS} /var/log/act && \
    ln -s ${WORKFLOWS} /workflow && \
    chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/*

# Define volumes
VOLUME ["/workflows", "/test", "/target"]

# Configure healthcheck
HEALTHCHECK --interval=10s --timeout=20s --retries=30 --start-period=120s \
  CMD docker info >/dev/null 2>&1 || exit 1 ; \
      HEALTHS=$(docker compose ps --format '{{.Health}}') ; \
        [ -z "$HEALTHS" ] && exit 1 ; \
        echo "$HEALTHS" | grep -qv '^healthy$' && exit 1 ; \
      docker image inspect act-with-gh >/dev/null 2>&1 || exit 1 ; \
      BUILDING=$(docker ps --filter "status=running" --filter "name=act-with-gh" --format '{{.ID}}') ; \
        [ -n "$BUILDING" ] && exit 1 ; \
      exit 0

ENTRYPOINT ["/docker/entrypoint.sh"]
CMD ["sh", "-c", "sleep infinite"]
