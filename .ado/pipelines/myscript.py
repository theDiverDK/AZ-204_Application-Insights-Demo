import argparse

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--endpoint', type=str, help='Cosmos DB endpoint')
parser.add_argument('--key', type=str, help='Cosmos DB key')
parser.add_argument('--database', type=str, help='Cosmos DB database name')
parser.add_argument('--container', type=str, help='Cosmos DB container name')

args = parser.parse_args()
cosmosDBEndpoint = args.endpoint
cosmosDBKey = args.key
cosmosDBDatabaseName = args.database
cosmosDBContainerName = args.container

print(f"The Cosmos DB endpoint is: {cosmosDBEndpoint}")
print(f"The Cosmos DB key is: {cosmosDBKey}")
print(f"The Cosmos DB database name is: {cosmosDBDatabaseName}")
print(f"The Cosmos DB container name is: {cosmosDBContainerName}")

