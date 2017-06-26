import boto3
import time
import sys
import json
from multiprocessing.pool import ThreadPool
KeyPairName='My-Jenkins-Server'

client = boto3.setup_default_session(region_name='us-east-1')
client = boto3.client('cloudformation')
stack = client.describe_stack_events(
        StackName='WebServer'
        )
summary=stack['StackEvents']
flag = 0
for stack in summary:
        if stack['ResourceType'] ==  'AWS::CloudFormation::Stack' and stack['ResourceStatus'] ==  'CREATE_COMPLETE':
                flag = 1
if flag == 0:
        raise ValueError('Stack not created')
