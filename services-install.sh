#!/usr/bin/env bash

export CLUSTER=$1

kubectl config use-context kind-$1

bash build-java-service.sh service1
bash build-java-service.sh service2

bash service-chart/install-service1.sh `cat service1/latest-image.id`
bash service-chart/install-service2.sh `cat service2/latest-image.id`

