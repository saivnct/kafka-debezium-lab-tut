ARG DEBEZIUM_VERSION
FROM quay.io/debezium/connect:${DEBEZIUM_VERSION}
ENV KAFKA_CONNECT_MONGO_DIR=$KAFKA_CONNECT_PLUGINS_DIR/kafka-connect-mongo

RUN mkdir $KAFKA_CONNECT_MONGO_DIR

COPY --chown=kafka ../giangbb-modver-mongo-kafka-connect-1.12.0-confluent.jar $KAFKA_CONNECT_MONGO_DIR/mongo-kafka-connect-1.12.0-confluent.jar
