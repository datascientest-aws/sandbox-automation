function handler () {
   topic=$(aws sns list-topics | jq -r ".Topics[ ] | .TopicArn" | grep BillingEmailAlertTopic )
   aws sns publish --topic-arn $topic --message “You have reached the limit of your AWS sandbox budget. We’ll proceed with the reset of this environment and destroy all the resources.”

    aws cloudformation create-stack --stack-name cfn-nuke-stack  \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
    --template-url https://cf-template-datascientest-sandboxes.s3.amazonaws.com/aws-wipe-service.yaml  \
    --tags Key=management, Value=student \
    --parameters ParameterKey=GitUser,ParameterValue='antho-data' ParameterKey=GitRepo,ParameterValue='aws-nuke-service' ParameterKey=GitBranch,ParameterValue=master ParameterKey=GitToken,ParameterValue=$GITHUBToken ParameterKey=AWSNukeVersionNumber,ParameterValue='2.12.0' ParameterKey=AWSNukeConfigFile,ParameterValue='aws-nuke-config/config.yaml' ParameterKey=AWSNukeProfileName,ParameterValue='nuke'
}
