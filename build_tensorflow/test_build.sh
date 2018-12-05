#!/bin/bash

set -eu -o pipefail

# https://github.com/multiarch/qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static:register --reset

docker build "$(mktemp -d)" \
       --build-arg HOST_UID="$(id -u)" \
       -t cross-build-tester \
       -f -<<'_DOCKERFILE_EOF_'
FROM multiarch/ubuntu-core:arm64-xenial AS TF_DEPS_LAYER

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    g++ \
    gfortran \
    pkg-config \
    ca-certificates \
    libhdf5-dev \
    libopenblas-dev \
    libeigen3-dev \
    python3 \
    python3-dev \
    sudo

RUN curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3

RUN python3 -m pip install --no-cache-dir \
    numpy \
    h5py \
    grpcio

RUN rm -rf /var/lib/apt/lists/*

FROM TF_DEPS_LAYER AS RUNTIME
ARG HOST_UID
ENV CONTAINER_USER_ID=${HOST_UID}
ENV CONTAINER_USER_NAME=tensorflow

# Create users
ARG HOST_UID
ENV CONTAINER_USER_ID=${HOST_UID}
ENV CONTAINER_USER_NAME=tensorflow

RUN useradd --shell /bin/bash \
	-u "${CONTAINER_USER_ID}" -o -c "" \
	-m "${CONTAINER_USER_NAME}"
RUN echo "${CONTAINER_USER_NAME}:${CONTAINER_USER_NAME}" | chpasswd
RUN usermod -aG sudo ${CONTAINER_USER_NAME}
RUN mkdir -p /etc/sudoers.d
RUN echo "${CONTAINER_USER_NAME} ALL=(ALL) NOPASSWD: ALL" \
     > "/etc/sudoers.d/${CONTAINER_USER_NAME}"

ENV USER ${CONTAINER_USER_NAME}
ENV HOME /home/"${CONTAINER_USER_NAME}"
RUN chmod a+w /home/"${CONTAINER_USER_NAME}"
RUN chown "${CONTAINER_USER_NAME}" /home/"${CONTAINER_USER_NAME}"

_DOCKERFILE_EOF_

docker run -it \
       --user="$(id -u)" \
       --privileged \
       --ipc=host \
       -v ${PWD}:/workspace -w /workspace \
       cross-build-tester \
       /bin/bash
