branchName="*/master"
listViewName="AutomaticDeploy"
CodeRepoUrl="https://github.com/akashrventekar/AutomaticDeploy.git"
buildNo="$BUILD_NUMBER";


jobName=listViewName+"-prep"
job(jobName){
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
	
            

}

jobName=listViewName + "-provision-infra"
job(jobName){
    parameters {
        stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
    }
    deliveryPipelineConfiguration("Acceptance", jobName)
    blockOnDownstreamProjects()
    scm {
        git{
            remote{
                url(CodeRepoUrl)
                 }
            branch(branchName)

        }
    }
    steps{
		shell('aws cloudformation create-stack --stack-name WebServer --template-body file:///var/lib/jenkins/workspace/AutomaticDeploy-provision-infra/EC2Template.js --parameters ParameterKey=InstanceType,ParameterValue=t2.micro ParameterKey=KeyName,ParameterValue=My-Jenkins-Server ParameterKey=SSHLocation,ParameterValue=0.0.0.0/0  --region us-east-1' )
    }

}

jobName=listViewName + "-execute-tests"
freeStyleJob(jobName){
    parameters {
        stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
    }

    deliveryPipelineConfiguration("Acceptance", jobName)
    blockOnDownstreamProjects()
    scm {
        git{
            remote{
                url(CodeRepoUrl)
                 }
            branch(branchName)

        }
    }
    steps{
        shell('echo '+buildNo)
        shell('/usr/bin/python var/lib/jenkins/workspace/AutomaticDeploy-execute-tests/Test.py')
    }
}

jobName=listViewName + "-env-tear-down"
freeStyleJob(jobName){
    parameters {
        stringParam('BRANCH_NAME', branchName, 'The branch name or tag that must be built')
    }
    deliveryPipelineConfiguration("Acceptance", jobName)
    blockOnDownstreamProjects()
    
    steps{
        shell('aws cloudformation delete-stack --stack-name WebServer --region us-east-1')
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