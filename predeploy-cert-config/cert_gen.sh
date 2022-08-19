#!/bin/bash
set +e

TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
CP4BA_NAMESPACE="cp4ba"
oc_token=$(cat ${TOKEN_PATH}/token)
oc_server='https://kubernetes.default.svc'
oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"


echo "creating certs dir"
dir_path=/tmp/certs
#mkdir -p $dir_path
# chmod -R 777 certs
# CA cert

oc project $CP4BA_NAMESPACE 
echo "generating ca"
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -days 36500 -nodes -x509 -subj "/CN='Global CA'" -keyout $dir_path/global-ca.key -out $dir_path/global-ca.crt

# Wildcard cert
domain=$(oc --namespace openshift-ingress-operator get ingresscontrollers -o jsonpath='{$.items[0].status.domain}')

echo "generating wildcard cert for $domain"
openssl genrsa -out $dir_path/wildcard.key 4096

openssl req -new -key $dir_path/wildcard.key -subj "/CN='Global CA'" -addext "subjectAltName = DNS:*.$domain" -out $dir_path/wildcard.csr

openssl x509 -req -days 36500 -in $dir_path/wildcard.csr -CA $dir_path/global-ca.crt -CAkey $dir_path/global-ca.key -out $dir_path/wildcard.crt

chmod 777 -R /tmp/certs

global_ca_cert=$`cat $dir_path/global-ca.crt`
global_ca_key=`cat $dir_path/global-ca.key`
wildcard_cert=`cat $dir_path/wildcard.crt`
wildcard_key=`cat $dir_path/wildcard.key`

# echo "kind: Secret
# apiVersion: v1
# metadata:
#   name: external-tls-secret
#   namespace: cp4ba
# stringData:
#   cert.key: "$wildcard_key"
#   cert.crt: "$wildcard_cert"
#   tls.crt:  "$wildcard_cert"
#   ca.crt:   "$global_ca_cert"
# type: Opaque"  > /tmp/external_tls_cert.yaml
# oc apply -f /tmp/external_tls_cert.yaml
oc create secret tls global-ca --cert=$dir_path/global-ca.crt --key=$dir_path/global-ca.key -n cp4ba

oc create secret generic external-tls-secret --from-literal=cert.key="$wildcard_key" --from-literal="cert.crt=$wildcard_cert" --from-literal=tls.crt="$wildcard_cert" --from-literal=ca.crt="$global_ca_cert" -n cp4ba


oc create secret tls cp4ba-root-ca --cert=$dir_path/global-ca.crt --key=$dir_path/global-ca.key -n cp4ba

# echo "kind: Secret
# apiVersion: v1
# metadata:
#   name: cp4ba-root-ca
#   namespace: cp4ba
# stringData:
#   tls.key: "$global_ca_key"
#   tls.crt: "$global_ca_cert"
# " > /tmp/cp4ba_root_ca.yaml
# oc apply -f /tmp/cp4ba_root_ca.yaml