from azure.cosmos import exceptions, CosmosClient, PartitionKey
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import argparse
import os
import json

parser = argparse.ArgumentParser(description='Seed Cosmos DB with config data')
parser.add_argument('--connectionstring', type=str, help='Cosmos DB connection string')
parser.add_argument('--keyvault-name', type=str, help='Key Vault name (to fetch connection string)')
parser.add_argument('--secret-name', type=str, default='CosmosConnectionString', help='Secret name holding the Cosmos connection string')
parser.add_argument('--database', type=str, required=True, help='Cosmos DB database name')
parser.add_argument('--container', type=str, required=True, help='Cosmos DB container name')
parser.add_argument('--configdata', type=str, required=True, help='ConfigData folder path')

args = parser.parse_args()
DATABASE_ID = args.database
CONTAINER_ID = args.container
CONFIG_DATA_DIR = args.configdata

def _resolve_connection_string() -> str:
    # Priority: explicit arg > Key Vault > env var
    if args.connectionstring:
        return args.connectionstring
    if args.keyvault_name:
        # argparse maps '--keyvault-name' to keyvault_name
        kv_name = args.keyvault_name
        secret_name = args.secret_name
        if not kv_name:
            raise RuntimeError('Key Vault name not provided. Use --keyvault-name <name>.')
        credential = DefaultAzureCredential()
        kv_uri = f"https://{kv_name}.vault.azure.net/"
        client = SecretClient(vault_url=kv_uri, credential=credential)
        secret = client.get_secret(secret_name)
        return secret.value
    env_cs = os.getenv('COSMOS_CONNECTION_STRING')
    if env_cs:
        return env_cs
    raise RuntimeError('Cosmos connection string not provided. Pass --connectionstring, or --keyvault-name/--secret-name, or set COSMOS_CONNECTION_STRING.')


def upsert_config_item(container, config_doc):
    """Upserts config item to the appropriate container"""
    try:
        response = container.upsert_item(body=config_doc)
        return response
    
    except exceptions.CosmosHttpResponseError:
        print('\nupsert_item caught an error upserting item {0}'.format(config_doc['id']))


def get_cosmos_client():
    """Gets Cosmos client using a connection string"""
    conn_str = _resolve_connection_string()
    # azure-cosmos supports creating client from connection string
    return CosmosClient.from_connection_string(conn_str)


def get_cosmos_database(client):
    try:
        db = client.create_database_if_not_exists(id = DATABASE_ID)
        return db

    except exceptions.CosmosHttpResponseError:
        pass


def get_cosmos_container(database, container_id):
    try:
        container = database.create_container_if_not_exists(id = container_id, partition_key=PartitionKey(path='/id', kind='Hash'))
        return container

    except exceptions.CosmosHttpResponseError:
        print('Container with id \'{0}\' was found'.format(container_id))


def process_config_docs():
    print("\nprocess_config_docs started")
    client = get_cosmos_client()

    try:
        # setup database for this sample
        db = get_cosmos_database(client)

        config_data_dir = os.scandir(CONFIG_DATA_DIR)
        print("Iterating directories in '{0}'".format(CONFIG_DATA_DIR))

        for entry in config_data_dir:
            print ("Processing directory '{0}'".format(entry.name))
            if entry.is_dir():
                print("Iterating files in '{0}' directory.".format(entry.name))
                container = get_cosmos_container(db, entry.name)
                current_dir = os.scandir(entry.path)

                for file_entry in current_dir:
                    if file_entry.is_file:
                        print("Processing file '{0}'". format(file_entry.name))
                        with open(file_entry.path) as json_file:
                            data = json.load(json_file)

                            for item in data:
                                response = upsert_config_item(container, item)
                                print('Upserted Item\'s Id is {0}'.format(response['id']))

                current_dir.close()
                
        config_data_dir.close()

    except exceptions.CosmosHttpResponseError as e:
        print('\nprocess_config_docs has caught an error. {0}'.format(e.message))

    finally:
        print("\nprocess_config_docs done")


if __name__ == '__main__':
    process_config_docs()
