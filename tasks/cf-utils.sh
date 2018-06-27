#!/bin/bash
# shellcheck disable=SC2086,SC1007,SC2163,SC2046

set -o errexit
set -o errtrace
set -o pipefail

export TMPDIR=${TMPDIR:-/tmp}

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
	      echo "Adding: ${var}"
	      export "$var"
	    fi
	  done < "${props}"
	fi
}

# This function logins against PCF
function cfLogin(){
  PWS_API=$1
  PWS_USER=$2
  PWS_PWD=$3
  PWS_ORG=$4
  PWS_SPACE=$5

  cf login -a "${PWS_API}" --skip-ssl-validation -u "${PWS_USER}" -p "${PWS_PWD}" -o "${PWS_ORG}" -s "${PWS_SPACE}"
}

# This function export a variable PASSED_APPS_URL with the URL to access all applications for an organization and space inside PCF
function getPCFUrls(){
  ORGANIZATION_NAME=$1
  SPACE_NAME=$2

  ORGANIZATIONS=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${ORGANIZATION_NAME}'" ) | .entity.spaces_url' | wc -l)

  if [[ $ORGANIZATIONS -gt "1" ]]
  then
    echo "ERROR: Found more than 1 organizations with name ${ORGANIZATION_NAME}!!!!"
    exit 1
  fi

  SPACES_URL=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${ORGANIZATION_NAME}'" ) | .entity.spaces_url' | sed -e 's/^"//' -e 's/"$//')

  echo "DEBUG: Spaces Url: ${SPACES_URL} for organization ${ORGANIZATION_NAME}"

  SPACES=$(cf curl ${SPACES_URL} | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${SPACE_NAME}'" ) | .entity.apps_url' | wc -l)

  if [[ $SPACES -gt "1" ]]
  then
    echo "ERROR: Found more than 1 space with name ${SPACE_NAME} in the organization ${ORGANIZATION_NAME}!!!!"
    exit 1
  fi

  APPS_URL=$(cf curl ${SPACES_URL} | jq '.resources[] | select(.entity.name == "'${SPACE_NAME}'") | .entity.apps_url' | sed -e 's/^"//' -e 's/"$//')

  echo "DEBUG: Apps Url: ${APPS_URL}"

  SERVICE_INSTANCES_URL=$(cf curl ${SPACES_URL} | jq '.resources[] | select(.entity.name == "'${SPACE_NAME}'") | .entity.service_instances_url' | sed -e 's/^"//' -e 's/"$//')

  echo "DEBUG: Service Instances Url: ${SERVICE_INSTANCES_URL}"

  export PASSED_PCF_APPS_URL=${APPS_URL}

  export PASSED_PCF_SPACES_URL=${SPACES_URL}

  export PASSED_PCF_SERVICES_INSTANCES_URL=${SERVICE_INSTANCES_URL}
}


