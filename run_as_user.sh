#!/bin/bash
set -u

HOSTUID=$1
shift

echo "Adding UID ${HOSTUID} to notebook group"
sudo useradd -s /bin/bash -N -g ${NB_GID} -M -d ${HOME} -u ${HOSTUID} ${NB_HOST_USER}
sudo -E PATH=${PATH} -u ${NB_HOST_USER} "${@}"
