#!/bin/bash

PIPELINE_NAME="pipeline-build.yml"
ALIAS="local"

fly -t "${ALIAS}" destroy-pipeline -p "${PIPELINE_NAME}" -n
