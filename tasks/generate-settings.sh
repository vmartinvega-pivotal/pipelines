#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

M2_HOME="${HOME}/.m2"
M2_CACHE="${ROOT_FOLDER}/maven"
GRADLE_HOME="${HOME}/.gradle"
GRADLE_CACHE="${ROOT_FOLDER}/gradle"

echo "M2_SETTINGS_REPO_MIRROR_URL(generate bash): $M2_SETTINGS_REPO_MIRROR_URL"

echo "Generating symbolic links for caches"

[[ -d "${M2_CACHE}" && ! -d "${M2_HOME}" ]] && ln -s "${M2_CACHE}" "${M2_HOME}"
[[ -d "${GRADLE_CACHE}" && ! -d "${GRADLE_HOME}" ]] && ln -s "${GRADLE_CACHE}" "${GRADLE_HOME}"

echo "Writing maven settings to [${M2_HOME}/settings.xml]"

[ -d "$M2_HOME" ] || mkdir "$M2_HOME"

cat > "${M2_HOME}/settings.xml" <<EOF

<?xml version="1.0" encoding="UTF-8"?>
<settings>
    <pluginGroups>
      <pluginGroup>org.sonarsource.scanner.maven</pluginGroup>
    </pluginGroups>
    <mirrors>
      <mirror>
        <id>\${M2_SETTINGS_REPO_ID}</id>
        <mirrorOf>*</mirrorOf>
	    <url>\${M2_SETTINGS_REPO_MIRROR_URL}</url>
      </mirror>
    </mirrors>
    <servers>
      <server>
        <id>\${M2_SETTINGS_REPO_ID}</id>
        <username>\${M2_SETTINGS_REPO_USERNAME}</username>
        <password>\${M2_SETTINGS_REPO_PASSWORD}</password>
      </server>
    </servers>
    <profiles>
       <profile>
         <id>devops-sdp</id>
         <activation>
           <activeByDefault>true</activeByDefault>
         </activation>
         <properties>
           <mySiteUrl>\${M2_SETTINGS_REPO_SITE_URL}</mySiteUrl>
           <releasesRepositoryUrl>\${M2_SETTINGS_REPO_RELEASE_URL}</releasesRepositoryUrl>
           <snapshotsRepositoryUrl>\${M2_SETTINGS_REPO_SNAPSHOTS_URL}</snapshotsRepositoryUrl>
           <gitServerUrl>\${M2_SETTINGS_REPO_GIT_SERVER_URL}</gitServerUrl>
           <sonar.host.url>\${M2_SETTINGS_REPO_SONAR_URL}</sonar.host.url>
           <sonar.login>\${M2_SETTINGS_REPO_SONAR_TOKEN}</sonar.login>
         </properties>
       </profile>
    </profiles>
</settings>

EOF
echo "Settings xml written"
