# Pull base image.
FROM pivotalservices/docker-concourse-cf-tools

RUN \
  apt-get update \
  && apt-get -y install gettext-base \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
