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

  deleteDeployPipe "dev1-collevo" ${APP_NAME}
  deleteDeployPipe "dev2-collevo" ${APP_NAME}
  deleteDeployPipe "dev3-collevo" ${APP_NAME}
  deleteDeployPipe "dev4-collevo" ${APP_NAME}
  deleteDeployPipe "dev1-collcon" ${APP_NAME}
  deleteDeployPipe "dev2-collcon" ${APP_NAME}
  deleteDeployPipe "dev3-collcon" ${APP_NAME}
  deleteDeployPipe "dev4-collcon" ${APP_NAME}

  deletePipe release-collevo-${APP_NAME}
  deletePipe release-collcon-${APP_NAME}
done < "logical-apps"
