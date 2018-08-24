#!/bin/bash

source ./concourse-physical-params.sh

APP_NAME=$1
APP_BRANCH=$2

fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly -t automate sync

PIPELINE_SNAPSHOT_NAME=snapshot-${APP_NAME}-${APP_BRANCH}

fly -t automate destroy-pipeline -p ${PIPELINE_SNAPSHOT_NAME} -n
