diff --git base-notebook/Dockerfile base-notebook/Dockerfile
index 020cd41..f91e34b 100644
--- base-notebook/Dockerfile
+++ base-notebook/Dockerfile
@@ -70,15 +70,15 @@ RUN mkdir /home/$NB_USER/work && \
     fix-permissions /home/$NB_USER
 
 # Install conda as jovyan and check the md5 sum provided on the download site
-ENV MINICONDA_VERSION=4.7.12.1 \
-    MINICONDA_MD5=81c773ff87af5cfac79ab862942ab6b3 \
-    CONDA_VERSION=4.7.12
+ENV MINICONDA_VERSION=4.8.3 \
+    MINICONDA_MD5=d63adf39f2c220950a063e0529d4ff74 \
+    CONDA_VERSION=4.8.3
 
 RUN cd /tmp && \
-    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
-    echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
-    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
-    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
+    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-py38_${MINICONDA_VERSION}-Linux-x86_64.sh && \
+    echo "${MINICONDA_MD5} *Miniconda3-py38_${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
+    /bin/bash Miniconda3-py38_${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
+    rm Miniconda3-py38_${MINICONDA_VERSION}-Linux-x86_64.sh && \
     echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
     conda config --system --prepend channels conda-forge && \
     conda config --system --set auto_update_conda false && \
@@ -109,7 +109,7 @@ RUN conda install --quiet --yes 'tini=0.18.0' && \
 RUN conda install --quiet --yes \
     'notebook=6.0.3' \
     'jupyterhub=1.1.0' \
-    'jupyterlab=1.2.5' && \
+    'jupyterlab=2.2.8' && \
     conda clean --all -f -y && \
     npm cache clean --force && \
     jupyter notebook --generate-config && \
