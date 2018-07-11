#!/bin/bash

set -e +x

set -o errexit
set -o errtrace
set -o pipefail

export ROOT_FOLDER
ROOT_FOLDER="$( pwd )"
export REPO_RESOURCE=repoput
export TOOLS_RESOURCE=tools
export OUTPUT_RESOURCE=out
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Pvcs Upload ---"

chmod 777 ${TRUST_STORE_FILE}

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

# Resolve ranges for the dependencies
echo "Resolving version ranges"
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
echo "Creationg dependency list file"
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor.df app-version-collaudo-evolutivo-template.sh app-version-collaudo-evolutivo.sh app-version-prod-template.sh app-version-prod.sh maven-binaries-file

cat maven-binaries-file

# Get all binaries from file to be uploaded to PVCS
# PVCS Integration, checkout
echo "checkout pvcs url: ${PVCS_URL}"
PVCS_PATH=${TMPDIR}/pvcs/vicente_test
mkdir -p ${PVCS_PATH} 
cd ${PVCS_PATH}
#svn checkout --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD} ${PVCS_URL}
#cd ${PVCS_CHECKOUTDIR}

mkdir ${PVCS_PATH}/binaries

while IFS= read -r artifact
do
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:get -Dartifact=${artifact} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -Ddest=${PVCS_PATH}/binaries -Dtransitive=false
done < "maven-binaries-file"

ls ${PVCS_PATH}/binaries

rm -Rf ${TMPDIR}/${REPO_RESOURCE}

echo "--- Pvcs Upload ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
