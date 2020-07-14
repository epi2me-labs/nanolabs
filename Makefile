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


OWNER := ontresearch
BASEARGS     =--build-arg PYTHON_VERSION=3.6
MINIMALARGS  =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
PICOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
NANOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/picolabs-notebook


.PHONY: base-notebook
base-notebook:
> cd docker-stacks
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


datamount:=$(shell pwd)/labfolder
token:=$(shell head /dev/random | openssl sha1)

.PHONY: run
run:
> mkdir -p $(datamount)
> docker run \
  -d \
  -p 8888:8888 \
  -e JUPYTER_ENABLE_LAB=yes \
  -v $(datamount):/home/jovyan/work \
  ontresearch/nanolabs-notebook \
  start-notebook.sh \
  --NotebookApp.allow_origin='https://colab.research.google.com' \
  --NotebookApp.disable_check_xsrf=True \
  --port=8888 \
  --NotebookApp.port_retries=0 \
  --ip=0.0.0.0 \
  --no-browser \
  --NotebookApp.token=$(token) \
  --notebook-dir=./work
