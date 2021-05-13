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
BASEARGS     =
PICOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/base-notebook
NANOLABSARGS =--build-arg BASE_CONTAINER=$(OWNER)/picolabs-notebook --build-arg DATE=$(DATE)

# require that we have been given a few version strings
check-versions:
ifndef APLANAT_VERSION
	$(error APLANAT_VERSION is undefined)
endif
ifndef EPI2MELABS_VERSION
	$(error EPI2MELABS_VERSION is undefined)
endif
ifndef MAPULA_VERSION
	$(error MAPULA_VERSION is undefined)
endif

.PHONY: base-notebook
base-notebook:
> cd docker-stacks
> git checkout -- base-notebook/Dockerfile
> make build/base-notebook OWNER=$(OWNER) DARGS="$(BASEARGS)"

.PHONY: picolabs-notebook
picolabs-notebook:
> docker build --rm --force-rm $(PICOLABSARGS) -t $(OWNER)/$@:latest -f picolabs.dockerfile .

.PHONY: nanolabs-notebook
nanolabs-notebook: check-versions
> docker build --rm --force-rm $(NANOLABSARGS) --build-arg APLANAT_VERSION=$(APLANAT_VERSION) --build-arg EPI2MELABS_VERSION=$(EPI2MELABS_VERSION) --build-arg MAPULA_VERSION=$(MAPULA_VERSION) -t $(OWNER)/$@:latest -f nanolabs.dockerfile .

