#./set_pipeline.sh pipeline-build credentials-build-local.yml pipeline-build.yml
#./set_pipeline.sh pipeline-task-artifact-test credentials-build-local.yml pipeline-task-artifact-test.yml
./set_pipeline.sh deploy-systemtest credentials-deploy-local.yml pipeline-deploy.yml
#./set_pipeline.sh pipeline-deploy-notify credentials-deploy-local.yml pipeline-deploy-notify.yml
