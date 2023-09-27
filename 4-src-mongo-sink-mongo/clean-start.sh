#!/usr/bin/env bash
export DEBEZIUM_VERSION=2.3
docker compose down

sudo rm -rf mongodb1
sudo rm -rf mongodb2
sudo rm -rf kafka

docker compose up -d

sleep 5

# Initialize MongoDB replica set and insert some test data
docker compose exec mongodb1 bash -c '/usr/local/bin/init-inventory.sh'

# Initialize MongoDB2 replica set
docker compose exec mongodb2 bash -c '/usr/local/bin/init-inventory.sh'


# Register MongoDB-Kafka sink connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mongodb-sink.json

sleep 1

# Register Debezium MongoDB CDC connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mongodb-source.json


docker-compose logs -f connect