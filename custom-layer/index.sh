function handler () {
    aws cloudformation create-stack --stack-name cfn-freeze-stack  \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
    --template-url https://cf-template-sandboxes.s3.amazonaws.com/aws-freeze-service.yaml  \
    --parameters ParameterKey=NotificationEmailAddress,ParameterValue='ahmedhosni.contact@gmail.com' ParameterKey=WhenToExecute,ParameterValue='cron(0 0 * * ? *)' ParameterKey=RetentionInDays,ParameterValue=14 ParameterKey=AWSFreezeProfileName,ParameterValue=freeze
}