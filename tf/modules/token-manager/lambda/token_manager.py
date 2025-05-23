import boto3
import json
import os

def lambda_handler(event, context):
    # Initialize AWS clients
    ssm = boto3.client('ssm')
    secrets = boto3.client('secretsmanager')
    
    # Get environment variables
    instance_id = os.environ['CONTROL_PLANE_INSTANCE_ID']
    secret_name = os.environ['SECRET_MANAGER_NAME']
    
    try:
        # Run kubeadm command on the control plane instance
        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName='AWS-RunShellScript',
            Parameters={
                'commands': ['sudo kubeadm token create --print-join-command']
            }
        )
        
        # Get Command ID
        command_id = response['Command']['CommandId']
        
        # Wait for command completion and get output
        waiter = ssm.get_waiter('command_executed')
        waiter.wait(
            CommandId=command_id,
            InstanceId=instance_id
        )
        
        # Get command output
        output = ssm.get_command_invocation(
            CommandId=command_id,
            InstanceId=instance_id
        )
        
        join_command = output['StandardOutputContent'].strip()
        
        if not join_command:
            raise Exception("Failed to get join command - empty output")
        
        # Store join command in Secrets Manager
        secrets.put_secret_value(
            SecretId=secret_name,
            SecretString=json.dumps({
                'join_command': join_command,
                'timestamp': context.invoked_function_arn
            })
        )
        
        return {
            'statusCode': 200,
            'body': 'Successfully updated join command in Secrets Manager'
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise 