#!/usr/bin/env bash
export DEBEZIUM_VERSION=2.3
docker-compose down
sudo rm -rf mongodb
sudo rm -rf kafka
sudo rm -rf elastic

docker-compose up -d

sleep 30

# Initialize MongoDB replica set and insert some test data
docker-compose exec mongodb bash -c '/usr/local/bin/init-inventory.sh'

sleep 3


# Start Elasticsearch sink connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @elastic-sink.json

# Start Debezium MongoDB CDC connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mongodb-source.json


docker-compose logs -f connect