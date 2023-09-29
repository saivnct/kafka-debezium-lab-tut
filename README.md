## ***[Giangbb Studio]*** 
# **Kafka - Debezium CDC Labs**

## **Introduction to Debezium**

Debezium is a set of distributed services that capture changes in your databases. Your applications can consume and respond to those changes. Debezium captures each row-level change in each database table in a change event record and streams these records to Kafka topics. Applications read these streams, which provide the change event records in the same order in which they were generated.

Debezium is built on top of Apache Kafka and provides a set of Kafka Connect compatible connectors. By taking advantage of Kafka’s reliable streaming platform, Debezium makes it possible for applications to consume changes that occur in a database correctly and completely. Even if your application stops unexpectedly, or loses its connection, it does not miss events that occur during the outage. After the application restarts, it resumes reading from the topic from the point where it left off.

## **Table of contents**

1. [Debezium CDC Mysql Basic Demo](1-tut-debezium-basic-mysql-connector.md)
2. [Debezium CDC MongoDB Demo](2-tut-debezium-basic-mongo-connector.md)
3. [Debezium CDC Unwrap MongoDB SMT  - Postgres Data warehouse demo](3-tut-debezium-src-mongo-sink-postgres.md)
4. [Debezium CDC MongoDB - MongoDB warehouse demo](4-tut-debezium-src-mongo-sink-mongo.md)
5. [Debezium CDC Unwrap MySQL SMT - Elasticsearch sink connector demo](5-tut-debezium-src-mysql-sink-elasticsearch.md)
6. [Debezium CDC Unwrap Postgres SMT  - Elasticsearch sink connector demo](6-tut-debezium-src-postgres-sink-elasticsearch.md)
7. [Debezium CDC Unwrap MongoDB SMT  - Elasticsearch sink connector demo](7-tut-debezium-src-mongo-sink-elasticsearch.md)