import json
import http.client
from urllib.parse import urlparse
import os

def lambda_handler(event, context):
    """
    AWS Lambda handler para procesar eventos de S3 y enviar datos a una API externa usando http.client.
    """
    mage_api_url = os.environ.get("MAGE_API_URL")

    if not mage_api_url:
        raise ValueError("La variable de entorno MAGE_API_URL no está configurada.")
    
    parsed_url = urlparse(mage_api_url)
    host = parsed_url.hostname
    port = parsed_url.port if parsed_url.port else (443 if parsed_url.scheme == 'https' else 80)
    path = parsed_url.path

    print("Evento recibido:", json.dumps(event, indent=2))
    
    responses = []
    
    for record in event.get('Records', []):
        try:
            bucket_name = record['s3']['bucket']['name']
            object_key = record['s3']['object']['key']

            print(f"Procesando bucket: {bucket_name}, objeto: {object_key}")

            payload = json.dumps({
                'bucket_name': bucket_name,
                'object_key': object_key
            })

            connection = (
                http.client.HTTPSConnection(host, port)
                if parsed_url.scheme == "https"
                else http.client.HTTPConnection(host, port)
            )

            headers = {'Content-Type': 'application/json'}

            connection.request("POST", path, payload, headers)

            response = connection.getresponse()
            response_body = response.read().decode()

            print(f"Respuesta de la API: {response.status}, {response_body}")
            responses.append({
                'bucket_name': bucket_name,
                'object_key': object_key,
                'status_code': response.status,
                'response_body': response_body
            })

            connection.close()

        except Exception as e:
            print(f"Error procesando registro: {record}. Error: {str(e)}")
            responses.append({
                'bucket_name': bucket_name if 'bucket_name' in locals() else None,
                'object_key': object_key if 'object_key' in locals() else None,
                'error': str(e)
            })

    return {
        'statusCode': 200,
        'body': json.dumps(responses, indent=2)
    }