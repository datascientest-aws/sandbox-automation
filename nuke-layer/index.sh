function handler () {
    aws cloudformation create-stack --stack-name cfn-nuke-stack  \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
    --template-url https://cf-template-datascientest-sandboxes.s3.amazonaws.com/aws-wipe-service.yaml  \
    --parameters ParameterKey=GitUser,ParameterValue='hosniah' ParameterKey=GitRepo,ParameterValue='aws-nuke-service' ParameterKey=GitBranch,ParameterValue=master ParameterKey=GitToken,ParameterValue='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' ParameterKey=AWSNukeVersionNumber,ParameterValue='2.12.0' ParameterKey=AWSNukeConfigFile,ParameterValue='aws-nuke-config/config.yaml' ParameterKey=AWSNukeProfileName,ParameterValue='nuke'
}
