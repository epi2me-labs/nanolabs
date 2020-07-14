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
    # Optional dependency
    #texlive-fonts-extra \
    # ----
    tzdata \
    unzip \
    #nano \
  && rm -rf /var/lib/apt/lists/*

USER $NB_UID

# Install Python 3 packages
RUN \
  conda config --system --append channels bioconda \
  && conda install --quiet --yes \
    # bokeh 2.0.x breaks hexmaps
    'bokeh=1.4.0' \
    'conda-forge::blas=*=openblas' \
    'ipywidgets=7.5.*' \
    'conda-forge::matplotlib-base=3.2.*' \
    'pandas=1.0.3' \
    'protobuf=3.11.*' \
    'scikit-learn=0.22.*' \
    'scipy=1.4.*' \
    'conda-forge::seaborn=0.9.*' \
    'xlrd=1.2.0' \
  && conda clean --all -f -y \
  && conda init bash \
  && fix-permissions $CONDA_DIR \
  && fix-permissions /home/$NB_USER

# jupyter extensions
RUN \
  ## Activate ipywidgets extension in the environment that runs the notebook server
  jupyter nbextension enable --py widgetsnbextension --sys-prefix \
  ## Also activate ipywidgets extension for JupyterLab
  # Check this URL for most recent compatibilities
  # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
  && jupyter labextension install @jupyter-widgets/jupyterlab-manager@^1.1 --no-build \
  ## table of contents, added for no colab option
  && jupyter labextension install @jupyterlab/toc \ 
  ## colab extension
  && pip install --no-cache-dir jupyter_http_over_ws \
  && jupyter serverextension enable --py jupyter_http_over_ws \
  ## bokeh
  && jupyter labextension install @bokeh/jupyter_bokeh --no-build \
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
  # not needed in colab, added for nocolab option
  && jupyter labextension install @jupyterlab/github --no-build \
  && pip install jupyterlab_github \
  # build things
  && jupyter lab build \
  && npm cache clean --force \
  && rm -rf $CONDA_DIR/share/jupyter/lab/staging \
  && rm -rf /home/$NB_USER/.cache/yarn \
  && rm -rf /home/$NB_USER/.node-gyp \
  && fix-permissions $CONDA_DIR \
  && fix-permissions /home/$NB_USER

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN \
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" \
  && fix-permissions /home/$NB_USER

USER $NB_UID

