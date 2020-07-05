#!/bin/bash

cd $(dirname $0)

helm upgrade -i service2 . --values values-service2.yaml --set image.tag=$1
