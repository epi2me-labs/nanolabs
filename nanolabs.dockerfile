# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified for and by Oxford Nanopore Technologies
ARG BASE_CONTAINER=ontresearch/picolabs-notebook:latest
FROM $BASE_CONTAINER
ARG DATE=unknown
LABEL maintainer="Oxford Nanopore Technologies"

ARG APLANAT_VERSION
ARG EPI2MELABS_VERSION
ARG MAPULA_VERSION

RUN test -n "$APLANAT_VERSION" || (echo "APLANAT_VERSION  not set" && false)
RUN test -n "$EPI2MELABS_VERSION" || (echo "EPI2MELABS_VERSION  not set" && false)
RUN test -n "$MAPULA_VERSION" || (echo "MAPULA_VERSION  not set" && false)

USER root

RUN apt-get update \
  && apt-get install -yq --no-install-recommends \
     vim bsdmainutils tree \
     bzip2 zlib1g-dev libbz2-dev liblzma-dev libffi-dev libncurses5-dev \
     libcurl4-gnutls-dev libssl-dev curl make cmake wget \
     python3-all-dev python3-venv \
     git-lfs libxml2-dev \
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
    "'aplanat=${APLANAT_VERSION}'" \
    'epi2melabs::barcoder=5.0.7_0' \
    'bedtools=2.29.2' \
    'bcftools=1.11' \
    "'epi2melabs=${EPI2MELABS_VERSION}'" \
    'flye=2.8.1' \
    "'mapula=${MAPULA_VERSION}'" \
    'minimap2=2.17' \
    'miniasm=0.3_r179' \
    'mosdepth=0.3.1' \
    'ncbitaxonomy==3.1.2=pyh7b7c402_3' \
    'pomoxis=0.3.5' \
    'pyranges=0.0.76' \
    'pysam=0.16.0.1' \
    'racon=1.4.10' \
    'samtools=1.11' \
    'seqkit=0.13.2' \
    'sniffles=1.0.11' \
    'tabix=1.11' \
  && conda clean --all -f -y \
  && git lfs install \
  && fix-permissions $CONDA_DIR \
  && fix-permissions /home/$NB_USER

# Installing medaka into main environment causes:
#   "Problem: package pomoxis-0.3.4-py_0 requires python >=3.4,<3.7"
# Which is odd because we should be on python3.6
# Since we're doing things in a separate end anyway, lets use
# pip and take the (the smaller) medaka/tensorflow-cpu package
ARG MEDAKA_VERSION=1.4.2
RUN \
  python3 -m venv ${CONDA_DIR}/envs/venv_medaka --prompt "(medaka) " \
  && . ${CONDA_DIR}/envs/venv_medaka/bin/activate \
  && pip install --no-cache-dir --upgrade pip wheel \
  && pip install --no-cache-dir medaka-cpu==${MEDAKA_VERSION}

# replace centrifuge download with one that just does http with wget (not ftp)
RUN mkdir -p /home/$NB_USER/.local/bin/
ENV PATH=/home/$NB_USER/.local/bin/:$PATH
COPY centrifuge-download.http /home/$NB_USER/.local/bin/centrifuge-download


# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
