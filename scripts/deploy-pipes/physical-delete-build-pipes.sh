CONCOURSE_URL=http://10.56.253.197:8080
CONCOURSE_TEAM=main
CONCOURSE_USERNAME=admin
CONCOURSE_PASSWORD=e8apq0ezgu5g6ck0kogc

while IFS= read -r app
do
  APP_NAME=$(echo ${app} | awk -F"@" '{print $1}')
  fly -t automate login -c $CONCOURSE_URL -n $CONCOURSE_TEAM -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
  fly -t automate sync
  fly -t automate destroy-pipeline -p release-${APP_NAME} -n
done < "physical-apps"
