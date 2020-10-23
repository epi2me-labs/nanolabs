# Startup script for epi2melabs container
#   This is run by start.sh from docker-stats
#   The docker file installs it to /usr/local/bin/start-notebook.d/

MOUNT=/epi2melabs/


mkdir -p ${MOUNT}/notebooks/
