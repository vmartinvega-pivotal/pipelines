#./set_pipeline-tim.sh  snapshot-dispositiva-processor credentials-snapshoot-dispositiva-processor-tim.yml pipeline-snapshoot.yml
./set_pipeline-tim.sh release-dispositiva-processor  credentials-release-dispositiva-processor-tim.yml pipeline-build.yml
./set_pipeline-tim.sh release-consistenze-id20-coll-evo pipeline-logical-microservice/params.yml pipeline-logical-microservice/pipeline.yml
