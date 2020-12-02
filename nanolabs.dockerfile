# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified for and by Oxford Nanopore Technologies
ARG BASE_CONTAINER=ontresearch/picolabs-notebook:latest
FROM $BASE_CONTAINER
ARG DATE=unknown
LABEL maintainer="Oxford Nanopore Technologies"

ARG APLANAT_VERSION
ARG EPI2MELABS_VERSION

RUN test -n "$APLANAT_VERSION" || (echo "APLANAT_VERSION  not set" && false)
RUN test -n "$EPI2MELABS_VERSION" || (echo "EPI2MELABS_VERSION  not set" && false)

USER root

RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
     vim bsdmainutils tree \
     bzip2 zlib1g-dev libbz2-dev liblzma-dev libffi-dev libncurses5-dev \
     libcurl4-gnutls-dev libssl-dev curl make cmake wget python3-all-dev \
     python-virtualenv git-lfs libxml2-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# for notebooks etc
ARG RESOURCE_DIR=/epi2me-resources
RUN \
  mkdir ${RESOURCE_DIR} \
  && fix-permissions ${RESOURCE_DIR}

USER $NB_UID

# Install additional modules into root
RUN \
  mamba install --quiet --yes \
    'blast=2.9.0' \
    'bedtools=2.29.2' \
    'bcftools=1.10.2' \
    'centrifuge=1.0.4_beta' \
    'flye=2.8.1' \
    'minimap2=2.17' \
    'miniasm=0.3_r179' \
    'mosdepth=0.2.9' \
    'pomoxis=0.3.4' \
    'pyranges=0.0.76' \
    'pysam=0.16.0.1' \
    'racon=1.4.10' \
    ##'rtg-tools=3.11' \
    'samtools=1.10' \
    'seqkit=0.13.2' \
    'sniffles=1.0.11' \
    'tabix=0.2.6' \
  && conda clean --all -f -y \
  && git lfs install \
  && fix-permissions $CONDA_DIR \
  && fix-permissions /home/$NB_USER

# Installing medaka into main environment causes:
#   "Problem: package pomoxis-0.3.4-py_0 requires python >=3.4,<3.7"
# Which is odd because we should be on python3.6
# Since we're doing things in a separate end anyway, lets use
# pip and take the (the smaller) medaka/tensorflow-cpu package
ARG MEDAKA_VERSION=1.2.1
RUN \
  python3 -m venv ${CONDA_DIR}/envs/venv_medaka --prompt "(medaka) " \
  && . ${CONDA_DIR}/envs/venv_medaka/bin/activate \
  && pip install --no-cache-dir --upgrade pip \
  && pip install --no-cache-dir medaka-cpu==${MEDAKA_VERSION}

# some tools to support sniffles SV calling
ARG SV_PIPELINE_TAG=v1.6.1
RUN \
  git clone --depth 1 --branch ${SV_PIPELINE_TAG} https://github.com/nanoporetech/pipeline-structural-variation.git \
  && python3 -m venv ${CONDA_DIR}/envs/venv_svtools --prompt "(svtools) " \
  && . ${CONDA_DIR}/envs/venv_svtools/bin/activate \
  && cd pipeline-structural-variation/lib \
  && pip install --no-cache-dir . \
  && cd .. && rm -rf pipeline-structural-variation

# install guppy (minus the basecalling)
COPY ont-guppy-cpu /home/$NB_USER/ont-guppy-cpu
ENV PATH=/home/$NB_USER/ont-guppy-cpu/bin/:$PATH

# replace centrifuge download with one that just does http with wget (not ftp)
COPY centrifuge-download.http /opt/conda/bin/centrifuge-download

# our plotting and misc libraries, not on conda
RUN \
  pip install --no-cache-dir aplanat==${APLANAT_VERSION} epi2melabs==${EPI2MELABS_VERSION}


# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
