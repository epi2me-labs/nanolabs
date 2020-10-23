# Startup script for epi2melabs container
#   This is run by start.sh from docker-stats
#   The docker file installs it to /usr/local/bin/start-notebook.d/


MOUNT=/epi2melabs/
NOTEBOOKDIR=${MOUNT}/notebooks/

# new notebooks from templates are saved here:
mkdir -p ${NOTEBOOKDIR}

# trust any notebooks in the directory where we save
for file in $(find ${NOTEBOOKDIR} -name "*.ipynb"); do
    echo "Adding trust: ${file}"
    jupyter trust ${file}
done 
