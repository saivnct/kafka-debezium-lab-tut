# Debezium CDC MongoDB Demo

This example shows how to capture events from a MongoDB database

We are using Docker Compose to deploy the following components:

* MongoDB
* Kafka
  * Kafka Broker
  * Kafka Connect with the [Debezium CDC](https://debezium.io/) connector

## Preparations - Option 1: Step by step setup

```shell
# go to working directory
cd 2-basic-mongo-connector

# Start the application
./start.sh

# Initialize MongoDB replica set and insert some test data
docker-compose exec mongodb bash -c '/usr/local/bin/init-inventory.sh'

# Register the MongoDB connector to monitor the inventory database
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-mongodb.json

```

## Preparations - Option 2: All in one setup
```shell
cd 3-src-mongo-sink-postgres

./clean-start.sh
```

# Viewing change events from a Debezium topic

```shell
# listen for topic "dbserver1.inventory.customers"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.inventory.customers --from-beginning --property print.key=true
	
# listen for topic "dbserver1.inventory.orders"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.inventory.orders --from-beginning --property print.key=true
```

## Adding a new record and verifying the change event

Insert a new record into MongoDB:

```shell
docker-compose exec mongodb bash -c 'mongo "mongodb://debezium:dbz@localhost:27017/inventory?tls=false&authSource=admin&replicaSet=rs0"'

MongoDB server version: 3.4.10
rs0:PRIMARY>

db.customers.insert([
{ _id : NumberLong("1005"), first_name : 'Bob', last_name : 'Hopper', email : 'thebob@example.com', unique_id : UUID() }
]);

...
"nInserted" : 1
...
```


## Stop application
```shell
# Stop the application
./stop.sh

# Clear all data
./clear.sh
```