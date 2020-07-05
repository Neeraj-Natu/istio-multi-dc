#!/usr/bin/env bash

DC=$1
LB_IP_RANGE=$2

cd $(dirname $0)

bash keys/intermediate.sh $DC
bash keys/cert.sh $DC dashboard

mkdir -p instance
cp *.yaml instance

mkdir -p instance/dashboard-secrets
cp keys/$DC/dashboard-cert.pem instance/dashboard-secrets/tls.crt
cp keys/$DC/dashboard-key.pem instance/dashboard-secrets/tls.key

mkdir -p instance/istio-secrets
cp keys/${DC}/ca-cert.pem instance/istio-secrets/ca-cert.pem
cp keys/${DC}/ca-key.pem instance/istio-secrets/ca-key.pem
cp keys/${DC}/root-cert.pem instance/istio-secrets/root-cert.pem
cp keys/${DC}/cert-chain.pem instance/istio-secrets/cert-chain.pem

cd instance

sed -s "s/LB_IP_RANGE/$LB_IP_RANGE/g" -i dashboard.yaml
sed -s "s/LB_IP_RANGE/$LB_IP_RANGE/g" -i metallb-config.yaml
sed -s "s/LB_IP_RANGE/$LB_IP_RANGE/g" -i values-istio.yaml

kind create cluster --name $DC --config cluster.yaml
kubectl config use-context "kind-$DC"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f metallb-config.yaml

kubectl apply -f dashboard.yaml
kubectl create secret generic kubernetes-dashboard-certs --namespace kubernetes-dashboard --from-file=dashboard-secrets

kubectl apply -f admin-user.yaml
echo "Secret:"
kubectl get -n kube-system  `kubectl get secret -n kube-system  -o name | grep admin-token` -o jsonpath="{.data.token}" | base64 -d | tee ../keys/token-$DC.key
echo

kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system --from-file=../certs

istioctl install -f values-istio.yaml

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    global:53 {
        errors
        cache 30
        forward . $(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP}):53
    }
EOF

kubectl delete envoyfilter istio-multicluster-ingressgateway -n istio-system

export ADMIRAL_HOME=../../admiral-install-v0.9

kubectl create namespace admiral
kubectl apply -f $ADMIRAL_HOME/yaml/remotecluster.yaml
kubectl apply -f $ADMIRAL_HOME/yaml/demosinglecluster.yaml
kubectl rollout status deployment admiral -n admiral

kubectl label namespace default istio-injection=enabled

for node in `kubectl get nodes -o name`; do
  kubectl label --overwrite $node failure-domain.beta.kubernetes.io/region=kind-$DC
done

cd ..
rm -rf instance
