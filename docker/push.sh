export DOCKER_ID_USER="vmartinvega"
docker login
docker tag concourse-tools-tim ${DOCKER_ID_USER}/concourse-tools-tim:latest
docker push ${DOCKER_ID_USER}/concourse-tools-tim
