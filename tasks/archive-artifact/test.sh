REGEXP="\d+\.\d+\.\d+"
POM_FILE="/home/vicente/development/unzip-sink/pom.xml"
BRANCH_NAME="2.0"

VERSION=$(python parse-pom.py $POM_FILE "version")
checkversion=$(python check-version.py $REGEXP $VERSION $BRANCH_NAME)

echo $checkversion


