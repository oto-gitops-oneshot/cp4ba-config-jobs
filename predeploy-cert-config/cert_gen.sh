#!/bin/bash
set +e

TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
CP4BA_NAMESPACE="cp4ba"
oc_token=$(cat ${TOKEN_PATH}/token)
oc_server='https://kubernetes.default.svc'
oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"



# CA cert

oc project $CP4BA_NAMESPACE 


external_tls_secret_exists=$(oc get secret external-tls-secret -n cp4ba -o jsonpath='{.metadata.name}')
global_ca_exists=$(oc get secret global-ca -n cp4ba -o jsonpath='{.metadata.name}')
cp4ba_root_ca_exists=$(oc get secret cp4ba-root-ca -n cp4ba -o jsonpath='{.metadata.name}')

echo $external_tls_secret_exists
echo $global_ca_exists
echo $cp4ba_root_ca_exists


if [ "$external_tls_secret_exists" = "external-tls-secret" ] | [ "$global_ca_exists" = "global-ca" ] | [ "$cp4ba_root_ca_exists" = "cp4ba-root-ca" ]; then
    echo "A secret already exists. Please delete external-tls-secret, global-ca and cp4ba-root-ca in the $CP4BA_NAMESPACE namespace and run this job again."
    sleep 10 
    exit 0
else
    echo "creating certs dir"
    dir_path=certificates
    mkdir -p $dir_path
    chmod -R 777 $dir_path
    echo "generating ca"
    openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -days 36500 -nodes -x509 -subj "/CN='Global CA'" -keyout $dir_path/global-ca.key -out $dir_path/global-ca.crt

    # Wildcard cert
    domain=$(oc --namespace openshift-ingress-operator get ingresscontrollers -o jsonpath='{$.items[0].status.domain}')

    echo "generating wildcard cert for $domain"
    openssl genrsa -out $dir_path/wildcard.key 4096

    openssl req -new -key $dir_path/wildcard.key -subj "/CN='Global CA'" -addext "subjectAltName = DNS:*.$domain" -out $dir_path/wildcard.csr

    openssl x509 -req -days 36500 -in $dir_path/wildcard.csr -CA $dir_path/global-ca.crt -CAkey $dir_path/global-ca.key -out $dir_path/wildcard.crt

    chmod 777 -R $dir_path

    global_ca_cert=`cat $dir_path/global-ca.crt`
    global_ca_key=`cat $dir_path/global-ca.key`
    wildcard_cert=`cat $dir_path/wildcard.crt`
    wildcard_key=`cat $dir_path/wildcard.key`

    # oc create only runs if the secrets do not exist - i.e. if the secrets already exist things wont be created. 


    # create the global-ca secret
    oc create secret tls global-ca --cert=$dir_path/global-ca.crt --key=$dir_path/global-ca.key -n cp4ba

    # create the external-tls-secret
    oc create secret generic external-tls-secret --from-literal=cert.key="$wildcard_key" --from-literal=cert.crt="$wildcard_cert" --from-literal=tls.crt="$wildcard_cert" --from-literal=ca.crt="$global_ca_cert" -n cp4ba

    # create ht ecp4ba-root-ca
    oc create secret tls cp4ba-root-ca --cert=$dir_path/global-ca.crt --key=$dir_path/global-ca.key -n cp4ba

    # filesystem cleanup
    rm -rf $dir_path
fi


