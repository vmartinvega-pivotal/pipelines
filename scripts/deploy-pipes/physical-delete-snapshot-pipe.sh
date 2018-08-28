#!/bin/bash

source ./concourse-physical-params.sh

programname=$0

function usage {
    echo "usage: $programname [physical app name] [develop branch]"
    exit 1
}

if [ "$#" -lt 1 ]; then
  usage
fi

APP_NAME=$1
APP_BRANCH=$2

fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly -t automate sync

PIPELINE_SNAPSHOT_NAME=snapshot-${APP_NAME}-${APP_BRANCH}

fly -t automate destroy-pipeline -p ${PIPELINE_SNAPSHOT_NAME} -n
