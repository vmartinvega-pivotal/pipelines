#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repo
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "-- Deploying streams ..."

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

# Resolve ranges for the dependencies
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Delete the files for the python app not to failed
if [ -f dependencies.list ]; then
    rm dependencies.list
fi

if [ -f app-descriptor.df ]; then
    rm app-descriptor.df
fi

if [ -f app-versions.properties ]; then
    rm app-versions.properties
fi

# Generate the app-descriptor for the microservice from the template
python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor.df app-versions.properties

# Creates the app-register file
echo "app import --uri file:${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df" >> ${TMPDIR}/app-register.df

# Register all microservices
scdf_shell ${PASSED_SCDF_SERVER_URL} "${TMPDIR}/app-register.df"

#cd "${ROOT_FOLDER_SCDF_SCRIPTS}" || exit

# Run all scripts in order
#for file in `ls *.sh | sort -V`; do 

#  echo "Sourcing file: ${file}"

#  source ${file}

#done

# Creating the streams
#echo "DEBUG: Creating the streams in the scdf server ${PASSED_SCDF_SERVER_URL}"
#scdf_shell ${PASSED_SCDF_SERVER_URL} "${ROOT_FOLDER_SCDF_SCRIPTS}/create.df"

# Deploying the streams
#echo "DEBUG: Deploying the streams in the scdf server ${PASSED_SCDF_SERVER_URL}"
#scdf_shell ${PASSED_SCDF_SERVER_URL} "${ROOT_FOLDER_SCDF_SCRIPTS}/deploy.df"

#echo "-- Deploying streams ..."

# Adding values to keyvalout
passKeyValProperties

echo "Done!!"
