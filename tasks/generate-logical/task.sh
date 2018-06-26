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

echo "--- Generate Logical ---"

POM_FILE="pom.xml"

# Resolve ranges for microservices dependencies
mvn -s settings.xml versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Generate the dependencies list
mvn -s settings.xml dependency:list -DexcludeTransitive=true -DoutputFile=dependenciesnew.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

# Check if the files are different
dependencieslist=`md5 dependencies.list`
dependenciesnewlist=`md5 dependenciesnew.list`

if [ "${dependencieslist}" = "${dependenciesnewlist}" ]
then
  echo "The dependencies have not changed!!"
else
  git config --global http.sslKey "${HOME}/.gitprivatekey/privatekey"
  git config --global http.sslVerify false
  git config --global user.name "${GIT_NAME}"
  git config --global user.email "${GIT_EMAIL}"

  mvn versions:revert -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}
  mv dependenciesnew.list dependencies.list 

  git commit -a -m "[ci skip] Dependencies have changed"
  
  git push ${CURRENT_BRANCH}

  chmod 777 ${TRUST_STORE_FILE}

  git checkout -f ${CURRENT_BRANCH}

  mvn --batch-mode release:clean release:prepare release:perform -Drelease.arguments="-Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}" -Dresume=false -Dusername=${USERNAME} -Dpassword=${PASSWORD} -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE} -DscmCommentPrefix="[ci skip]"

  mvn -s settings.xml dependency:copy-dependencies -Dclassifier=sources -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}
  mv target/dependencies target/sources

  mvn -s settings.xml dependency:copy-dependencies -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}
  mv target/dependencies target/binaries
fi

echo "--- Generate Logical ---"
echo ""

# Adding values to the next job
passKeyValProperties

cp -r "${ROOT_FOLDER}/${REPO_RESOURCE}"/. "${ROOT_FOLDER}/${OUTPUT_RESOURCE}/"

echo "Done!!"
