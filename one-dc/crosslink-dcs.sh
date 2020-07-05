#!/usr/bin/env bash

cd $(dirname $0)

if [ "$#" -gt "0" ]; then
  local_cluster=kind-$1
fi

if [ "$#" -gt "1" ]; then
  remote_cluster=kind-$2
fi

#prep for creating kubeconfig of remote cluster
export WORK_DIR=$(pwd)
CLUSTER_NAME=$(kubectl config view --minify=true --context $remote_cluster -o "jsonpath={.clusters[].name}")
export KUBECFG_FILE=/tmp/${CLUSTER_NAME}
#SERVER=$(kubectl config view --minify=true --context $remote_cluster -o "jsonpath={.clusters[].cluster.server}")
SERVER=https://$(kubectl get pods -n kube-system --context $remote_cluster kube-apiserver-$2-control-plane -o 'jsonpath={.metadata.annotations.kubeadm\.kubernetes\.io/kube-apiserver\.advertise-address\.endpoint}')
NAMESPACE_SYNC=admiral-sync
SERVICE_ACCOUNT=admiral
SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} --context $remote_cluster -n ${NAMESPACE_SYNC} -o jsonpath='{.secrets[].name}')
CA_DATA=$(kubectl get secret ${SECRET_NAME} --context $remote_cluster -n ${NAMESPACE_SYNC} -o "jsonpath={.data['ca\.crt']}")
RAW_TOKEN=$(kubectl get secret ${SECRET_NAME} --context $remote_cluster -n ${NAMESPACE_SYNC} -o "jsonpath={.data['token']}")
TOKEN=$(kubectl get secret ${SECRET_NAME} --context $remote_cluster -n ${NAMESPACE_SYNC} -o "jsonpath={.data['token']}" | base64 --decode)

cat <<EOF > kind-$2
apiVersion: v1
clusters:
   - cluster:
       certificate-authority-data: ${CA_DATA}
       server: ${SERVER}
     name: ${CLUSTER_NAME}
contexts:
   - context:
       cluster: ${CLUSTER_NAME}
       user: ${CLUSTER_NAME}
     name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
   - name: ${CLUSTER_NAME}
     user:
       token: ${TOKEN}
EOF

cat kubeconfig

kubectl config use-context $local_cluster

kubectl delete secret ${CLUSTER_NAME} -n admiral
kubectl create secret generic ${CLUSTER_NAME} --from-file kind-$2 -n admiral
kubectl label secret ${CLUSTER_NAME} admiral/sync=true -n admiral

rm kind-$2