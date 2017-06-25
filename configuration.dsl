
def gitUrl = 'https://github.com/akashrventekar/AutomaticDeploy.git'

job('PROJ-unit-tests') {
    scm {
        git(gitUrl)
    }
    triggers {
        scm('*/15 * * * *')
    }
    steps {
        shell('aws cloudformation create-stack --stack-name WebServer --template-body file:///var/lib/jenkins/workspace/DeployMyWebServer-seed/EC2Template.js --parameters ParameterKey=InstanceType,ParameterValue=t2.micro ParameterKey=KeyName,ParameterValue=My-Jenkins-Server ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0  --region us-east-1' )
        shell('aws s3 cp /var/lib/jenkins/workspace/DeployMyWebServer-seed/index.html s3://cf-templates-1oovhy8v24ee5-us-east-1/index.html  --region us-east-1')
    }
}

