#!/usr/bin/env bash
export DEBEZIUM_VERSION=2.3
docker-compose down
sudo rm -rf mongodb
sudo rm -rf kafka

docker-compose up -d

sleep 3

# Initialize MongoDB replica set and insert some test data
docker-compose exec mongodb bash -c '/usr/local/bin/init-inventory.sh'


# Register the MongoDB connector to monitor the inventory database
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-mongodb.json

docker-compose logs -f mongodb