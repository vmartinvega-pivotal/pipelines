#./set_pipeline-tim.sh  snapshot-dispositiva-processor credentials-snapshoot-dispositiva-processor-tim.yml pipeline-snapshoot.yml
./set_pipeline-tim.sh release-dispositiva-processor  credentials-release-dispositiva-processor-tim.yml pipeline-build.yml
./set_pipeline-tim.sh release-logical-microservice credentials-deploy-tim.yml pipeline-deploy.yml  
./set_pipeline-tim.sh release-consistenze-id20 credentials-test-consistenze-id20.yml pipeline-deploy-collaudo.yml
./set_pipeline-tim.sh release-consistenze-id20-test credentials-test-consistenze-id20.yml pipeline-deploy-collaudo-test.yml
#./set_pipeline-tim.sh  build-release-sdp-demo-clienti credentials-build-tim.yml pipeline-build.yml
#./set_pipeline-tim.sh  build-snapshoot-sdp-demo-clienti credentials-snapshoot-tim.yml pipeline-snapshoot.yml
#./set_pipeline-tim.sh  build-snapshoot-logical credentials-logical-tim.yml pipeline-logical.yml
#./set_pipeline-tim.sh deploy-systemtest-logicalmicroservice credentials-deploy-tim.yml pipeline-deploy.yml
#./set_pipeline.sh  pipeline-build-sdp-demo-clienti credentials-build-tim.yml pipeline-build.yml
#./set_pipeline-tim.sh  pipeline-task-artifact-test-sdp-demo-clienti credentials-build-tim.yml pipeline-task-artifact-test.yml
#./set_pipeline.sh  pipeline-deploy-system-test credentials-deploy-tim.yml pipeline-deploy.yml
#./set_pipeline.sh pipeline-deploy-notify credentials-deploy-tim.yml pipeline-deploy-notify.yml
