ARG DEBEZIUM_VERSION
FROM quay.io/debezium/connect:${DEBEZIUM_VERSION}
ENV KAFKA_CONNECT_ES_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-elasticsearch

# Deploy Confluent Elasticsearch sink connector
RUN mkdir $KAFKA_CONNECT_ES_DIR && cd $KAFKA_CONNECT_ES_DIR
COPY kafka-connect-elasticsearch $KAFKA_CONNECT_ES_DIR

#ARG KAFKA_ELASTICSEARCH_VERSION=10.0.0
#
## Deploy Confluent Elasticsearch sink connector
#RUN mkdir $KAFKA_CONNECT_ES_DIR && cd $KAFKA_CONNECT_ES_DIR &&\
#        curl -sO https://packages.confluent.io/maven/io/confluent/kafka-connect-elasticsearch/$KAFKA_ELASTICSEARCH_VERSION/kafka-connect-elasticsearch-$KAFKA_ELASTICSEARCH_VERSION.jar && \
#        curl -sO https://repo1.maven.org/maven2/io/searchbox/jest/6.3.1/jest-6.3.1.jar && \
#        curl -sO https://repo1.maven.org/maven2/org/apache/httpcomponents/httpcore-nio/4.4.4/httpcore-nio-4.4.4.jar && \
#        curl -sO https://repo1.maven.org/maven2/org/apache/httpcomponents/httpclient/4.5.1/httpclient-4.5.1.jar && \
#        curl -sO https://repo1.maven.org/maven2/org/apache/httpcomponents/httpasyncclient/4.1.1/httpasyncclient-4.1.1.jar && \
#        curl -sO https://repo1.maven.org/maven2/org/apache/httpcomponents/httpcore/4.4.4/httpcore-4.4.4.jar && \
#        curl -sO https://repo1.maven.org/maven2/commons-logging/commons-logging/1.2/commons-logging-1.2.jar && \
#        curl -sO https://repo1.maven.org/maven2/commons-codec/commons-codec/1.9/commons-codec-1.9.jar && \
#        curl -sO https://repo1.maven.org/maven2/org/apache/httpcomponents/httpcore/4.4.4/httpcore-4.4.4.jar && \
#        curl -sO https://repo1.maven.org/maven2/io/searchbox/jest-common/6.3.1/jest-common-6.3.1.jar && \
#        curl -sO https://repo1.maven.org/maven2/com/google/code/gson/gson/2.8.6/gson-2.8.6.jar && \
#        curl -sO https://repo1.maven.org/maven2/com/google/guava/guava/20.0/guava-20.0.jar
