CONCOURSE_URL=http://10.56.253.197:8080
CONCOURSE_TEAM=main
CONCOURSE_USERNAME=admin
CONCOURSE_PASSWORD=e8apq0ezgu5g6ck0kogc
PIPELINE_YML=../../pipeline-physical-microservice/pipeline-build.yml

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  APP_BRANCH=$(echo ${app} | awk -F"@" '{print $2}')  

  sed "s/app-url: #APPS-URL#/app-url: https:\/\/gitlab-sdp.telecomitalia.local\/factory-apps\/${APP_NAME}.git/" physical-params-template-build-pipe.yml > params-build-1-${APP_NAME}.yml
  sed "s/app-branch: #APPS_BRANCH#/app-branch: ${APP_BRANCH}/" params-build-1-${APP_NAME}.yml > params-build-${APP_NAME}.yml
  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync
  fly -t automate sp -p release-${APP_NAME} -c "${PIPELINE_YML}" -l params-build-${APP_NAME}.yml -n
  rm params-build-${APP_NAME}.yml
  rm params-build-1-${APP_NAME}.yml
done < "physical-apps"
