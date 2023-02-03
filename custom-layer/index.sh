function handler () {
    group_name='datascientest-readonlyusers'
    policy_arn='arn:aws:iam::aws:policy/ReadOnlyAccess'
    # Create the Readonly IAM group and assign the right managed policy
    # https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#policies/arn:aws:iam::aws:policy/ReadOnlyAccess 
    aws iam create-group --group-name $group_name
    aws iam attach-group-policy --group-name "$group_name" --policy-arn "$policy_arn" 

    # Publish an SNS message to the right topic
    topic=$(aws sns list-topics | jq -r ".Topics[ ] | .TopicArn" | grep BillingEmailAlertTopic )
    aws sns publish --topic-arn $topic --message 'You reached the warning level of your AWS sandbox budget. We’ll stop your was resources to reduce unwanted billing.'

    # Make all users Read Only by adding them to the right group
    for user in $(aws iam list-users --query '[Users[].UserName]' --output text) ; do 

      # Remove all the policies directly attached to the user
      for policy_arn in $(aws iam list-attached-user-policies --user-name $user --query '[AttachedPolicies[].PolicyArn]' --output text) ; do 
        aws iam detach-user-policy --user-name $user --policy-arn $policy_arn
      done

       # Remove user from all the IAM user groups to remove inherited permissions
      for iamgroup in $(aws iam list-groups-for-user --user-name $user --query '[Groups[].GroupName]' --output text) ; do
        aws iam remove-user-from-group --user-name $user --group-name $iamgroup
      done
      
      # Add the user to the newly created read only IAM group
      aws iam add-user-to-group --user-name $user --group-name $group_name
    done

    #GITHUBToken should be added as an environment variable to this lambda.

    # Create the codepipeline freeze process to start freezing resources 
    aws cloudformation create-stack --stack-name cfn-freeze-stack  \
    --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
    --template-url https://cf-template-datascientest-sandboxes.s3.amazonaws.com/aws-freeze-service.yaml  \
    --tags='[{"Key": "management","Value": "student"} \
    --parameters  ParameterKey=GitToken,ParameterValue=$GITHUBToken ParameterKey=NotificationEmailAddress,ParameterValue='dst-student@datascientest.com' ParameterKey=WhenToExecute,ParameterValue='cron(0 0 * * ? *)' ParameterKey=RetentionInDays,ParameterValue=14 ParameterKey=AWSFreezeProfileName,ParameterValue=freeze 
}
