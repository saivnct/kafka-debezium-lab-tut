#!/usr/bin/env bash
export DEBEZIUM_VERSION=2.3
docker-compose down
sudo rm -rf postgres
sudo rm -rf kafka
sudo rm -rf elastic

docker-compose up -d

sleep 30

# Start Elasticsearch sink connector for topics "customers,geom,orders,products" (these topics has key named 'id')
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @elastic-sink-1.json

# Start Elasticsearch sink connector for topic "orders" (this topic has key named 'order_number')
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @elastic-sink-2.json

# Start Debezium Postgres CDC connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @postgres-source.json


docker-compose logs -f connect