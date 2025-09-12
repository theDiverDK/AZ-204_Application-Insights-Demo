from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import argparse
import os

parser = argparse.ArgumentParser(description='Seed Azure Blob Storage with config data')
parser.add_argument('--connectionstring', type=str, help='Azure Blob Storage connection string')
parser.add_argument('--keyvault-name', type=str, help='Key Vault name (to fetch connection string)')
parser.add_argument('--secret-name', type=str, default='StorageConnectionString', help='Secret name holding the Storage connection string')
parser.add_argument('--configdata', type=str, required=True, help='ConfigData folder path')

args = parser.parse_args()
CONFIG_DATA_DIR = args.configdata

def _resolve_connection_string() -> str:
    # Priority: explicit arg > Key Vault > env var
    if args.connectionstring:
        return args.connectionstring
    if args.keyvault_name:
        kv_name = args.keyvault_name
        secret_name = args.secret_name
        if not kv_name:
            raise RuntimeError('Key Vault name not provided. Use --keyvault-name <name>.')
        credential = DefaultAzureCredential()
        kv_uri = f"https://{kv_name}.vault.azure.net/"
        client = SecretClient(vault_url=kv_uri, credential=credential)
        secret = client.get_secret(secret_name)
        return secret.value
    env_cs = os.getenv('STORAGE_CONNECTION_STRING')
    if env_cs:
        return env_cs
    raise RuntimeError('Storage connection string not provided. Pass --connectionstring, or --keyvault-name/--secret-name, or set STORAGE_CONNECTION_STRING.')

def upload_blob(container_client, blob_name, data):
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(data, overwrite=True)

def get_container_client(container_name):
    blob_service_client = BlobServiceClient.from_connection_string(_resolve_connection_string())
    container_client = blob_service_client.get_container_client(container_name)

    if not container_client.exists():
        print("Creating container '{0}'".format(container_name))
        container_client.create_container()
    return container_client

def process_config_docs():
    print("\nprocess_config_docs started")

    try:
        config_data_dir = os.scandir(CONFIG_DATA_DIR)
        print("Iterating directories in '{0}'".format(CONFIG_DATA_DIR))

        for entry in config_data_dir:
            print("Processing directory '{0}'".format(entry.name))
            if entry.is_dir():
                print("Iterating files in '{0}' directory.".format(entry.name))
                current_dir = os.scandir(entry.path)

                container_client = get_container_client(entry.name)

                for file_entry in current_dir:
                    if file_entry.is_file():
                        print("Processing file '{0}'".format(file_entry.name))

                        with open(file_entry.path, 'rb') as data:
                            blob_name = f"{file_entry.name}"
                            upload_blob(container_client, blob_name, data)
                            print("Uploaded blob '{0}'".format(blob_name))

                current_dir.close()
                
        config_data_dir.close()

    except Exception as e:
        print('\nprocess_config_docs has caught an error: {0}'.format(str(e)))

    finally:
        print("\nprocess_config_docs done")

if __name__ == '__main__':
    process_config_docs()
