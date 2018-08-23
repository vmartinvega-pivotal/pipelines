CONCOURSE_URL=http://10.56.253.197:8080
CONCOURSE_TEAM=main
CONCOURSE_USERNAME=admin
CONCOURSE_PASSWORD=e8apq0ezgu5g6ck0kogc

function deleteDeployPipe(){
  DEV=$1
  APP_NAME=$2

  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync

  PIPELINE_NAME=${DEV}-deploy-${APP_NAME}

  echo "Deleting pipeline ${PIPELINE_NAME}"

  fly -t automate destroy-pipeline -p ${PIPELINE_NAME} -n
}

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')

  deleteDeployPipe "dev1" ${APP_NAME}
  deleteDeployPipe "dev2" ${APP_NAME}
  deleteDeployPipe "dev3" ${APP_NAME}
  deleteDeployPipe "dev4" ${APP_NAME}

done < "logical-apps"
