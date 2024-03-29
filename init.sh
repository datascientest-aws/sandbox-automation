#!/bin/bash

# This script trigger the Datascientest Sandbox creation with the initla CloudFormation templates.
# If the S3 Bucket has not been created, this Script will create S3 bucket and tag the bucket with appropriate name.
 
# To check if access key is setup in your system 
if ! grep aws_access_key_id ~/.aws/config; then
   if ! grep aws_access_key_id ~/.aws/credentials; then
   echo "AWS config not found or you don't have AWS CLI installed"
   exit 1
   fi
fi
 
# read command will prompt you to enter the name of bucket name you wish to create 

read -r -p  "* Choose the account you want to deploy (format: student[1-30]):" student

cat $HOME/.aws/credentials | grep -A1 "$student" | head -2
echo
# prompting for choice
read -p "Do you want to proceed? (y/n) " -t 30 yn

if [ -z "$yn" ]
then
      echo -e "\nerror: no response detected"
      exit 1
fi

case $yn in
        y ) echo ok, we will proceed;;
        n ) echo exiting...;
                exit;;
        * ) echo invalid response;
                exit 1;;
esac


read -r -p  "* Enter the name of the sandbox user:" username
read -r -p  "* Enter the sandbox user password:" userpass
read -r -p  "* Enter the billing warning level (This will stop running resources) :" warning_level
read -r -p  "* Enter the billing critical level (This triggers the aws nuke pipeline) :" critical_level
read -r -p  "* Enter the email of the sandbox user to notify (Student email): " email_student
read -r -p  "* Enter the datascientest admin email to notify :" email_datascientest
read -r -p  "* Enter a valid Github token :"  GITHUBToken


# Choosing the account
export AWS_PROFILE=$student

function initsandbox()
{
   aws cloudformation create-stack \
  --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
  --stack-name sandbox-init-stack  --template-body file://aws-user-service.yaml \
  --parameters ParameterKey=UserName,ParameterValue=$username ParameterKey=Password,ParameterValue=$userpass ParameterKey=SESToEmail,ParameterValue=$email_student  --region us-east-1

  # Wait until the stack status is CREATE_COMPLETE
   
 #  until [ stack_status=$(aws cloudformation describe-stacks --stack-name sandbox-init-stack  --output json --query 'Stacks[0].StackStatus') = "CREATE_COMPLETE" ]
 #  do
     echo "Waiting until the stack status is CREATE_COMPLETE ..."
     sleep 120
 #  done
}

function invokeUserLambda()    
{
   touch response.json
   
   aws lambda invoke \
    --function-name caller \
    --region us-east-1 response.json
}

# Creating Second function to tag a bucket 
function invokeConfigLambda()    {
   aws lambda invoke \
    --function-name sandboxTrigger \
    --region us-east-1 \
    response2.json

#   --payload '{ "name": "Bob" }' \
sleep 20
}


function setupAlerts()
{

   #Fetch the S3 bucket name, it has been createed randomly by the first stack:
   S3BucketName=$(aws s3api list-buckets --query 'Buckets[*].[Name]' --output text | grep "cfn-datascientest-sandbox-templates-repo" | head -n 1)

   aws cloudformation create-stack \
  --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" "CAPABILITY_AUTO_EXPAND" \
  --stack-name sandbox-setup-billing-alerts --template-body file://aws-alerting-service.yaml\
  --parameters ParameterKey=CriticalLevel,ParameterValue=$critical_level  ParameterKey=WarningLevel,ParameterValue=$warning_level \
    ParameterKey=Email,ParameterValue=$email_datascientest  ParameterKey=EmailStudent,ParameterValue=$email_student  \
    ParameterKey=S3BucketName,ParameterValue=$S3BucketName  ParameterKey=GITHUBToken,ParameterValue=$GITHUBToken\
  --region us-east-1

   echo "Waiting until the billing alerts stack status is CREATE_COMPLETE ..."
   sleep 90
} 

echo "** Creating the AWS Sandbox user and preparing the sandbox config !! "
echo ""
initsandbox    # Calling the createbucket function  
invokeUserLambda
invokeConfigLambda
setupAlerts

#tagbucket       # calling our tagbucket function
#aws s3api list-objects --bucket S3BucketName --prefix * --query 'Contents[].[Key]' --output text | xargs -n 1 aws s3api put-object-tagging --bucket S3BucketName --tagging 'TagSet=[{Key=management,Value=student}]' --key
echo "** The sandbox-inint-stack AWS Cloudformation stack has been created successfully!"
