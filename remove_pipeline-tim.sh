#!/bin/bash

PIPELINE_NAME="$1"
ALIAS="tim"

fly -t "${ALIAS}" destroy-pipeline -p "${PIPELINE_NAME}" -n
