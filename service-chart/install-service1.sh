#!/bin/bash

cd $(dirname $0)

helm upgrade -i service1 . --values values-service1.yaml --set image.tag=$1
