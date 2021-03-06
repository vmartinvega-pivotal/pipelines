#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

function prepareScriptsToDeploy(){
  # Resolve ranges for the dependencies
  mvn versions:resolve-ranges -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}

  # Checks that all dependencies were resolved correctly
  
  checkDependencies="$(checkDependenciesListVersions pom.xml)"
  echo "checkDependenciesListVersions result=${checkDependencies}"

  if [[ $checkDependencies = "false" ]]
  then
    echo "ERROR: Not all dependencies for the logical microservice were resolved correctly!!!"
    exit 1
  fi

  # Get the dependencies for the logical microservice from the compiled pom.xml
  #mvn dependency:list -DexcludeTransitive=true -DoutputFile=dependencies.list -Djavax.net.ssl.trustStore=${TRUST_STORE_FILE}
  python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/list-dependencies-pom.py pom.xml dependencies.list 
 
  # Generate the app-descriptor for the microservice from the template
  if [ -f app-descriptor.df ]; then
    rm app-descriptor.df
  fi

  if [ -f apps-version.env ]; then
    rm apps-version.env
  fi

  if [ -d compiled ]; then
    rm -Rf compiled
  fi

  python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/file_process.py dependencies.list app-descriptor-template.df app-descriptor.df apps-version-template.env apps-version.env

  #chmod +x apps-version.env
  #exportKeyValPropertiesForDeploying apps-version.env

  #envsubst < app-descriptor-aux.df > app-descriptor-aux1.df
  #rm app-descriptor-aux.df

  # Remove comillas 
  #sed -e 's|["'\'']||g' app-descriptor-aux1.df > app-descriptor.df
  #rm app-descriptor-aux1.df

  echo "echo \"\\" >> microservice.env
  cat app-descriptor.df >> microservice.env
  echo "\" \\" >> microservice.env
  echo "> \${COMPILED_DIR}/app-descriptor.df" >> microservice.env
  
  # Source all environments and stores all compiled info 
  mkdir compiled_aux
  for ENV_FILE in `ls ../${CONFIG_RESOURCE}/*.env`
  do
    echo "DEBUG: creating compiled files for: ${ENV_FILE}"
    ./microservice.sh ../${CONFIG_RESOURCE}/${ENV_FILE} microservice.env script
    COMPILED_ENV_NAME_AUX=$(echo ${ENV_FILE} | awk -F"/" '{print $3}')
    COMPILED_ENV_NAME=$(echo ${COMPILED_ENV_NAME_AUX} | awk -F"." '{print $1}')
    mkdir compiled_aux/${COMPILED_ENV_NAME}
    mv compiled/* compiled_aux/${COMPILED_ENV_NAME}
    rm -Rf compiled
  done
  mv compiled_aux compiled
  
  echo "DEBUG: apps-version.env created..."
  cat apps-version.env
}

function checkDiferenciesForFilesAndCopyIfNeeded(){
  FILE_1=$1
  FILE_2=$2

  if [ -f ${FILE_2} ]; then
    MD51=$(md5sum ${FILE_1} | awk '{ print $1 }')
    MD52=$(md5sum ${FILE_2} | awk '{ print $1 }')
    
    if [ "'${MD51}'" == "'${MD52}'" ]; then
      echo "false"
    else
      cp ${FILE_1} ${FILE_2}
      echo "true"
    fi    
  else
    cp ${FILE_1} ${FILE_2}
    echo "true"    
  fi
}

# Reads a file.properties as the first argument and add it as a environment variable
function exportKeyValPropertiesForDeploying() {
	props=$1
	echo "Props are in [${props}]"
	if [ -f "${props}" ]
	then
	  echo "Reading passed key values"
	  while IFS= read -r var
	  do
	    if [ ! -z "${var}" ]
	    then
              if [[ "${var}" =~ ^#.* ]]; then
                echo "Skipping line ${var}"
              else
	        echo "Adding: ${var}"
	        export "$var"
              fi
	    fi
	  done < "${props}"
	fi
}

# Reads all key-value pairs in a file.properties input file and exports the ones that are needed for the environment system test, from the config file for that environment
function exportKeyValPropertiesForSystemTest() {
	props=$1
	echo "Props are in [${props}]"
	if [ -f "${props}" ]
	then
	  echo "Reading passed key values from file ${props}"
	  while IFS='=' read -r name value
	  do
            if [[ "${name}" == 'PASSED_RUN'* ]]; then
	      echo "Adding: ${name}=${value}"
	      export "$name=$value"
            fi
            if [[ "${name}" == 'PASSED_RABBIT_EXCHANGE' ]]; then
              echo "Adding: ${name}=${value}"
	      export "$name=$value"
            fi
            if [[ "${name}" == 'PASSED_RABBIT_ROUTING_KEY' ]]; then
              echo "Adding: ${name}=${value}"
	      export "$name=$value"
            fi
            if [[ "${name}" == 'PASSED_RABBIT_QUEUE' ]]; then
              echo "Adding: ${name}=${value}"
	      export "$name=$value"
            fi
	  done < "${props}"
	fi
}

function getUrlArtifact(){
  USERNAME=$1 # devops-sdp
  PASSWORD=$2 # zxcdsa011
  REPOSITORY=$3 # maven-releases
  GROUP=$4 # com.tim.sdp
  NAME=$5 # logical-microservice
  VERSION=$6 # 1.0.113

  echo insecure >> ~/.curlrc

  RESULT=$(curl -u ${USERNAME}:${PASSWORD} -X GET --header 'Accept: application/json' 'https://nexus-sdp.telecomitalia.local/nexus/service/siesta/rest/beta/search?repository='${REPOSITORY}'&group='${GROUP}'&name='${NAME}'&version='${VERSION}'' | jq '.items[].assets[].downloadUrl' | grep jar\" | sed -e 's/^"//' -e 's/"$//')

  echo ${RESULT}
}

#Params 
# 1 - output file name
function soapUItestrunnerWorkaround(){
  OUTPUT=$1 
  echo "nohup "${line}" &" >> ${OUTPUT}
  echo "PROC_ID=\$!" >> ${OUTPUT}
  echo "while kill -0 \"\$PROC_ID\" >/dev/null 2>&1; do" >> ${OUTPUT}
  echo "echo \"Tests running ...\"" >> ${OUTPUT}
  echo "sleep 5" >> ${OUTPUT}
  echo "done" >> ${OUTPUT}
  echo "echo \"Tests finished!!\"" >> ${OUTPUT}
}

# Converts a string to lower case
function toLowerCase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Gets the artifactid tag from a POM file
# Arguments:
# 1 - Pom file
#
# Result string: artifactid
#
function getArtifactId(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/parse-pom.py $1 "artifact")
}

function getGroupId(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/parse-pom.py $1 "group")
}

function increaseBranch(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/modify-branch.py $1 "increase")
}

function decreaseBranch(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/modify-branch.py $1 "decrease")
}

function randomName(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/random.py)
}

# Gets the version tag from a POM file
# Arguments:
# 1 - Pom file
#
# Result string: pom version
#
function getPomVersion(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/parse-pom.py $1 "version")
}

# Gets version from pom version based on a regular expression
# Arguments:
# 2 - Pom version
#
# Result string: version
#
function getVersionFromPomVersion(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/regex-match.py "\d+\.\d+\.\d+" $1 "find" 0)
}

# Checks that all dependencies versions for the logical microservice have been resolved, that is,
# all matches the regular expression "\d+\.\d+\.\d+"
#
# Arguments:
# 1 - Pom file
#
# Result true if all matches the regular expression, otherwise false
#
function checkDependenciesListVersions(){
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/check-dependencies-list-version.py $1)
}

# Checks if the branch name starts with the version extracted from the POM version
# Arguments:
# 1 - Branch name
# 2 - Pom file
#
# Result string: true / false
#
function checkVersion(){
  POM_VERSION="$(getPomVersion $2)"
  VERSION="$(getVersionFromPomVersion $POM_VERSION)"
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/check-version.py "\d+\.\d+\.\d+" ${VERSION} $1)
}

# Checks there is a tag on git for the current branch that ends with the version extracted from the POM version
# Arguments:
# 1 - Pom file
#
# Result string: true/false
#
function tagExists(){
  POM_VERSION="$(getPomVersion $1)"
  VERSION="$(getVersionFromPomVersion $POM_VERSION)"
  TAG=$(git tag | grep '${VERSION}' || echo 'OK')
  echo $(python ${ROOT_FOLDER}/${TOOLS_RESOURCE}/python/tag-exists.py ${TAG} ${VERSION})
}
