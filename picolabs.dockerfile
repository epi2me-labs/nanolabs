# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified for and by Oxford Nanopore Technologies
ARG BASE_CONTAINER=jupyter/base-notebook
FROM $BASE_CONTAINER
LABEL maintainer="Oxford Nanopore Technologies"

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    vim-tiny \
    git \
    inkscape \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    # ---- nbconvert dependencies ----
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    # ----
    tzdata \
    unzip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

USER $NB_UID

RUN \
  conda config --system --append channels bioconda \
  && conda config --system --prepend channels epi2melabs \
  && conda install mamba --quiet --yes \
  && mamba install --quiet --yes --freeze-installed \
    'bokeh=2.2.*' \
    'jinja2=2.11.3' \
    'conda-forge::blas=*=openblas' \
    'hdf5=1.12.0' \
    'jupyter-lsp=0.9.3' \
    'python-language-server=0.36.2' \
    'matplotlib-base=3.3.*' \
    'conda-forge::r-base=4.0.3' \
    'conda-forge::r-essentials' \
    'parallel' \
    'pandas=1.2.*' \
    'protobuf=3.14.*' \
    'scikit-learn=0.24.*' \
    'scipy=1.6.*' \
    # downgrade to fix "should_run_async" ipykernel warning
    'ipython=7.10.*' \
    'ipywidgets' \
    # fix AttributeError: 'ExtensionManager' object has no attribute '_extensions'
    'nbclassic=0.3.1' \
  && mkdir ~/.parallel && touch ~/.parallel/will-cite \
  && conda clean --all -f -y \
  && conda init bash \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "/home/${NB_USER}"

# jupyter extensions
RUN \
  # our own modifications
  pip install --no-cache-dir \
    igv-jupyterlab \
    aquirdturtle_collapsible_headings \
    jupyter_bokeh \
    jupyterlab-lsp \
    jupyterlab-slash-copy-path \
    jupyterlab-autorun-cells \
    jupyterlab-play-cell-button \
    jupyterlab-code-cell-collapser \
    epi2melabs-splashpage \
    epi2melabs-splash \
    epi2melabs-theme \
  # build things
  && jupyter lab build -y --name='EPI2MELabs' --dev-build=False --minimize=True \
  && jupyter lab clean -y \
  && npm cache clean --force \
  && rm -rf "${CONDA_DIR}/share/jupyter/lab/staging" \
  && rm -rf "/home/${NB_USER}/.cache/yarn" \
  && rm -rf "/home/${NB_USER}/.node-gyp" \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "/home/${NB_USER}"

# copy user settings for jupyterlab
USER root
COPY user-settings /home/$NB_USER/.jupyter/lab/user-settings
COPY config/pycodestyle /home/$NB_USER/.config/
RUN fix-permissions "/home/${NB_USER}"
# favicon
COPY favicon.png /opt/conda/share/jupyterhub/static/favicon.ico 
COPY favicon.png /opt/conda/lib/python3.6/site-packages/notebook/static/favicon.ico 
COPY favicon.png /opt/conda/lib/python3.6/site-packages/notebook/static/base/images/favicon.ico
# default theme (can this be in user-settings?)
COPY overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json
# copy script for injecting user permissions
# TODO: this is all a bit unnecessary, we could instead run directly as
# host user, but add host user to the notebook group with docker --group-add
ENV NB_HOST_USER=nbhost
COPY run_as_user.sh /usr/local/bin/
COPY startup.sh /usr/local/bin/start-notebook.d/
RUN \
  # allow notebook user to add new users, see run_as_user.sh
  echo "${NB_USER} ALL=(root) NOPASSWD: /usr/sbin/useradd" > /etc/sudoers.d/${NB_USER} \
  # and allow notebook user to run notebook as NB_HOST_USER
  && echo "${NB_USER} ALL=(${NB_HOST_USER}) NOPASSWD:SETENV: /usr/local/bin/start-notebook.sh" >> /etc/sudoers.d/${NB_USER} \
  && fix-permissions ${HOME}
USER $NB_UID

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
RUN \
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" \
  && fix-permissions "/home/${NB_USER}"

USER $NB_UID

