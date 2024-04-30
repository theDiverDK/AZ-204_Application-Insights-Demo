import argparse

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--endpoint', type=str, help='Cosmos DB endpoint')

args = parser.parse_args()
cosmosDBEndpoint = args.endpoint

print(f"The Cosmos DB endpoint is: {cosmosDBEndpoint}")
