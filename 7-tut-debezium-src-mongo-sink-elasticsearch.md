# Debezium CDC Unwrap MongoDB SMT  - Elasticsearch sink connector demo

This example shows how to capture events from a MongoDB database and stream them to Elastichsearch.
In order to convert the CDC events ebitted by Debezium's MongoDB connector into a "flat" structure consumable by the Elasticsearch sink connector, [Debezium MongoDB Event Flattening SMT](https://debezium.io/docs/configuration/mongodb-event-flattening/) is used.

We are using Docker Compose to deploy the following components:

* MongoDB 5
* Kafka
  * Kafka Broker
  * Kafka Connect with the [Debezium CDC](https://debezium.io/) and [JDBC sink](https://github.com/confluentinc/kafka-connect-jdbc) connectors as well as the Postgres JDBC driver
* Elastisearch 8

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
                  | Elasticsearch 8|
                  |                |
                  +----------------+


```


## Preparations - Option 1: Step by step setup

```shell
# go to working directory
cd 7-src-mongo-sink-elasticsearch

# Start the application
./start.sh

# Initialize MongoDB replica set and insert some test data
docker compose exec mongodb bash -c '/usr/local/bin/init-inventory.sh'

# Start Elasticsearch sink connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @elastic-sink.json

# Start Debezium MongoDB CDC connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mongodb-source.json

```

## Preparations - Option 2: All in one setup
```shell
cd 7-src-mongo-sink-elasticsearch

./clean-start.sh
```

# Viewing change events from a Debezium topic

```shell
# listen for topic "dbserver1.inventory.customers"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.inventory.customers --from-beginning --property print.key=true
	
# listen for topic "dbserver1.inventory.orders"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic dbserver1.inventory.orders --from-beginning --property print.key=true
```



## Verify initial sync

Check contents of the MongoDB database:

```shell
docker compose exec mongodb bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory --eval "db.customers.find()"'

{ "_id" : NumberLong(1001), "first_name" : "Sally", "last_name" : "Thomas", "email" : "sally.thomas@acme.com" }
{ "_id" : NumberLong(1002), "first_name" : "George", "last_name" : "Bailey", "email" : "gbailey@foobar.com" }
{ "_id" : NumberLong(1003), "first_name" : "Edward", "last_name" : "Walker", "email" : "ed@walker.com" }
{ "_id" : NumberLong(1004), "first_name" : "Anne", "last_name" : "Kretchmar", "email" : "annek@noanswer.org" }
```

Verify that Elasticsearch has the same content:

```shell
curl 'http://localhost:9200/customers/_search?pretty'

{
  "took" : 2,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 4,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "customers",
        "_id" : "1001",
        "_score" : 1.0,
        "_source" : {
          "id" : 1001,
          "first_name" : "Sally",
          "last_name" : "Thomas",
          "email" : "sally.thomas@acme.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      },
      {
        "_index" : "customers",
        "_id" : "1002",
        "_score" : 1.0,
        "_source" : {
          "id" : 1002,
          "first_name" : "George",
          "last_name" : "Bailey",
          "email" : "gbailey@foobar.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      },
      {
        "_index" : "customers",
        "_id" : "1003",
        "_score" : 1.0,
        "_source" : {
          "id" : 1003,
          "first_name" : "Edward",
          "last_name" : "Walker",
          "email" : "ed@walker.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      },
      {
        "_index" : "customers",
        "_id" : "1004",
        "_score" : 1.0,
        "_source" : {
          "id" : 1004,
          "first_name" : "Anne",
          "last_name" : "Kretchmar",
          "email" : "annek@noanswer.org",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      }
    ]
  }
}
```

## Adding a new record

Insert a new record into MongoDB:

```shell
docker compose exec mongodb bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'

MongoDB server version: 5.0.21
rs0:PRIMARY>

db.customers.insert([
    { _id : NumberLong("1005"), first_name : 'Bob', last_name : 'Hopper', email : 'bob@example.com' }
]);

...
"nInserted" : 1
...
```

Verify that Elasticsearch contains the new record:

```shell
curl 'http://localhost:9200/customers/_search?pretty'

...
      {
        "_index" : "customers",
        "_id" : "1005",
        "_score" : 1.0,
        "_source" : {
          "id" : 1005,
          "first_name" : "Bob",
          "last_name" : "Hopper",
          "email" : "bob@example.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      }
...
```

## Updating a record

Update a record in MongoDB:

```shell
docker compose exec mongodb bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'

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

Verify that record in Elasticsearch is updated:

```shell
curl 'http://localhost:9200/customers/_search?pretty'

...
      {
        "_index" : "customers",
        "_id" : "1005",
        "_score" : 1.0,
        "_source" : {
          "id" : 1005,
          "first_name" : "Billy-Bob",
          "last_name" : "Hopper",
          "email" : "bob@example.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      }
...
```

## Record delete
delete a record in MongoDB:

```shell
docker compose exec mongodb bash -c 'mongo -u debezium -p dbz --authenticationDatabase admin inventory'

MongoDB server version: 5.0.21
rs0:PRIMARY>
db.customers.remove(
   {
    _id: NumberLong("1005")
   }
);   
```

Verify that record in Elasticsearch is deleted:

```shell
curl 'http://localhost:9200/customers/_search?pretty'

{
  "took" : 2,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 4,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "customers",
        "_id" : "1001",
        "_score" : 1.0,
        "_source" : {
          "id" : 1001,
          "first_name" : "Sally",
          "last_name" : "Thomas",
          "email" : "sally.thomas@acme.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      },
      {
        "_index" : "customers",
        "_id" : "1002",
        "_score" : 1.0,
        "_source" : {
          "id" : 1002,
          "first_name" : "George",
          "last_name" : "Bailey",
          "email" : "gbailey@foobar.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      },
      {
        "_index" : "customers",
        "_id" : "1003",
        "_score" : 1.0,
        "_source" : {
          "id" : 1003,
          "first_name" : "Edward",
          "last_name" : "Walker",
          "email" : "ed@walker.com",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      },
      {
        "_index" : "customers",
        "_id" : "1004",
        "_score" : 1.0,
        "_source" : {
          "id" : 1004,
          "first_name" : "Anne",
          "last_name" : "Kretchmar",
          "email" : "annek@noanswer.org",
          "__rs" : "rs0",
          "__collection" : "customers"
        }
      }
    ]
  }
}
```

There should be no record of `Billy-Bob`.


## Stop application
```shell
# Stop the application
./stop.sh

# Clear all data
./clear.sh
```