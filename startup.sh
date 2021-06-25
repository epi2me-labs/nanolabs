# Startup script for epi2melabs container
#   This is run by start.sh from docker-stats, it is also run by the
#   labslauncher application at certain times.
#   The docker file installs it to /usr/local/bin/start-notebook.d/

trust_path () {
    DIR=$1
    # careful of spaces in filenames
    find ${DIR} -name "*.ipynb" -print0 | while read -d $'\0' file
        echo "Adding trust: ${file}"
        jupyter trust "${file}"
    done
}

# new notebooks from templates are saved here
MOUNT=/epi2melabs/
NOTEBOOKDIR=${MOUNT}/notebooks/
mkdir -p ${NOTEBOOKDIR}
trust_path ${NOTEBOOKDIR}

# templates
trust_path /epi2me-resources/tutorials
