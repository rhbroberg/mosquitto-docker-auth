FROM alpine AS builder

WORKDIR /opt

RUN \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
    build-base \
    gcc \
    git

RUN \
    apk add --no-cache \
    pkgconf  \
    libressl-dev \
    mariadb-connector-c-dev \
    postgresql-dev \
    mosquitto-dev \
    mongo-c-driver-dev \
    sqlite-dev \
    libmemcached-dev \
    hiredis-dev \
    openldap-dev \
    curl-dev

RUN git clone https://github.com/rhbroberg/mosquitto-auth-plug.git

RUN \
    cd mosquitto-auth-plug && \
    sed -e 's/^\(BACKEND_.*=\).*/\1 yes/g' < config.mk.in > config.mk && \
    make

RUN ldd mosquitto-auth-plug/*.so || true

FROM eclipse-mosquitto

WORKDIR /opt

COPY --from=builder /opt/mosquitto-auth-plug/*.so ./

# thanks, https://silvenga.com/alpine-missing-dependencies/ !
RUN \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
    inotify-tools \
    mariadb-connector-c \
    libpq \
    mongo-c-driver \
    hiredis \
    curl \
    libmemcached \
    sqlite-libs && \
    rm -f /var/cache/apk/*

RUN ldd *.so || true

CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
