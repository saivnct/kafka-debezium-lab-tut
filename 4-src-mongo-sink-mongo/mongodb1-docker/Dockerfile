FROM mongo:5

COPY ../etc/mongo /etc/mongo
COPY ../opt/mongodb /opt/mongodb

RUN chmod 400 /opt/mongodb/mongo-keyfile \
    && chown mongodb:mongodb /opt/mongodb/mongo-keyfile

CMD ["mongod", "--config", "/etc/mongo/mongod.conf","--auth", "--keyFile", "/opt/mongodb/mongo-keyfile", "--replSet","rs1"]