SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

OS := $(shell uname)
ifeq ($(OS), Darwin)
	SEDI=sed -i '.bak'
else
	echo $(OS)
	SEDI=sed -i
endif

DATE=$(shell date +%s)

OWNER := ontresearch
BASEARGS     =--build-arg PYTHON_VERSION=3.6
MINIMALARGS  =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
PICOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
NANOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/picolabs-notebook --build-arg DATE=$(DATE)

MINICONDA_VERSION=4.8.3
MINICONDA_MD5=d63adf39f2c220950a063e0529d4ff74
CONDA_VERSION=4.8.3
JUPYTERLAB_VERSION=2.1.2

.PHONY: base-notebook
base-notebook:
> cd docker-stacks
> $(SEDI) "s/^\(ENV MINICONDA_VERSION=\)\([^ ]*\)/\1$(MINICONDA_VERSION)/" base-notebook/Dockerfile
> $(SEDI) "s/^\(    MINICONDA_MD5=\)\([^ ]*\)/\1$(MINICONDA_MD5)/" base-notebook/Dockerfile
> $(SEDI) "s/^\(    CONDA_VERSION=\)\([^ ]*\)/\1$(CONDA_VERSION)/" base-notebook/Dockerfile
> $(SEDI) 's/Miniconda3-$${MINICONDA_VERSION}-Linux-x86_64.sh/Miniconda3-py38_$${MINICONDA_VERSION}-Linux-x86_64.sh/' base-notebook/Dockerfile
> $(SEDI) "s/jupyterlab=[^']*/jupyterlab=$(JUPYTERLAB_VERSION)/" base-notebook/Dockerfile
> make build/base-notebook OWNER=$(OWNER) DARGS="$(BASEARGS)"

.PHONY: minimal-notebook
minimal-notebook:
> cd docker-stacks
> make build/minimal-notebook OWNER=$(OWNER) DARGS="$(MINIMALARGS)"

.PHONY: picolabs-notebook
picolabs-notebook:
> docker build --rm --force-rm $(PICOLABSARGS) -t $(OWNER)/$@:latest -f picolabs.dockerfile .

.PHONY: nanolabs-notebook
nanolabs-notebook:
> docker build --rm --force-rm $(NANOLABSARGS) -t $(OWNER)/$@:latest -f nanolabs.dockerfile .

