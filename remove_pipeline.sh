#!/bin/bash

PIPELINE_NAME="$1"
ALIAS="local"

fly -t "${ALIAS}" destroy-pipeline -p "${PIPELINE_NAME}" -n
