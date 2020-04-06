
# Nanolabs container stack

This project builds a docker container capable of running a Jupyter notebook
server with bioinformatics tools preconfigured. It leverages the stack
from the jupyter project: https://github.com/jupyter/docker-stacks.


## Building notebook server

To build the container stack locally run:

```
make base-notebook picolabs-notebook nanolabs-notebook
```

The above targets build a stack of containers, the first two are from the
Jupyter stack

* **base-notebook**:
all OS dependencies for notebook server that starts but lacks all features
* **minimal-notebook**:
all OS dependencies for fully functional notebook server (not used as required parts in picolabs)
* **picolabs-notebook**: 
all OS dependencies for fully functional notebook server and basic data science and plotting libraries
* **nanolabs-notebook**:
additional ONT and bioinformatics libraries

## Running the server

To start the server container run:

```
make run
```

When this runs a token will be displayed. This can be used to connect
to the server in a browser.

## Connecting Google Colab

https://colab.research.google.com/

Google Colaboratory can be told to connect to the locally running Jupyter
server. In this way an end-user gets the niceities of Google Colab whilst
having a preconfigured environment. There is a drop-down in the top-left
of the Colab interface to "Connect > Connect to local runtime...". In the
pop-up dialog enter

`http://localhost:8888/?token=<token from above>`

