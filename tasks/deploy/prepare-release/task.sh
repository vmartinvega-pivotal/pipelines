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

echo "--- Prepare Release ---"

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
if [ -f app-descriptor.df ]; then
  rm app-descriptor.df
fi

if [ -f app-version-collaudo-evolutivo.sh ]; then
  rm app-version-collaudo-evolutivo.sh
fi

if [ -f app-version-prod.sh ]; then
  rm app-version-prod.sh
fi

# Compiles the templates
python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor.df app-version-collaudo-evolutivo-template.sh app-version-collaudo-evolutivo.sh app-version-prod-template.sh app-version-prod.sh

TAG_VERSION_APP_DESCRIPTOR=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-descriptor.df)
if [[ $TAG_VERSION_APP_DESCRIPTOR = "true" ]]
then
  echo "Some physical microservices where not resolved in app-descriptor.df !! Existing ..."
  exit 1
fi

TAG_VERSION_COLLAUDO=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-version-collaudo-evolutivo.sh)
if [[ $TAG_VERSION_COLLAUDO = "true" ]]
then
  echo "Some physical microservices where not resolved in app-version-collaudo-evolutivo.sh !! Existing ..."
  exit 1
fi

TAG_VERSION_PROD=$(python "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/python/check_file_version.py app-version-prod.sh)
if [[ $TAG_VERSION_PROD = "true" ]]
then
  echo "Some physical microservices where not resolved in app-version-prod.sh !! Existing ..."
  exit 1
fi

cd "${ROOT_FOLDER}/${REPO_RESOURCE}"

if [ -f app-descriptor.df ]; then
  rm app-descriptor.df
fi
echo "DEBUG: Adding the compiled app-descriptor.df "
mv ${TMPDIR}/${REPO_RESOURCE}/app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}

if [ -f app-version-collaudo-evolutivo.sh ]; then
  rm app-version-collaudo-evolutivo.sh
fi  
echo "DEBUG: Addig the compiled app-version-collaudo-evolutivo.sh"
mv ${TMPDIR}/${REPO_RESOURCE}/app-version-collaudo-evolutivo.sh ${ROOT_FOLDER}/${REPO_RESOURCE}

if [ -f app-version-prod.sh ]; then
  rm app-version-prod.sh
fi
echo "DEBUG: Addig the compiled app-version-prod.sh"
mv ${TMPDIR}/${REPO_RESOURCE}/app-version-prod.sh ${ROOT_FOLDER}/${REPO_RESOURCE}

git add --all
  
git commit -m "[ci skip] Adding all compiled files for the version"

rm -Rf cd ${TMPDIR}/${REPO_RESOURCE}

echo "--- Prepare Release ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
