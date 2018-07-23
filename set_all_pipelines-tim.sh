./set_pipeline-tim.sh snapshot-dispositiva-processor pipeline-physical-microservice/params-snapshoot.yml pipeline-snapshoot.yml
./set_pipeline-tim.sh release-dispositiva-processor  pipeline-physical-microservice/params-build.yml pipeline-build.yml
./set_pipeline-tim.sh release-consistenze-id20-coll-con pipeline-logical-microservice/params.yml pipeline-logical-microservice/pipeline.yml
