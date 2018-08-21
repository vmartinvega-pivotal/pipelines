./set_pipeline-tim.sh snapshot-dispositiva-processor pipeline-physical-microservice/params-snapshoot-dispositiva-processor.yml pipeline-physical-microservice/pipeline-snapshoot.yml
./set_pipeline-tim.sh release-dispositiva-processor  pipeline-physical-microservice/params-build-dispositiva-processor.yml pipeline-physical-microservice/pipeline-build.yml
./set_pipeline-tim.sh release-consistenze-id20-coll-con pipeline-logical-microservice/params-coll-consolidato-id20.yml pipeline-logical-microservice/pipeline-coll-consolidato.yml
./set_pipeline-tim.sh release-consistenze-id20-coll-evo pipeline-logical-microservice/params-coll-evolutivo-id20.yml pipeline-logical-microservice/pipeline-coll-evolutivo.yml
./set_pipeline-tim.sh deploy-dev-id22 pipeline-logical-microservice/params-deploy-id22.yml pipeline-logical-microservice/pipeline-deploy.yml
