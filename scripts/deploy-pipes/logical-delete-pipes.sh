#!/bin/bash

source ./concourse-logical-params.sh

function deleteDeployPipe(){
  DEV=$1
  INPUT_APP_NAME=$2
  INPUT_PREFIX=$3
  INPUT_BRANCH_NAME=$4

  PIPELINE_NAME=${DEV}-${INPUT_PREFIX}-${INPUT_APP_NAME}-${INPUT_BRANCH_NAME}

  deletePipe ${PIPELINE_NAME}
}

function deletePipe(){
  PIPELINE_NAME=$1

  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync

  fly -t automate destroy-pipeline -p ${PIPELINE_NAME} -n
}

programname=$0

function usage {
    # Format for the file
    # <app-name>@branch-con@branch-evo
    #
    echo "usage: $programname [apps file]"
    exit 1
}

if [ "$#" -lt 1 ]; then
  usage
fi

INPUT_FILE=$1

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  APP_BRANCH_CON=$(echo ${app} | awk -F"@" '{print $2}')
  APP_BRANCH_EVO=$(echo ${app} | awk -F"@" '{print $3}')

  deleteDeployPipe "dev1" ${APP_NAME} "con" ${APP_BRANCH_CON}
  deleteDeployPipe "dev2" ${APP_NAME} "con" ${APP_BRANCH_CON}
  deleteDeployPipe "dev3" ${APP_NAME} "con" ${APP_BRANCH_CON}
  deleteDeployPipe "dev4" ${APP_NAME} "con" ${APP_BRANCH_CON}
  deleteDeployPipe "dev1" ${APP_NAME} "evo" ${APP_BRANCH_EVO}
  deleteDeployPipe "dev2" ${APP_NAME} "evo" ${APP_BRANCH_EVO}
  deleteDeployPipe "dev3" ${APP_NAME} "evo" ${APP_BRANCH_EVO}
  deleteDeployPipe "dev4" ${APP_NAME} "evo" ${APP_BRANCH_EVO}

  deletePipe release-evo-${APP_NAME}-${APP_BRANCH_EVO} 
  deletePipe release-con-${APP_NAME}-${APP_BRANCH_CON} 
  deletePipe systemtest-con-${APP_NAME}-${APP_BRANCH_CON} 
  deletePipe systemtest-evo-${APP_NAME}-${APP_BRANCH_EVO} 
done < "${INPUT_FILE}"
