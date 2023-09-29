# Debezium CDC MongoDB - Data warehouse demo

This example shows how to capture events from a MongoDB database and stream them to data warehouse (another MongoDB database).

We are using Docker Compose to deploy the following components:

* MongoDB1 as connector source
* MongoDB2 as connector sink
* Kafka
  * Kafka Broker
  * Kafka Connect with the [Debezium CDC](https://debezium.io/) and [Mongo-Kafka sink](https://github.com/mongodb/mongo-kafka) connectors


### Topology

```
                   +-------------+
                   |             |
                   |  MongoDB 5  |
                   |             |
                   +------+------+
                          |
                          |
                          |
          +---------------v------------------+
          |                                  |
          |           Kafka Connect          |
          |    (Debezium, ES connectors)     |
          |                                  |
          +---------------+------------------+
                          |
                          |
                          |
                          |
                  +-------v--------+
                  |                |
                  |    MongoDB 5   |
                  |                |
                  +----------------+


```

## Preparations - Option 1: Step by step setup

```shell
# go to working directory
cd 4-src-mongo-sink-mongo

# Start the application
./start.sh

# Initialize MongoDB1 replica set and insert some test data 
docker compose exec mongodb1 bash -c '/usr/local/bin/init-inventory.sh'

# Initialize MongoDB2 replica set
docker compose exec mongodb2 bash -c '/usr/local/bin/init-inventory.sh'

# Register MongoDB-Kafka sink connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mongodb-sink.json

# Register Debezium MongoDB CDC connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mongodb-source.json

```

## Preparations - Option 2: All in one setup
```shell
cd 4-src-mongo-sink-mongo

./clean-start.sh
```

# Viewing change events from a Debezium topic

```shell
# listen for topic "customers"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic customers --from-beginning --property print.key=true
	
# listen for topic "orders"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic orders --from-beginning --property print.key=true
```



## Verify initial sync

Check contents of the MongoDB1 database:

```shell
docker compose exec mongodb1 bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory --eval "db.customers.find()"'

{ "_id" : NumberLong(1001), "first_name" : "Sally", "last_name" : "Thomas", "email" : "sally.thomas@acme.com" }
{ "_id" : NumberLong(1002), "first_name" : "George", "last_name" : "Bailey", "email" : "gbailey@foobar.com" }
{ "_id" : NumberLong(1003), "first_name" : "Edward", "last_name" : "Walker", "email" : "ed@walker.com" }
{ "_id" : NumberLong(1004), "first_name" : "Anne", "last_name" : "Kretchmar", "email" : "annek@noanswer.org" }
```

Verify that the MongoDB2 database has the same content:

```shell
docker compose exec mongodb2 bash -c 'mongo -port 27018 -u debezium -p dbz --authenticationDatabase admin inventorybu --eval "db.customers.find()"'

{ "_id" : NumberLong(1001), "first_name" : "Sally", "last_name" : "Thomas", "email" : "sally.thomas@acme.com" }
{ "_id" : NumberLong(1002), "first_name" : "George", "last_name" : "Bailey", "email" : "gbailey@foobar.com" }
{ "_id" : NumberLong(1003), "first_name" : "Edward", "last_name" : "Walker", "email" : "ed@walker.com" }
{ "_id" : NumberLong(1004), "first_name" : "Anne", "last_name" : "Kretchmar", "email" : "annek@noanswer.org" }
```

## Adding a new record

Insert a new record into MongoDB:

```shell
docker compose exec mongodb1 bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'

MongoDB server version: 5.0.21
rs0:PRIMARY>

db.customers.insert([
    { _id : NumberLong("1005"), first_name : 'Bob', last_name : 'Hopper', email : 'bob@example.com' }
]);

...
"nInserted" : 1
...
```

Verify that MongoDB2 contains the new record:

```shell
docker compose exec mongodb2 bash -c 'mongo -port 27018 -u debezium -p dbz --authenticationDatabase admin inventorybu --eval "db.customers.find()"'

{ "_id" : NumberLong(1001), "first_name" : "Sally", "last_name" : "Thomas", "email" : "sally.thomas@acme.com" }
{ "_id" : NumberLong(1002), "first_name" : "George", "last_name" : "Bailey", "email" : "gbailey@foobar.com" }
{ "_id" : NumberLong(1003), "first_name" : "Edward", "last_name" : "Walker", "email" : "ed@walker.com" }
{ "_id" : NumberLong(1004), "first_name" : "Anne", "last_name" : "Kretchmar", "email" : "annek@noanswer.org" }
{ "_id" : NumberLong(1005), "first_name" : "Bob", "last_name" : "Hopper", "email" : "bob@example.com" }
```

## Updating a record

Update a record in MongoDB:

```shell
docker compose exec mongodb1 bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'

MongoDB server version: 5.0.21
rs0:PRIMARY>

db.customers.update(
   {
    _id : NumberLong("1005")
   },
   {
     $set : {
       first_name: "Billy-Bob"
     }
   }
);
```

Verify that record in MongoDB2 is updated:

```shell
docker compose exec mongodb2 bash -c 'mongo -port 27018 -u debezium -p dbz --authenticationDatabase admin inventorybu --eval "db.customers.find()"'

{ "_id" : NumberLong(1001), "first_name" : "Sally", "last_name" : "Thomas", "email" : "sally.thomas@acme.com" }
{ "_id" : NumberLong(1002), "first_name" : "George", "last_name" : "Bailey", "email" : "gbailey@foobar.com" }
{ "_id" : NumberLong(1003), "first_name" : "Edward", "last_name" : "Walker", "email" : "ed@walker.com" }
{ "_id" : NumberLong(1004), "first_name" : "Anne", "last_name" : "Kretchmar", "email" : "annek@noanswer.org" }
{ "_id" : NumberLong(1005), "first_name" : "Billy-Bob", "last_name" : "Hopper", "email" : "bob@example.com" }
```

```shell
docker compose exec mongodb1 bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'

MongoDB server version: 5.0.21
rs0:PRIMARY>
db.customers.remove(
   {
    _id: NumberLong("1005")
   }
);   
```

Verify that record in PostgreSQL is deleted:

```shell
docker compose exec mongodb2 bash -c 'mongo -port 27018 -u debezium -p dbz --authenticationDatabase admin inventorybu --eval "db.customers.find()"'

{ "_id" : NumberLong(1001), "first_name" : "Sally", "last_name" : "Thomas", "email" : "sally.thomas@acme.com" }
{ "_id" : NumberLong(1002), "first_name" : "George", "last_name" : "Bailey", "email" : "gbailey@foobar.com" }
{ "_id" : NumberLong(1003), "first_name" : "Edward", "last_name" : "Walker", "email" : "ed@walker.com" }
{ "_id" : NumberLong(1004), "first_name" : "Anne", "last_name" : "Kretchmar", "email" : "annek@noanswer.org" }
```

There should be no record of `Billy-Bob`.


## Stop application
```shell
# Stop the application
./stop.sh

# Clear all data
./clear.sh
```
