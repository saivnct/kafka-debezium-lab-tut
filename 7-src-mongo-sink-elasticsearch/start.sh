#!/usr/bin/env bash
export DEBEZIUM_VERSION=2.3
docker-compose down
docker-compose up -d
docker-compose logs -f connect