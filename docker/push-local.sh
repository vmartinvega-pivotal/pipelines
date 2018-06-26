#export DOCKER_ID_USER="vmartinvega"
#docker login
docker tag cf-tools-tim 10.56.252.199/concourse-tools-tim:latest
docker push 10.56.252.199/concourse-tools-tim
