import json

def lambda_handler(event, context):
    print("Evento recibido:", json.dumps(event, indent=2))
    
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
    
    return {
        'statusCode': 200,
        'body': json.dumps('Evento procesado correctamente.')
    }