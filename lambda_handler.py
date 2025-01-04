import json
import requests
import os

def lambda_handler(event, context):
    print("Evento recibido:", json.dumps(event, indent=2))
    
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']

        response = requests.post(os.environ["MAGE_API_URL"], json={
            'bucket_name': bucket_name,
            'object_key': object_key
        })

    return {
        'statusCode': response.status_code,
        'body': response.text
    }