ARG BASE_IMAGE="alpine"
ARG BASE_IMAGE_TAG="latest"
FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}

ARG BASE_IMAGE
ARG BASE_IMAGE_TAG
ARG ARCH="amd64"
ARG PLATFORM="linux"
ARG TAG=""
ARG TAG_ROLLING=""
ARG BUILD_DATE=""
ARG IMAGE_VCS_REF=""
ARG VCS_REF=""
ARG FHEM_VERSION=""
ARG IMAGE_VERSION=""

ENV LANG=de_DE.UTF-8 \
   LANGUAGE=de_DE:de \
   LC_ADDRESS=de_DE.UTF-8 \
   LC_MEASUREMENT=de_DE.UTF-8 \
   LC_MESSAGES=de_DE.UTF-8 \
   LC_MONETARY=de_DE.UTF-8 \
   LC_NAME=de_DE.UTF-8 \
   LC_NUMERIC=de_DE.UTF-8 \
   LC_PAPER=de_DE.UTF-8 \
   LC_TELEPHONE=de_DE.UTF-8 \
   LC_TIME=de_DE.UTF-8 \
   TERM=xterm \
   TZ=Europe/Berlin \
   LOGFILE=./log/fhem-%Y-%m-%d.log \
   TELNETPORT=7072 \
   FHEM_UID=6061 \
   FHEM_GID=6061 \
   FHEM_PERM_DIR=0750 \
   FHEM_PERM_FILE=0640 \
   UMASK=0037 \
   BLUETOOTH_GID=6001 \
   GPIO_GID=6002 \
   I2C_GID=6003 \
   TIMEOUT=10 \
   CONFIGTYPE=fhem.cfg

# Install base environment
COPY ./src/qemu-* /usr/bin/
COPY src/entry.sh /entry.sh
COPY src/ssh_known_hosts.txt /ssh_known_hosts.txt
COPY src/health-check.sh /health-check.sh
COPY src/find-* /usr/local/bin/
COPY src/99_DockerImageInfo.pm /fhem/FHEM/

RUN chmod 755 /*.sh /usr/local/bin/* && LC_ALL=C \
&& apk add \
     curl \
     i2c-tools \
     jq \
     busybox-extras \
     wget \
     usbutils \
     libcap-ng-utils \
     make \
     gcc \
     grep \
     sudo \
     bash \
     openssl \
     openssl-dev \
     zlib-dev \
     openssh-client \
     perl-boolean \     
     perl-dev \
     musl-dev \
     perl-app-cpanminus \
     perl-device-serialport \
     perl-module-pluggable \
     # Install cultures (same approach as Alpine SDK image)
     tzdata icu-libs \
   && cpanm --notest -i \
     App::cpanoutdated \
     Perl::PrereqScanner::NotQuiteLite \
     Cpanel::JSON::XS \
     JSON \
     JSON::XS \
     IO::Socket::SSL \
     Net::MQTT::Simple \     
     Net::MQTT::Constants \
   && apk del make gcc musl-dev perl-dev zlib-dev openssl-dev \
   && rm -rf /var/cache/apk/* \
   && rm -rf /root/.cpanm
     
COPY src/fhem/trunk/fhem/ /fhem/

VOLUME [ "/opt/fhem" ]

EXPOSE 8083

HEALTHCHECK --interval=20s --timeout=10s --start-period=60s --retries=5 CMD /health-check.sh

WORKDIR "/opt/fhem"
ENTRYPOINT [ "/entry.sh" ]
CMD [ "start" ]
