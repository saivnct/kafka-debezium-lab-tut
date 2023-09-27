# Debezium CDC Mysql Basic Demo

This example shows how to capture events from a Mysql database

We are using Docker to deploy the following components:

* Mysql
* Kafka
    * Kafka Broker
    * Kafka Connect with the [Debezium CDC](https://debezium.io/) connector


## Preparations

```shell
#1. Starting Zookeeper
docker run -it --rm --name zookeeper -p 2181:2181 -p 2888:2888 -p 3888:3888 quay.io/debezium/zookeeper:2.3

#2. Starting Kafka
docker run -it --rm --name kafka -p 9092:9092 --link zookeeper:zookeeper quay.io/debezium/kafka:2.3

#3. Starting a MySQL database
docker run -it --rm --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=debezium -e MYSQL_USER=mysqluser -e MYSQL_PASSWORD=mysqlpw quay.io/debezium/example-mysql:2.3

#4. Starting a MySQL command line client
docker run -it --rm --name mysqlterm --link mysql --rm mysql:8.0 sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD"'

#5. Starting Kafka Connect
# After starting MySQL and connecting to the inventory database with the MySQL command line client, you start the Kafka Connect service. This service exposes a REST API to manage the Debezium MySQL connector.
docker run -it --rm --name connect -p 8083:8083 -e GROUP_ID=1 -e CONFIG_STORAGE_TOPIC=my_connect_configs -e OFFSET_STORAGE_TOPIC=my_connect_offsets -e STATUS_STORAGE_TOPIC=my_connect_statuses --link kafka:kafka --link mysql:mysql quay.io/debezium/connect:2.3

# Check the status of the Kafka Connect service:
curl -H "Accept:application/json" localhost:8083/
{"version":"3.4.0","commit":"cb8625948210849f"}

# Check the list of connectors registered with Kafka Connect:		
curl -H "Accept:application/json" localhost:8083/connectors/
[]
```


## Deploying the MySQL connector
To deploy the MySQL connector, you must:
- Register the MySQL connector to monitor the inventory database
  After the connector is registered, it will start monitoring the database server’s binlog and it will generate change events for each row that changes.
- Watch the MySQL connector start
  Reviewing the Kafka Connect log output as the connector starts helps you to better understand each task it must complete before it can start monitoring the binlog.  

```shell
# Register the MongoDB connector to monitor the inventory database
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://localhost:8083/connectors/ -d '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.mysql.MySqlConnector", "tasks.max": "1", "database.hostname": "mysql", "database.port": "3306", "database.user": "debezium", "database.password": "dbz", "database.server.id": "184054", "topic.prefix": "dbserver1", "database.include.list": "inventory", "schema.history.internal.kafka.bootstrap.servers": "kafka:9092", "schema.history.internal.kafka.topic": "schemahistory.inventory" } }'

```


## Viewing change events with watch-topic

```shell
docker run -it --rm --name watcher --link zookeeper:zookeeper --link kafka:kafka quay.io/debezium/kafka:2.3 watch-topic -a -k dbserver1.inventory.customers

#-a
#Watches all events since the topic was created. Without this option, watch-topic would only show the events recorded after you start watching.

#-k
#Specifies that the output should include the event’s key. In this case, this contains the row’s primary key.

```


## Verifying View change 
```shell    
#Updating the database and viewing the update event
UPDATE customers SET first_name='Anne Marie' WHERE id=1004;

#Deleting a record in the database and viewing the delete event
DELETE FROM customers WHERE id=1004;
```
   

   








   

   























