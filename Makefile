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
	SEDI=sed -i
endif

DATE=$(shell date +%s)

OWNER := ontresearch
BASEARGS     =--build-arg PYTHON_VERSION=3.6
MINIMALARGS  =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
PICOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
NANOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/picolabs-notebook --build-arg DATE=$(DATE)

.PHONY: base-notebook
base-notebook:
> cd docker-stacks
> git checkout -- base-notebook/Dockerfile
> patch -p0 -i ../baselabs.dockerfile 
> make build/base-notebook OWNER=$(OWNER) DARGS="$(BASEARGS)"

.PHONY: minimal-notebook
minimal-notebook:
> cd docker-stacks
> make build/minimal-notebook OWNER=$(OWNER) DARGS="$(MINIMALARGS)"

.PHONY: picolabs-notebook
picolabs-notebook:
> docker build --rm --force-rm $(PICOLABSARGS) -t $(OWNER)/$@:latest -f picolabs.dockerfile .

# require that we have been given a few version strings
check-versions:
ifndef APLANAT_VERSION
	$(error APLANAT_VERSION is undefined)
endif
ifndef EPI2MELABS_VERSION
	$(error EPI2MELABS_VERSION is undefined)
endif

.PHONY: nanolabs-notebook
nanolabs-notebook: check-versions
> docker build --rm --force-rm $(NANOLABSARGS) --build-arg APLANAT_VERSION=$(APLANAT_VERSION) --build-arg EPI2MELABS_VERSION=$(EPI2MELABS_VERSION) -t $(OWNER)/$@:latest -f nanolabs.dockerfile .

