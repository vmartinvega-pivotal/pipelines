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

export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}
chmod 777 ${TRUST_STORE_FILE}

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Pvcs Upload ---"

echo "DEBUG: checking out the verson "${PASSED_TAG_RELEASED_CREATED}
git checkout tags/${PASSED_TAG_RELEASED_CREATED}

# Get all binaries from file to be uploaded to PVCS
echo "checkout pvcs url: ${PVCS_URL}"
PVCS_PATH=${TMPDIR}/pvcs/vicente_test
mkdir -p ${PVCS_PATH} 
cd ${PVCS_PATH}

svn checkout --config-option servers:global:store-plaintext-passwords=no --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD} ${PVCS_URL}

FOLDER_TO_WORK_IN_PVCS=${PVCS_PATH}/${PVCS_CHECKOUTDIR}/vicente
if [ -d ${FOLDER_TO_WORK_IN_PVCS} ]; then
  rm -Rf ${FOLDER_TO_WORK_IN_PVCS}
fi
mkdir ${FOLDER_TO_WORK_IN_PVCS}
cd ${FOLDER_TO_WORK_IN_PVCS}

cp "${ROOT_FOLDER}/${REPO_RESOURCE}"/pom.xml ${FOLDER_TO_WORK_IN_PVCS} 

# Get all sources
# Get all physical microservices pom.xml files and jar files
mvn -f pom.xml dependency:copy-dependencies -DexcludeTransitive=true -Dmdep.copyPom=true -DoutputDirectory=target/poms -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

mkdir ${FOLDER_TO_WORK_IN_PVCS}/micros-sources
for FILE in `ls target/poms/*.pom` 
do
  ARTIFACTID=$(getArtifactId ${FILE})
  
  #mvn -f ${FILE}  -DcheckoutDirectory=target/micros-sources/${ARTIFACTID} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}
done
#cp -r target/micros-sources ${FOLDER_TO_WORK_IN_PVCS}/micros-sources

cp -r compiled/ ${FOLDER_TO_WORK_IN_PVCS}
mv ${FOLDER_TO_WORK_IN_PVCS}/compiled ${FOLDER_TO_WORK_IN_PVCS}/compiled-files
cp app-descriptor.df ${FOLDER_TO_WORK_IN_PVCS}/compiled-files
cp apps-version.env ${FOLDER_TO_WORK_IN_PVCS}/compiled-files

mkdir ${FOLDER_TO_WORK_IN_PVCS}/micros-binaries
cp target/poms/*.jar ${FOLDER_TO_WORK_IN_PVCS}/micros-binaries

svn add --force ${FOLDER_TO_WORK_IN_PVCS}

svn commit -m "Logical microservice version ${PASSED_TAG_RELEASED_CREATED}" --username=${PVCS_USERNAME} --password=${PVCS_PASSWORD}

echo "--- Pvcs Upload ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
