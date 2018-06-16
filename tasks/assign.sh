#!/bin/bash

programname=$0

function usage {
    echo "usage: $programname [org name] [space name] [app base name] [service name] [pws api] [username] [password]"
    echo "  org name        orgnaization name"
    echo "  space name      space name"
    echo "  app base name   application base name to find and bind the service name"
    echo "  service name    service name"
    echo "  pws api         pws api url"
    echo "  username        username to connect to pws api"
    echo "  password        password for the user"
    exit 1
}

if [ "$#" -ne 7 ]; then
  usage
fi

ORGANIZATION_NAME=$1
SPACE_NAME=$2
APP_NAME_BASE=$3
SERVICE_NAME=$4
USERNAME=$5
PASSWORD=$6
PWS_API=$7

echo "Logging to PWS ${PWS_API} with user ${USERNAME}, organization {ORGANIZATION_NAME} and space {SPACE_NAME}"
cf login -a ${PWS_API} --skip-ssl-validation -u ${USERNAME} -p ${PASSWORD} -o ${ORGANIZATION_NAME} -s ${SPACE_NAME}

ORGANIZATIONS=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "'${ORGANIZATION_NAME}'" ) | .entity.spaces_url' | wc -l)

echo "orga: ${ORGANIZATIONS}"

if [[ $ORGANIZATIONS -gt "1" ]]
then
  echo "ERROR: Found more than 1 organizations with name ${ORGANIZATION_NAME}!!!!"
  exit 1
fi

SPACES=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "collaudo" ) | .entity.spaces_url' | wc -l)

if [[ $SPACES -gt "1" ]]
then
  echo "ERROR: Found more than 1 space with name ${SPACE_NAME} in the organization ${ORGANIZATION_NAME}!!!!"
  exit 1
fi

SPACES_URL=$(cf curl /v2/organizations | jq '.resources[] | select(.entity.status == "active" ) | select(.entity.name == "collaudo" ) | .entity.spaces_url' | sed -e 's/^"//' -e 's/"$//')

echo "DEBUG: Spaces Url: ${SPACES_URL} for organization ${ORGANIZATION_NAME}"

APPS_URL=$(cf curl ${SPACES_URL} | jq '.resources[] | select(.entity.name == "'${SPACE_NAME}'") | .entity.apps_url' | sed -e 's/^"//' -e 's/"$//')

echo "DEBUG: Apps Url: ${APPS_URL}"

APPS=$(cf curl ${APPS_URL} | jq '.resources[].entity.name' | sed -e 's/^"//' -e 's/"$//' | grep "^${APP_NAME_BASE}" | wc -l)

if [[ $apps -gt "1" ]]
then
  echo "ERROR: Found more than 1 app with name base ${APP_NAME_BASE} in the space ${SPACE_NAME} for the organization ${ORGANIZATION_NAME}!!!!"
  exit 1
fi

APP_NAME=$(cf curl ${APPS_URL} | jq '.resources[].entity.name' | sed -e 's/^"//' -e 's/"$//' | grep "^${APP_NAME_BASE}")
echo "Found app ${APP_NAME} in the space ${SPACE_NAME} and organization ${ORGANIZATION_NAME}"

echo "Binding service ${SERVICE_NAME} to the application ${APP_NAME}"
#cf bind-service ${APP_NAME} ${SERVICE_NAME}

echo "Restaging app ${APP_NAME}"
#cf restage ${APP_NAME}


