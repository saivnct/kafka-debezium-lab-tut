# Debezium CDC Unwrap MySQL SMT  - Elasticsearch sink connector demo

This example shows how to capture events from a Mysql database and stream them to Elastichsearch.
In order to convert the CDC events ebitted by Debezium's MySql connector into a "flat" structure consumable by the Elasticsearch sink connector, [Debezium Event Flattening SMT](https://debezium.io/documentation/reference/2.3/transformations/event-flattening.html) is used.

We are using Docker Compose to deploy the following components:

* MySQL
* Kafka
  * Kafka Broker
  * Kafka Connect with the [Debezium CDC](https://debezium.io/) and [Elasticsearch sink](https://github.com/confluentinc/kafka-connect-elasticsearch) connectors
* Elastisearch 8


### Topology

```
                   +-------------+
                   |             |
                   |    MySQL    |
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
cd 5-src-mysql-sink-elasticsearch

# Start the application
./start.sh

# Start Elasticsearch sink connector for topic "customers,addresses,geom,products" (these topic has key named 'id')
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @elastic-sink-1.json

# Start Elasticsearch sink connector for topic "orders" (this topic has key named 'order_number')
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @elastic-sink-2.json

# Start Debezium Mysql CDC connector
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @mysql-source.json

```

## Preparations - Option 2: All in one setup
```shell
cd 5-src-mysql-sink-elasticsearch

./clean-start.sh
```

# Viewing change events from a Debezium topic

```shell
# listen for topic "dbserver1.inventory.customers"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic customers --from-beginning --property print.key=true
	
# listen for topic "dbserver1.inventory.orders"
docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic orders --from-beginning --property print.key=true
```



## Verify initial sync

Check contents of the MySQL database:

```shell
docker compose exec mysql bash -c 'mysql -u mysqluser  -pmysqlpw inventory -e "select * from customers"'
+------+------------+-----------+-----------------------+
| id   | first_name | last_name | email                 |
+------+------------+-----------+-----------------------+
| 1001 | Sally      | Thomas    | sally.thomas@acme.com |
| 1002 | George     | Bailey    | gbailey@foobar.com    |
| 1003 | Edward     | Walker    | ed@walker.com         |
| 1004 | Anne       | Kretchmar | annek@noanswer.org    |
+------+------------+-----------+-----------------------+
```

Verify that Elasticsearch has the same content:

```shell
curl 'http://localhost:9200/customers/_search?pretty'
{
  "took" : 42,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 4,
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1001",
        "_score" : 1.0,
        "_source" : {
          "id" : 1001,
          "first_name" : "Sally",
          "last_name" : "Thomas",
          "email" : "sally.thomas@acme.com"
        }
      },
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1004",
        "_score" : 1.0,
        "_source" : {
          "id" : 1004,
          "first_name" : "Anne",
          "last_name" : "Kretchmar",
          "email" : "annek@noanswer.org"
        }
      },
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1002",
        "_score" : 1.0,
        "_source" : {
          "id" : 1002,
          "first_name" : "George",
          "last_name" : "Bailey",
          "email" : "gbailey@foobar.com"
        }
      },
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1003",
        "_score" : 1.0,
        "_source" : {
          "id" : 1003,
          "first_name" : "Edward",
          "last_name" : "Walker",
          "email" : "ed@walker.com"
        }
      }
    ]
  }
}

```


## Adding a new record

Insert a new record into MySQL:

```shell
docker compose exec mysql bash -c 'mysql -u mysqluser  -pmysqlpw inventory'
mysql> insert into customers values(default, 'John', 'Doe', 'john.doe@example.com');
Query OK, 1 row affected (0.02 sec)
```



Verify that Elasticsearch contains the new record:

```shell
curl 'http://localhost:9200/customers/_search?pretty'
...
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1005",
        "_score" : 1.0,
        "_source" : {
          "id" : 1005,
          "first_name" : "John",
          "last_name" : "Doe",
          "email" : "john.doe@example.com"
        }
      }
...
```

## Updating a record

Update a record in MySQL:

```shell
docker compose exec mysql bash -c 'mysql -u mysqluser  -pmysqlpw inventory'

mysql> update customers set first_name='Jane', last_name='Roe' where last_name='Doe';
Query OK, 1 row affected (0.02 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

Verify that record inElasticsearch is updated:

```shell
curl 'http://localhost:9200/customers/_search?pretty'
...
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1005",
        "_score" : 1.0,
        "_source" : {
          "id" : 1005,
          "first_name" : "Jane",
          "last_name" : "Roe",
          "email" : "john.doe@example.com"
        }
      }
...
```

#### Record delete


Delete a record in MySQL:

```shell
docker compose exec mysql bash -c 'mysql -u mysqluser  -pmysqlpw inventory'

mysql> delete from customers where email='john.doe@example.com';
Query OK, 1 row affected (0.01 sec)
```

Verify that record in Elasticsearch is deleted:

```shell
curl 'http://localhost:9200/customers/_search?pretty'
{
  "took" : 42,
  "timed_out" : false,
  "_shards" : {
    "total" : 5,
    "successful" : 5,
    "failed" : 0
  },
  "hits" : {
    "total" : 4,
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1001",
        "_score" : 1.0,
        "_source" : {
          "id" : 1001,
          "first_name" : "Sally",
          "last_name" : "Thomas",
          "email" : "sally.thomas@acme.com"
        }
      },
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1004",
        "_score" : 1.0,
        "_source" : {
          "id" : 1004,
          "first_name" : "Anne",
          "last_name" : "Kretchmar",
          "email" : "annek@noanswer.org"
        }
      },
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1002",
        "_score" : 1.0,
        "_source" : {
          "id" : 1002,
          "first_name" : "George",
          "last_name" : "Bailey",
          "email" : "gbailey@foobar.com"
        }
      },
      {
        "_index" : "customers",
        "_type" : "customer",
        "_id" : "1003",
        "_score" : 1.0,
        "_source" : {
          "id" : 1003,
          "first_name" : "Edward",
          "last_name" : "Walker",
          "email" : "ed@walker.com"
        }
      }
    ]
  }
}

```

There should be no record of `Jane Doe`.


## Stop application
```shell
# Stop the application
./stop.sh

# Clear all data
./clear.sh
```