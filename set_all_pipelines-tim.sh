./set_pipeline.sh pipeline-build credentials-build-tim.yml pipeline-build.yml
./set_pipeline.sh pipeline-task-artifact-test credentials-build-tim.yml pipeline-task-artifact-test.yml
./set_pipeline.sh pipeline-deploy-system-test credentials-deploy-tim.yml pipeline-deploy.yml
./set_pipeline.sh pipeline-deploy-notify credentials-deploy-tim.yml pipeline-deploy-notify.yml
