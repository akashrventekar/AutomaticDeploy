branchName="*/master"
listViewName="AutomaticDeploy"
CodeRepoUrl="https://github.com/akashrventekar/AutomaticDeploy.git"
buildNo="$BUILD_NUMBER";


jobName=listViewName+"-prep"
freeStyleJob(jobName){
	parameters 
	{
		stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
	}
	scm {
        git{
            remote{
                url(CodeRepoUrl)
                 }
            branch(branchName)

        }
    }
	blockOnDownstreamProjects()
	deliveryPipelineConfiguration('Launcher', jobName)
	steps{
        shell('aws s3 cp /var/lib/jenkins/workspace/DeployMyWebServer-seed/index.html s3://cf-templates-1oovhy8v24ee5-us-east-1/index.html  --region us-east-1')
	}
	 postBuildSteps {
            trigger (listViewName + '-execute-integration-tests', 'SUCCESS'){
                currentBuild()
            }
    }
}

jobName=listViewName + "-provision-infra"
freeStyleJob(jobName){
    parameters {
        stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
    }
    deliveryPipelineConfiguration("Acceptance", jobName)
    blockOnDownstreamProjects()
    
    steps{
		shell('aws cloudformation create-stack --stack-name WebServer --template-body file:///var/lib/jenkins/workspace/DeployMyWebServer-seed/EC2Template.js --parameters ParameterKey=InstanceType,ParameterValue=t2.micro ParameterKey=KeyName,ParameterValue=My-Jenkins-Server ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0  --region us-east-1' )
    }
        downstreamParameterized {
            trigger (listViewName + '-execute-tests', 'SUCCESS'){
                currentBuild()
            }
          }

}

jobName=listViewName + "-execute-tests"
freeStyleJob(jobName){
    parameters {
        stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
    }
    wrappers{
        colorizeOutput('xterm')

    }
    deliveryPipelineConfiguration("Acceptance", jobName)
    blockOnDownstreamProjects()
    
    steps{
        shell('echo '+buildNo)
        shell('/usr/bin/python multicftTest.py test ucs-test u1fz73fklj dqac3fajb8')
    }
    publishers {
        extendedEmail(notificationEmailAddressList,
            notificationEmailSubjectTemplate,
            notificationEmailContentTemplate) {
          trigger('Always')
        }
        downstreamParameterized {
            trigger (listViewName + '-env-tear-down', 'SUCCESS'){
                currentBuild()
            }
          }
    }
}

jobName=listViewName + "-execute-tests"
freeStyleJob(jobName){
    parameters {
        stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
    }
    wrappers{
        colorizeOutput('xterm')

    }
    deliveryPipelineConfiguration("Acceptance", jobName)
    blockOnDownstreamProjects()
    
    steps{
        shell('echo '+buildNo)
        shell('/usr/bin/python multicftTest.py test ucs-test u1fz73fklj dqac3fajb8')
    }
    publishers {
        extendedEmail(notificationEmailAddressList,
            notificationEmailSubjectTemplate,
            notificationEmailContentTemplate) {
          trigger('Always')
        }
        downstreamParameterized {
            trigger (listViewName + '-env-tear-down', 'SUCCESS'){
                currentBuild()
            }
          }
	}
}


listView(listViewName){
    description('All commit and acceptance jobs for ' + listViewName)
    jobs{
        regex(listViewName + '-.+')
    }
    columns {
        status()
        weather()
        name()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
   }
deliveryPipelineView(listViewName + '-pipeline'){
    pipelineInstances(3)
    showAggregatedPipeline(false)
    columns(1)
    sorting(Sorting.NONE)
    updateInterval(2)
    showAvatars(false)
    showChangeLog(false)
    pipelines {
      component('name', listViewName + '-prep')
    }
}