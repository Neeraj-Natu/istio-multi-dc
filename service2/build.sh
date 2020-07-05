#!/usr/bin/env bash
cd $(dirname $0)
mvn spring-boot:build-image
docker tag docker.io/library/service2:1.0.0-SNAPSHOT service2:1
kind load docker-image service2:1 --name k8s-cluster
