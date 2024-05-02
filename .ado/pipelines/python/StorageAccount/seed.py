from azure.storage.blob import BlobServiceClient, ContainerClient, BlobClient
import argparse
import os
import json

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--connectionString', type=str, help='Azure Blob Storage connection string')
parser.add_argument('--configData', type=str, help='ConfigData folder path')

args = parser.parse_args()
CONNECTION_STRING = args.connectionString
CONFIG_DATA_DIR = args.configData

def upload_blob(container_client, blob_name, data):
    """Uploads a blob to the appropriate container"""
    blob_client = container_client.get_blob_client(blob_name)
    blob_client.upload_blob(data, overwrite=True)

def get_container_client(container_name):
    """Gets a container client to connect to the blob container"""
    blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
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
