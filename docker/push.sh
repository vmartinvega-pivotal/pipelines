export DOCKER_ID_USER="vmartinvega"
docker login
docker tag cf-tools-tim ${DOCKER_ID_USER}/cf-tools-tim:latest
docker push ${DOCKER_ID_USER}/cf-tools-tim
