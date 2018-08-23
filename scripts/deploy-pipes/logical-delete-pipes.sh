#!/bin/bash

source ./concourse-logical-params.sh

function deleteDeployPipe(){
  DEV=$1
  APP_NAME=$2

  PIPELINE_NAME=${DEV}-deploy-${APP_NAME}

  deletePipe ${PIPELINE_NAME}
}

function deletePipe(){
  PIPELINE_NAME=$1

  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync

  fly -t automate destroy-pipeline -p ${PIPELINE_NAME} -n
}

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')

  deleteDeployPipe "dev1" ${APP_NAME}
  deleteDeployPipe "dev2" ${APP_NAME}
  deleteDeployPipe "dev3" ${APP_NAME}
  deleteDeployPipe "dev4" ${APP_NAME}

  deletePipe release-${APP_NAME}
done < "logical-apps"
