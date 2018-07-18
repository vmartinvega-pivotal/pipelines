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
export CONFIG_RESOURCE=config
export KEYVALOUTPUT_RESOURCE=keyvalout
export KEYVAL_RESOURCE=keyval

# Source all usefull scripts
source "${ROOT_FOLDER}/${TOOLS_RESOURCE}"/tasks/source-all.sh
export TRUST_STORE_FILE=${ROOT_FOLDER}/${TOOLS_RESOURCE}/truststore/${TRUSTSTORE}
chmod 777 ${TRUST_STORE_FILE}

# Add properties as environment variables
exportKeyValProperties

cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo "--- Test Logical ---"

# Copy all contents for the repo to a new location
cp -r ${ROOT_FOLDER}/${REPO_RESOURCE} ${TMPDIR}

# Change location
cd ${TMPDIR}/${REPO_RESOURCE}

# Resolve ranges for the dependencies
mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Get the dependencies for the logical microservice
mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

if [ -f apps-version.env ]; then
    rm apps-version.env
fi

if [ -f app-descriptor.df ]; then
    rm app-descriptor.df
fi

python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor-aux.df apps-version-template.env apps-version.env


chmod +x apps-version.env
exportKeyValPropertiesForDeploying apps-version.env

envsubst < app-descriptor-aux.df > app-descriptor-aux1.df
rm app-descriptor-aux.df

# Remove comillas 
sed -e 's|["'\'']||g' app-descriptor-aux1.df > app-descriptor.df
rm app-descriptor-aux1.df

echo ""
echo "--- APP-DESCRIPTOR.DF CREATED ---"
cat app-descriptor.df
echo "--- APP-DESCRIPTOR.DF CREATED ---"

#TODO: Check differencies for app-descriptor.df file
mv app-descriptor.df ${ROOT_FOLDER}/${REPO_RESOURCE}

echo ""
echo "--- APPS-VERSION.ENV CREATED ---"
cat apps-version.env
echo "--- APPS-VERSION.ENV CREATED ---"

#TODO: Check differencies for apps-version.env file
mv apps-version.env ${ROOT_FOLDER}/${REPO_RESOURCE}

rm -Rf ${TMPDIR}/${REPO_RESOURCE}
cd "${ROOT_FOLDER}/${REPO_RESOURCE}" || exit

echo ""
echo "--- CREATING COMPILED FILES FOR COLLAUDO EVOLUTIVO"
./microservice.sh ../config/collaudo-evolutivo.env microservice.env script

echo "--- Test Logical ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"