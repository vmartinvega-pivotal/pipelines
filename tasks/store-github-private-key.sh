#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

GITPRIVATEKEY_HOME="${HOME}/.gitprivatekey"

echo "Writing git private key to [${GITPRIVATEKEY_HOME}/privatekey]"

[ -d "$GITPRIVATEKEY_HOME" ] || mkdir "$GITPRIVATEKEY_HOME"

echo "${GITHUB_PRIVATE_KEY}" >> "${GITPRIVATEKEY_HOME}/privatekey"

echo "Written private key"

# Usefull information for git access with private key
#https://stackoverflow.com/questions/11621768/how-can-i-make-git-accept-a-self-signed-certificate

#git -c http.sslVerify=false -c http.sslKey=${HOME}/.gitprivatekey/privatekey clone https://example.com/path/to/git
