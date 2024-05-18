import boto3
import os
import json

def handler(event, context):
    secret_id = os.environ['SECRET_ID']
    secrets_client = boto3.client('secretsmanager')

    current_secret = secrets_client.get_secret_value(SecretId=secret_id)

    new_password = secrets_client.get_random_password(
        PasswordLength=16,
        ExcludeCharacters=':/@"\'\\'
    )

    secrets_client.put_secret_value(
        SecretId=secret_id,
        SecretString=json.dumps({
            'username': json.loads(current_secret['SecretString'])['username'],
            'password': new_password['RandomPassword']
        })
    )

    return {
        'statusCode': 200,
        'body': json.dumps('Password rotation successful')
    }
