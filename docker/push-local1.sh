#export DOCKER_ID_USER="vmartinvega"
#docker login
docker tag cf-tools-tim nexus-sdp.telecomitalia.local:18443/concourse-tools-tim:latest
#docker tag cf-tools-tim 10.56.252.199/concourse-tools-tim:latest
docker push nexus-sdp.telecomitalia.local:18443/concourse-tools-tim
