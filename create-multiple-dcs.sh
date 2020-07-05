#!/usr/bin/env bash

bash one-dc/create-one-dc.sh dc1 172.18.200
bash one-dc/create-one-dc.sh dc2 172.18.201

bash one-dc/crosslink-dcs.sh dc1 dc2
bash one-dc/crosslink-dcs.sh dc2 dc1

bash services-install.sh dc1
bash services-install.sh dc2
