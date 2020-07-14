ARG BASE_CONTAINER=ontresearch/nanolabs-notebook:v0.2.1
FROM $BASE_CONTAINER
 
LABEL maintainer="Oxford Nanopore Technologies"
 
USER $NB_UID
WORKDIR $HOME
 
RUN git clone https://github.com/epi2me-labs/resources.git \
  && git clone https://github.com/epi2me-labs/tutorials.git \
  && mv resources/*.ipynb . \
  && mv tutorials/*.ipynb . \
  && for i in *.ipynb; \
  do echo "$i"; \
    # preserve the colab breakout link; but move other links to internal
    sed -i -E 's#[^"]https://colab.research.google.com/github/epi2me-labs/[^/]+/blob/master/#(#g' $i; \
  done \
  # ipynb documents read only
  && chmod a-w *.ipynb \
  && rm -rf resources tutorials
 

USER root
  # install github plugin and the jupyter toc
RUN jupyter labextension install @jupyterlab/github \
  && pip install jupyterlab_github \
  && jupyter serverextension enable --sys-prefix jupyterlab_github \
  && jupyter labextension install @jupyterlab/toc 
USER $NB_UID
