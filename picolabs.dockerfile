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
  && conda install mamba==0.7.1 --quiet --yes \
  # ipykernel is pinned here simply to avoid messy DeprecationWarnings
  #   # (possibly resulting from retrofitting jupyterlab 2.2.9?)
  && mamba install --quiet --yes \
    'bokeh=2.2.*' \
    'jupyter_bokeh' \
    'conda-forge::blas=*=openblas' \
    'ipykernel=5.3.4' \
    'ipywidgets=7.6.*' \
    'matplotlib-base=3.3.*' \
    'conda-forge::r-base=4.0.3' \
    'conda-forge::r-essentials' \
    'jupyter-lsp' \
    'parallel' \
    'pandas=1.2.*' \
    'protobuf=3.14.*' \
    'python-language-server' \
    'scikit-learn=0.24.*' \
    'scipy=1.6.*' \
    'widgetsnbextension=3.5.*' \
  && mkdir ~/.parallel && touch ~/.parallel/will-cite \
  && conda clean --all -f -y \
  && conda init bash \
  && fix-permissions "${CONDA_DIR}" \
  && fix-permissions "/home/${NB_USER}"

# jupyter extensions
RUN \
  ## Activate ipywidgets extension in the environment that runs the notebook server
  jupyter nbextension enable --py widgetsnbextension --sys-prefix \
  ## Also activate ipywidgets extension for JupyterLab
  ##&& pip install jupyterlab_widgets \ # for JL3.x
  && jupyter labextension install @jupyter-widgets/jupyterlab-manager@^2.0.0 --no-build \
  ## our own modifications
  && pip install --no-cache-dir igv-jupyterlab \
  ## shouldn't need this, but further investigation is required to debug
  && jupyter labextension install @epi2melabs/igv-jupyterlab --no-build \
  && jupyter labextension install @epi2melabs/jupyterlab-autorun-cells --no-build \
  && jupyter labextension install @epi2melabs/jupyterlab-play-cell-button --no-build \
  && jupyter labextension install @epi2melabs/jupyterlab-code-cell-collapser --no-build \
  && jupyter labextension install @epi2melabs/epi2melabs-splashpage --no-build \
  && jupyter labextension install @epi2melabs/epi2melabs-splash --no-build \
  && jupyter labextension install @epi2melabs/epi2melabs-theme --no-build \
  ## allow markdown headings to collapse whole sections
  && jupyter labextension install @aquirdturtle/collapsible_headings --no-build \
  ## language server
  && jupyter labextension install @krassowski/jupyterlab-lsp --no-build \
  ## bokeh
  && jupyter labextension install @bokeh/jupyter_bokeh@2.0.3 --no-build \
  # build things
  && jupyter lab build -y --name='EPI2MELabs' \
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

