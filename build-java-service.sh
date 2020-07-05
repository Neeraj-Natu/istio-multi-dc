#!/usr/bin/env bash
pushd $(dirname $0)/$1
mvn -q compile com.google.cloud.tools:jib-maven-plugin:2.4.0:dockerBuild \
  -Djib.container.workingDirectory=/app \
  -Djib.to.image=$1:latest

IMAGE_ID=$(docker images $1:latest --format "{{.ID}}")
echo $IMAGE_ID > latest-image.id
popd

docker tag $1:latest $1:$IMAGE_ID
kind load docker-image $1:$IMAGE_ID --name $CLUSTER
