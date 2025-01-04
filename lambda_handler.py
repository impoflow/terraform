import json
import boto3
import http.client
import os
from urllib.parse import urlparse
from typing import Dict, Any, List


class ConfigError(Exception):
    """Excepción lanzada cuando la configuración es inválida o está incompleta."""
    pass


class S3Reader:    
    def __init__(self, s3_client=None):
        self.s3 = s3_client or boto3.client('s3')

    def read_json_object(self, bucket_name: str, object_key: str) -> Dict[str, Any]:
        try:
            s3_object = self.s3.get_object(Bucket=bucket_name, Key=object_key)
            object_content = s3_object['Body'].read().decode('utf-8')
            return json.loads(object_content)
        except Exception as e:
            raise RuntimeError(
                f"Error al leer el objeto S3. Bucket: {bucket_name}, Key: {object_key}. Detalles: {str(e)}"
            ) from e


class MageApiClient:
    def __init__(self, base_url: str):
        if not base_url:
            raise ConfigError("La variable de entorno MAGE_API_URL no está configurada.")
        
        self.parsed_url = urlparse(base_url)
        self.host = self.parsed_url.hostname
        self.port = self.parsed_url.port or (443 if self.parsed_url.scheme == 'https' else 80)
        self.path = self.parsed_url.path or '/'
        self.scheme = self.parsed_url.scheme.lower()

    def post_json(self, data: Dict[str, Any]) -> Dict[str, Any]:
        payload_str = json.dumps(data)

        if self.scheme == "https":
            connection = http.client.HTTPSConnection(self.host, self.port)
        else:
            connection = http.client.HTTPConnection(self.host, self.port)

        headers = {'Content-Type': 'application/json'}

        try:
            connection.request("POST", self.path, payload_str, headers)
            response = connection.getresponse()
            response_body = response.read().decode('utf-8')
            return {
                'status_code': response.status,
                'response_body': response_body
            }
        except Exception as e:
            raise RuntimeError(
                f"Error al realizar la solicitud POST a {self.host}. Detalles: {str(e)}"
            ) from e
        finally:
            connection.close()


class S3EventProcessor:
    def __init__(self, s3_reader: S3Reader, mage_api_client: MageApiClient):
        self.s3_reader = s3_reader
        self.mage_api_client = mage_api_client

    def process_event_records(self, event_records: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        results = []

        for record in event_records:
            bucket_name = None
            object_key = None

            try:
                bucket_name = record['s3']['bucket']['name']
                object_key = record['s3']['object']['key']

                object_json = self.s3_reader.read_json_object(bucket_name, object_key)
                
                api_response = self.mage_api_client.post_json(object_json)

                results.append({
                    'bucket_name': bucket_name,
                    'object_key': object_key,
                    'api_status_code': api_response['status_code'],
                    'api_response': api_response['response_body']
                })

            except Exception as e:
                print(f"Error procesando el registro (bucket: {bucket_name}, key: {object_key}): {str(e)}")
                results.append({
                    'bucket_name': bucket_name,
                    'object_key': object_key,
                    'error': str(e)
                })
        
        return results


def lambda_handler(event, context):
    mage_api_url = os.environ.get("MAGE_API_URL")
    if not mage_api_url:
        raise ValueError("La variable de entorno MAGE_API_URL no está configurada.")

    s3_reader = S3Reader()
    mage_api_client = MageApiClient(mage_api_url)
    event_processor = S3EventProcessor(s3_reader, mage_api_client)

    print("Evento recibido:", json.dumps(event, indent=2))

    records = event.get('Records', [])
    responses = event_processor.process_event_records(records)

    return {
        'statusCode': 200,
        'body': json.dumps(responses, indent=2)
    }