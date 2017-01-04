FROM landoop/fast-data-dev:latest
MAINTAINER Marios Andreopoulos <marios@landoop.com>

WORKDIR /

RUN apk add --no-cache openjdk8-jre-base

ENV SBT_OPTS="-Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled"
RUN apk add --no-cache git wget \
    && wget https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.13/sbt-launch.jar \
    \
    && git clone https://github.com/Landoop/fast-data-backend.git /fast-data-backend \
    && cd /fast-data-backend \
    && git checkout demo-api-for-topics-ui \
    && java $SBT_OPTS -jar /sbt-launch.jar assembly \
    && mv /fast-data-backend/target/scala-2.11/fast.data.kcql.service-assembly-1.0.jar / \
    && cd / \
    && git clone https://github.com/Landoop/blogs-code-examples.git /blogs-code-examples \
    && cd /blogs-code-examples/avro-kafka-generator \
    && git checkout demo-chart-generate-data \
    && java $SBT_OPTS -jar /sbt-launch.jar assembly \
    && mv target/scala-2.11/avro-kafka-generator-assembly-1.0.jar /avro-kafka-generator-assembly-1.0.jar \
    && cd / \
    \
    && rm -rf /sbt-launch.jar /root/.sbt /root/.ivy2 rm -rf /fast-data-backend /blogs-code-examples \
    && apk --no-cache del git wget

RUN mkdir /etc/supervisor.d/ \
    && echo "[include]" >> /etc/supervisord.conf \
    && echo 'files = /etc/supervisor.d/*.ini' >> /etc/supervisord.conf

ADD backend.ini /etc/supervisor.d/
ADD generator.ini /etc/supervisor.d/
RUN mv /var/www/kafka-topics-ui/env.js /temp.env.js \
    && rm -rf /var/www/kafka-topics-ui/*
ADD kafka-topics-ui-demo.tar.gz /var/www/kafka-topics-ui
RUN sed -e 's/localhost:8080/cloudera03.landoop.com:16885/g' -i /var/www/kafka-topics-ui/combined.js \
    && mv /temp.env.js /var/www/kafka-topics-ui/env.js
ENV FORWARDLOGS=0 RUNTESTS=0
