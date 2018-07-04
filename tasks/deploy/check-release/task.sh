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

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Logical Test ---"

chmod 777 ${TRUST_STORE_FILE}

git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
git config --global http.sslVerify false
git config --global user.name "${GIT_NAME}"
git config --global user.email "${GIT_EMAIL}"

# For insecure connections
# echo insecure >> ~/.curlrc

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

# Resolve ranges for the dependencies
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Generate the app-descriptor for the microservice from the template
python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py ./dependencies.list ./app-descriptor-template.df app-descriptor.df app-versions.properties

# TODO: if contains #VERSION abort!! Not all dependencies were resolved!!
TAG_VERSION=$(cat app-descriptor.df | grep '#VERSION' | wc -l)

if [ "$TAG_VERSION" -ne "0" ]
then
  echo "Some physical microservices where not resolved!! Existing ..."
  exit 1
fi


# If does not exist app-descriptor.df put it in place and push
#if [ ! -f ${ROOT_FOLDER}/${REPO_RESOURCE}/app-descriptor.df ]; then
#  echo "DEBUG: app-descriptor did not exist in the repo, adding it ..."

#  cp ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}
  
#  cd "${ROOT_FOLDER}/${REPO_RESOURCE}"

#  git add --all
  
#  git commit -a -m "[ci skip] Adding app-descriptor.df"
#else
  # Check if there are differencies
#  echo "DEBUG: Checking it there are new versions for the microservices ..."
  
#  MD51=$(md5sum app-descriptor.df | awk '{ print $1 }')
#  MD52=$(md5sum ${ROOT_FOLDER}/${REPO_RESOURCE}/app-descriptor.df | awk '{ print $1 }')
#  echo "DEBUG: MD51 (new app-descriptor): ${MD51}"
#  echo "DEBUG: MD52 (old app-descriptor): ${MD52}"

#  if [ "'${MD51}'" == "'${MD52}'" ]; then
#    echo "DEBUG: There are not new versions for physical microservices, skipping..."
#  else
#    echo "DEBUG: There are new versions for the physical microservices, modifiying the app-descriptor.df"

#    mv ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}
  
#    cd "${ROOT_FOLDER}/${REPO_RESOURCE}"

#    git add --all

#    git commit -a -m "[ci skip] Replacing app-descriptor.df because there are new version for microservices"
#  fi
#fi

rm -Rf cd ${TMPDIR}/${REPO_RESOURCE}

echo "--- Logical Test ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