# This function assumes the cfLogin was called previously
# Arguments:
# 1 - service-name
# 2 - service-plan
# 3 - Environñemtn to deploy
# 4 - Logical Microservice tag version to deploy
#
function pcfSetupRabbitService(){
  SERVICE_NAME=$1
  SERVICE_PLAN=$2
  ENVIRONMENT_TO_DEPLOY=$3
  LOGICAL_MICROSERVICE_TAG_VERSION=$4
  ARTIFACT_ID_DEPLOYING=$5

  RANDOM_SERVICE_NAME="RABBIT-"${ENVIRONMENT_TO_DEPLOY}"-"${ARTIFACT_ID_DEPLOYING}"-"${LOGICAL_MICROSERVICE_TAG_VERSION}

  # Creates a rabbitMQ service
  cf create-service ${SERVICE_NAME} ${SERVICE_PLAN} ${RANDOM_SERVICE_NAME}

  # waits for it to be created
  while true; do
    SERVICE_STATE=$(getServiceState $PASSED_PCF_SERVICES_INSTANCES_URL $RANDOM_SERVICE_NAME)

    if [[ $SERVICE_STATE = "succeeded" ]]
    then
      break;
    else
      echo "DEBUG: Waiting for the service ${RANDOM_SERVICE_NAME} to be craeted"
      sleep 5
    fi
  done

  # Creates the service-key for the service
  RANDOM_SERVICE_KEY_NAME="SERVICE-KEY-${RANDOM_SERVICE_NAME}"

  cf create-service-key ${RANDOM_SERVICE_NAME} ${RANDOM_SERVICE_KEY_NAME}

  export PASSED_RABBIT_HOST=$(getRabbitMqHost ${RANDOM_SERVICE_NAME} ${RANDOM_SERVICE_KEY_NAME})
  echo "DEBUG: PASSED_RABBIT_HOST: ${PASSED_RABBIT_HOST}"

  export PASSED_RABBIT_PORT=$(getRabbitMqPort ${RANDOM_SERVICE_NAME} ${RANDOM_SERVICE_KEY_NAME})
  echo "DEBUG: PASSED_RABBIT_PORT: ${PASSED_RABBIT_PORT}"

  export PASSED_RABBIT_VHOST=$(getRabbitMqVhost ${RANDOM_SERVICE_NAME} ${RANDOM_SERVICE_KEY_NAME})
  echo "DEBUG: PASSED_RABBIT_VHOST: ${PASSED_RABBIT_VHOST}"

  export PASSED_RABBIT_USERNAME=$(getRabbitMqUsername ${RANDOM_SERVICE_NAME} ${RANDOM_SERVICE_KEY_NAME})
  echo "DEBUG: PASSED_RABBIT_USERNAME: ${PASSED_RABBIT_USERNAME}"

  export PASSED_RABBIT_PASSWORD=$(getRabbitMqPassword ${RANDOM_SERVICE_NAME} ${RANDOM_SERVICE_KEY_NAME})
  echo "DEBUG: PASSED_RABBIT_PASSWORD: ${PASSED_RABBIT_PASSWORD}"

  export PASSED_RABBIT_SERVICE_KEY_NAME=${RANDOM_SERVICE_KEY_NAME}
  echo "DEBUG: PASSED_RABBIT_SERVICE_KEY_NAME: ${PASSED_RABBIT_SERVICE_KEY_NAME}"

  export PASSED_RABBIT_SERVICE_NAME=${RANDOM_SERVICE_NAME}
  echo "DEBUG: PASSED_RABBIT_SERVICE_NAME: ${PASSED_RABBIT_SERVICE_NAME}"
}

# This function destroys a service 
#
# 1 . Service name
#
function cfSCDFDestroy(){
  SERVICE_NAME=$1

  cf delete-service ${SERVICE_NAME} -f
}

