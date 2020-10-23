# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Modified for and by Oxford Nanopore Technologies
ARG BASE_CONTAINER=jupyter/base-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Oxford Nanopore Technologies"

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # ffmpeg for matplotlib anim
    ffmpeg \
    # taken from minimal-notebook@9b983ea
    build-essential \
    #emacs \
    git \
    inkscape \
    #jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    python-dev \
    # ---- nbconvert dependencies ----
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    # ----
    tzdata \
    unzip \
    #nano \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

USER $NB_UID

RUN \
  conda config --system --append channels bioconda \
  && conda install mamba --quiet --yes \
  && mamba install --quiet --yes \
    'bokeh=2.1.*' \
    'jupyter_bokeh' \
    'conda-forge::blas=*=openblas' \
    'ipywidgets=7.5.*' \
    'matplotlib-base=3.2.*' \
    'conda-forge::r-base=4.0.2' \
    'conda-forge::r-essentials' \
    'jupyter-lsp' \
    'parallel' \
    'pandas=1.1.*' \
    'protobuf=3.12.*' \
    'python-language-server' \
    'scikit-learn=0.23.*' \
    'scipy=1.5.*' \
    'seaborn=0.10.*' \
    'widgetsnbextension=3.5.*' \
    'xlrd=1.2.0' \
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
  # Check this URL for most recent compatibilities
  # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
  && jupyter labextension install @jupyter-widgets/jupyterlab-manager@^2.0.0 --no-build \
  ## table of contents in left-hand panel for navigation
  && jupyter labextension install @jupyterlab/toc --no-build \
  ## our own modifications
  && jupyter labextension install @epi2melabs/jupyterlab-autorun-cells --no-build \
  && jupyter labextension install @epi2melabs/jupyterlab-play-cell-button --no-build \
  && jupyter labextension install @epi2melabs/jupyterlab-code-cell-collapser --no-build \
  && jupyter labextension install @epi2melabs/epi2melabs-splashpage --no-build \
  ## allow markdown headings to collapse whole sections
  && jupyter labextension install @aquirdturtle/collapsible_headings --no-build \
  ## language server
  && jupyter labextension install @krassowski/jupyterlab-lsp --no-build \
  ## colab extension
  && pip install --no-cache-dir jupyter_http_over_ws \
  && jupyter serverextension enable --py jupyter_http_over_ws \
  ## bokeh
  && jupyter labextension install @bokeh/jupyter_bokeh@2.0.3 --no-build \
  ## interactive matplotlib graphs
  # DISABLED - doesn't work in colab, to enabled add back 'ipympl=0.5.0' to conda install
  #&& jupyter labextension install jupyter-matplotlib --no-build \
  ## plotly - https://plot.ly/python/getting-started/#jupyterlab-support-python-35
  # DISABLED: breaks web socket connections with medium-sized data
  #&& export NODE_OPTIONS=--max-old-space-size=4096 \
  #&& jupyter labextension install jupyterlab-plotly@1.5.0 --no-build \
  #&& jupyter labextension install plotlywidget@1.5.0 --no-build \
  #&& unset NODE_OPTIONS \
  ## github extension
  # not needed in colab, added for nocolab option, removed as its
  # unauthenticated and so of limited utility
  #&& jupyter labextension install @jupyterlab/github --no-build \
  #&& pip install jupyterlab_github \
  # build things
  && jupyter lab build -y \
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
USER $NB_UID

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
RUN \
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" \
  && fix-permissions "/home/${NB_USER}"

USER $NB_UID

