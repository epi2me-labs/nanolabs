#!/bin/bash
set -u

HOSTUID=$1
shift
echo "Providing permissions to host user for notebook group..."

if [[ "${HOSTUID}" == "${NB_UID}" ]]; then
    echo 'Nothing to be done, host UID is equal to ${NB_UID}: '"${NB_UID}"
    echo "Executing command directly"
    "${@}"
else
    echo "Adding UID ${HOSTUID} to notebook group as ${NB_HOST_USER}"
    sudo useradd -s /bin/bash -N -g ${NB_GID} -M -d ${HOME} -u ${HOSTUID} ${NB_HOST_USER}
    echo "Executing command as: ${NB_HOST_USER} (${HOSTUID})"
    sudo -E PATH=${PATH} -u ${NB_HOST_USER} "${@}"
fi