# This function assumes the cfLogin was called previously
# Arguments:
# 1 - service-name
# 2 - service-plan
#
function cfSCDFDeploy(){
  
  SERVICE_NAME=$1
  SERVICE_PLAN=$2
  ENVIRONMENT_TO_DEPLOY=$3
  LOGICAL_MICROSERVICE_TAG_VERSION=$4
  ARTIFACT_ID_DEPLOYING=$5
    
  #RANDOM_VALUE=$(python random.py)
  RANDOM_SERVICE_NAME="SCDF-"${ENVIRONMENT_TO_DEPLOY}"-"${ARTIFACT_ID_DEPLOYING}"-"${LOGICAL_MICROSERVICE_TAG_VERSION}

  # Creates the service instance
  cf create-service ${SERVICE_NAME} ${SERVICE_PLAN} ${RANDOM_SERVICE_NAME}

  # waits for it to be created
  while true; do
    SERVICE_STATE=$(getServiceState $PASSED_PCF_SERVICES_INSTANCES_URL $RANDOM_SERVICE_NAME)

    if [[ $SERVICE_STATE = "succeeded" ]]
    then
      break;
    else
      echo "DEBUG: Waiting for the service ${RANDOM_SERVICE_NAME} to be craeted"
      sleep 5
    fi
  done

  export PASSED_SCDF_SERVER_NAME=${RANDOM_SERVICE_NAME}

  echo "DEBUG: Random service name created: ${RANDOM_SERVICE_NAME}"

  GUID=$(getServiceGuid $PASSED_PCF_SERVICES_INSTANCES_URL $RANDOM_SERVICE_NAME)

  echo "DEBUG: SCDF server GUID: ${GUID}"

  export PASSED_SCDF_SERVER_GUID=${GUID}

  DASHBOARD=$(getSCDFServiceDashboard $PASSED_PCF_SERVICES_INSTANCES_URL $RANDOM_SERVICE_NAME)

  SERVER_URL=$(echo ${DASHBOARD%/*})
  echo "DEBUG: SCDF server Url: ${SERVER_URL}"

  export PASSED_SCDF_SERVER_URL=${SERVER_URL}
}

function getRabbitMqPort(){
  SERVICE_INSTANCE=$1
  SERVICE_INSTANCE_KEY=$2

  RESULT=$(cf service-key ${SERVICE_INSTANCE} ${SERVICE_INSTANCE_KEY} | tail -n +2 | jq '.protocols[].port')

  echo ${RESULT}  
}

function getRabbitMqPassword(){
  SERVICE_INSTANCE=$1
  SERVICE_INSTANCE_KEY=$2

  RESULT=$(cf service-key ${SERVICE_INSTANCE} ${SERVICE_INSTANCE_KEY} | tail -n +2 | jq '.protocols[].password' | sed -e 's/^"//' -e 's/"$//')

  echo ${RESULT}  
}

function getRabbitMqUsername(){
  SERVICE_INSTANCE=$1
  SERVICE_INSTANCE_KEY=$2

  RESULT=$(cf service-key ${SERVICE_INSTANCE} ${SERVICE_INSTANCE_KEY} | tail -n +2 | jq '.protocols[].username' | sed -e 's/^"//' -e 's/"$//')

  echo ${RESULT}  
}

function getRabbitMqVhost(){
  SERVICE_INSTANCE=$1
  SERVICE_INSTANCE_KEY=$2

  RESULT=$(cf service-key ${SERVICE_INSTANCE} ${SERVICE_INSTANCE_KEY} | tail -n +2 | jq '.protocols[].vhost' | sed -e 's/^"//' -e 's/"$//')

  echo ${RESULT}  
}

function getRabbitMqHost(){
  SERVICE_INSTANCE=$1
  SERVICE_INSTANCE_KEY=$2

  RESULT=$(cf service-key ${SERVICE_INSTANCE} ${SERVICE_INSTANCE_KEY} | tail -n +2 | jq '.protocols[].host' | sed -e 's/^"//' -e 's/"$//')

  echo ${RESULT}  
}

# This function gets the state creation for a service
#
# 1 . Services URL (Extracted from getPCFUrls function) and stored in the environment variable PASSED_PCF_SERVICES_INSTANCES_URL
# 2 . Service name
#
function getServiceState(){
  SERVICES_URL=$1
  SERVICE_NAME=$2

  RESULT=$(cf curl ${SERVICES_URL} | jq '.resources[] | select(.entity.name == "'${SERVICE_NAME}'") | .entity.last_operation.state' | sed -e 's/^"//' -e 's/"$//')
 
  echo $RESULT
}

function pcfNFSDestroy(){
  SERVICE_NAME=$1

  cf delete-service ${SERVICE_NAME} -f
}

function pcfSetupNfsService(){

  SERVICE_NAME=$1
  SERVICE_PLAN=$2
  ENVIRONMENT_TO_DEPLOY=$3
  LOGICAL_MICROSERVICE_TAG_VERSION=$4
  ARTIFACT_ID_DEPLOYING=$5
  NFS_SHARE=$6
  NFS_USERNAME=$7
  NFS_PASSWORD=$8

  #RANDOM_VALUE=$(python random.py)
  RANDOM_SERVICE_NAME="NFS-"${ENVIRONMENT_TO_DEPLOY}"-"${ARTIFACT_ID_DEPLOYING}"-"${LOGICAL_MICROSERVICE_TAG_VERSION}

  cf create-service ${SERVICE_NAME} ${SERVICE_PLAN} ${RANDOM_SERVICE_NAME} -c '{ "share":"'${NFS_SHARE}'", "username": "'${NFS_USERNAME}'", "password": "'${NFS_PASSWORD}'" }' 

  export PASSED_NFS_INSTANCE_NAME=${RANDOM_SERVICE_NAME}
}

# This function gets the guid for a service
#
# 1 . Services URL (Extracted from getPCFUrls function) and stored in the environment variable PASSED_PCF_SERVICES_INSTANCES_URL
# 2 . Service name
#
function getServiceGuid(){
  SERVICES_URL=$1
  SERVICE_NAME=$2

  RESULT=$(cf curl ${SERVICES_URL} | jq '.resources[] | select(.entity.name == "'${SERVICE_NAME}'") | .metadata.guid' | sed -e 's/^"//' -e 's/"$//')
 
  echo ${RESULT}
}

# This function gets the dashboard URL for a service
#
# 1 . Services URL (Extracted from getPCFUrls function) and stored in the environment variable PASSED_PCF_SERVICES_INSTANCES_URL
# 2 . Service name
#
function getSCDFServiceDashboard(){
  SERVICES_URL=$1
  SERVICE_NAME=$2

  RESULT=$(cf curl ${SERVICES_URL} | jq '.resources[] | select(.entity.name == "'${SERVICE_NAME}'") | .entity.dashboard_url' | sed -e 's/^"//' -e 's/"$//')
 
  echo ${RESULT}
}

function pcfDeleteRabbitService(){
  SERVICE_NAME=$1
  SERVICE_KEY_NAME=$2

  # Deletes de service key created
  cf delete-service-key ${SERVICE_NAME} ${SERVICE_KEY_NAME} -f

  # Deletes de service instance
  cf delete-service ${SERVICE_NAME} -f
}

scdf_shell() {
  echo "Running SCDF shell command: $(cat $2)"
  java \
  -jar ${ROOT_FOLDER}/${TOOLS_RESOURCE}/scdf/spring-cloud-dataflow-shell-1.5.1.RELEASE.jar \
  --dataflow.uri=$1 \
  --dataflow.credentials-provider-command="cf oauth-token" \
  --dataflow.skip-ssl-validation=true \
  --dataflow.mode=skipper \
  --spring.shell.commandFile=$2
}

# This function change the environment for the skipper and dataflow app 
#
function scdfChangeEnvironment(){

  SCDF_ORG=$1
  SCDF_SPACE=$2

  ORG_NAME=$3
  ORG_SPACE=$4

  USERNAME=$5
  PASSWORD=$6
  REPO_URL=$7

  cf target -o ${SCDF_ORG} -s ${SCDF_SPACE}

  # dataflow
  cf set-env dataflow SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_STREAM_BUILDPACK java_buildpack_offline
  cf set-env dataflow SPRING_CLOUD_DEPLOYER_CLOUDFOUNDRY_TASK_BUILDPACK java_buildpack_offline
  cf set-env dataflow SPRING_APPLICATION_JSON '{
	"spring.cloud.dataflow.applicationProperties.stream.spring.cloud.stream.bindings.applicationMetrics.destination":"metrics",
	"spring.cloud.dataflow.version-info.dependency-fetch.enabled": "false",
	"maven.remote-repositories.telecom.url": "'${REPO_URL}'",
	"maven.remote-repositories.telecom.auth.username": "'${USERNAME}'",
        "maven.remote-repositories.telecom.auth.password": "'${PASSWORD}'"
  }'

  # skipper
  cf set-env skipper SPRING_CLOUD_SKIPPER_SERVER_VERSION_INFO_DEPENDENCY_FETCH_ENABLED false
  cf set-env skipper SPRING_CLOUD_SKIPPER_SERVER_PLATFORM_CLOUDFOUNDRY_ACCOUNTS\[default\]_DEPLOYMENT_BUILDPACK java_buildpack_offline
  cf set-env skipper SPRING_APPLICATION_JSON '{
	"spring.cloud.dataflow.applicationProperties.stream.spring.cloud.stream.bindings.applicationMetrics.destination":"metrics",
	"spring.cloud.dataflow.version-info.dependency-fetch.enabled": "false",
	"maven.remote-repositories.telecom.url": "'${REPO_URL}'",
	"maven.remote-repositories.telecom.auth.username": "'${USERNAME}'",
        "maven.remote-repositories.telecom.auth.password": "'${PASSWORD}'"
  }'

  # restage
  cf restage dataflow && cf restage skipper

  # change space
  cf target -o ${ORG_NAME} -s ${ORG_SPACE}
}

#PWS_API="https://api.system.sdpcollaudo.telecomitalia.local"
#PWS_USER="admin"
#PWS_PWD="XWMhEBXV8Zn7LxT1HqiulUQ7aSYGq4b_"
#PWS_ORG="vicente-test"
#PWS_SPACE="development"
#NEXUS_USERNAME="sgramegna"
#NEXUS_PASSWORD="sgramegna"
#NEXUS_URL="https://nexus-sdp.telecomitalia.local/nexus/repository/maven-public"

#cfLogin $PWS_API $PWS_USER $PWS_PWD $PWS_ORG $PWS_SPACE
#getPCFUrls $PWS_ORG $PWS_SPACE
#cfSCDFDeploy "p-dataflow" "standard" "systemtest" "v1.0.2"
#scdfChangeEnvironment "p-dataflow" ${PASSED_SCDF_SERVER_GUID} $PWS_ORG $PWS_SPACE ${NEXUS_USERNAME} ${NEXUS_PASSWORD} ${NEXUS_URL}
#pcfSetupRabbitService "p.rabbitmq" "single-node-deprecated" "systemtest" "v1.0.2"
#pcfDeleteRabbitService ${PASSED_RABBIT_SERVICE_NAME} ${PASSED_RABBIT_SERVICE_KEY_NAME}
