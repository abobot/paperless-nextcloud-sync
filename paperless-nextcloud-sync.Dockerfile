FROM ubuntu:latest

RUN apt-get update \
  && apt-get install -y davfs2 ca-certificates locales inotify-tools \
  && mkdir -p /mnt/source \
  && mkdir -p /mnt/compare \
  && mkdir -p /mnt/webdrive \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:de
ENV LC_ALL=en_US.UTF-8
RUN locale-gen "$LC_ALL"

COPY ./start.sh /usr/local/bin
#COPY ./sync.sh /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/start.sh" ]

# docker build --file ./paperless-nextcloud-sync.Dockerfile --tag paperless-nextcloud-sync .
