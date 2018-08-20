CONCOURSE_URL=http://10.56.253.197:8080
CONCOURSE_TEAM=main
CONCOURSE_USERNAME=admin
CONCOURSE_PASSWORD=e8apq0ezgu5g6ck0kogc
PIPELINE_YML=/home/vicente/development/pipelines/pipeline-physical-microservice/pipeline-build.yml

while IFS= read -r app
do
  if [ -f params-build-${app}.yml ]; then
    rm params-build-${app}.yml
  fi
  sed "s/app-url: #APPS-URL#/app-url: https://gitlab-sdp.telecomitalia.local/factory-apps/${app}.git/" params-build-template.yml > params-build-${app}.yml
  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync
  fly -t automate sp -p release-${app} -c "${PIPELINE_YML}" -l params-build-${app}.yml -n
  rm params-build-${app}.yml
done < "apps"
