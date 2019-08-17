# This is a multi-stage build which requires Docker 17.05 or higher
FROM python:3.7-alpine as molecule-builder
WORKDIR /usr/src/molecule

ENV PACKAGES="\
    gcc \
    git \
    libffi-dev \
    make \
    musl-dev \
    openssl-dev \
    "
RUN apk add --update --no-cache ${PACKAGES}

ENV MOLECULE_EXTRAS="azure,docker,docs,ec2,gce,hetznercloud,linode,lxc,openstack,vagrant,windows"

ADD . .
RUN \
    pip wheel \
    -w dist \
    ".[${MOLECULE_EXTRAS}]"

# ✄---------------------------------------------------------------------
# This is an actual target container:
FROM python:3.7-alpine
LABEL maintainer "Ansible <info@ansible.com>"

ENV PACKAGES="\
    docker \
    git \
    openssh-client \
    ruby \
    "

ENV BUILD_DEPS="\
    gcc \
    libc-dev \
    make \
    ruby-dev \
    ruby-rdoc \
    "

ENV PIP_INSTALL_ARGS="\
    --only-binary :all: \
    --no-index \
    -f /usr/src/molecule/dist \
    "

ENV GEM_PACKAGES="\
    rubocop \
    json \
    etc \
    "

ENV MOLECULE_EXTRAS="azure,docker,docs,ec2,gce,hetznercloud,linode,lxc,openstack,vagrant,windows"

RUN apk add --update --no-cache ${BUILD_DEPS} ${PACKAGES}
RUN gem install ${GEM_PACKAGES}
RUN apk del --no-cache ${BUILD_DEPS}
RUN rm -rf /root/.cache
COPY --from=molecule-builder \
    /usr/src/molecule/dist \
    /usr/src/molecule/dist
RUN pip install ${PIP_INSTALL_ARGS} "molecule[${MOLECULE_EXTRAS}]"

ENV SHELL /bin/bash
