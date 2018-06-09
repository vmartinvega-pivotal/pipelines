REGEXP="\d+\.\d+\.\d+"
POM_FILE="/home/vicente/development/unzip-sink/pom.xml"
BRANCHNAME="2.0"

POM_VERSION=$(python parse-pom.py $POM_FILE "version")
echo "POM_VERSION=${POM_VERSION}"

checkversion=$(python check-version.py $REGEXP $POM_VERSION $BRANCHNAME)
echo "CheckVersion result=${checkversion}"

PATCH_LEVEL=$(expr `git tag|grep '${BRANCHNAME}.[0-9][0-9]*\$' | awk -F '.' '{ print $3 }' | sort -n | tail -n 1` + 1 || echo 0)
NEXT_RELEASE=${BRANCHNAME}.${PATCH_LEVEL}
echo "Calculated next release: ${NEXT_RELEASE}"

# tagExists function
VERSION=$(python regex-match.py $REGEXP $POM_VERSION "find" 0) 
echo "VERSION=${VERSION}"
TAG=$(git tag | grep '${VERSION}' || echo 'OK')
echo "Tag=${TAG}"
tagexists=$(python tag-exists.py ${TAG} ${VERSION})
echo "TagExists result=${tagexists}"

if [[ $checkversion = "true" ]]
then
    if [[ $tagexists = "true" ]]
    then
      echo "WARN: The software is already tagged with this release"
      NEW_POM_VERSION="${NEXT_RELEASE}-SNAPSHOT"
      NEW_POM_FILE="${POM_FILE}.new"
      $(python modify-version-pom.py ${POM_FILE} ${NEW_POM_FILE} ${NEW_POM_VERSION})
      echo "WARN: Patched pom version with value ${NEW_POM_VERSION}"
      #git commit -a -m "Changed pom version from ${POM_VERSION} to ${NEW_POM_VERSION}"
    fi
else
    echo "ERROR: Pom Version ${POM_VERSION} does not match release name ${BRANCHNAME}"
    exit 1
fi
