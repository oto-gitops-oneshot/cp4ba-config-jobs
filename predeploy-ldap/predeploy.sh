#!/bin/bash

set +e

function login {
  echo "Logging on..."
  TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
  CACERT=${TOKEN_PATH}/ca.crt
  oc_token=$(cat ${TOKEN_PATH}/token)
  oc_server='https://kubernetes.default.svc'
  oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"
  echo "Logging on complete"
}


function configmap {
  cp4ba_project_name="cp4ba"
  openldap_project_name="openldap"
  sleep 300
  password=$(oc get secret universal-password -n $cp4ba_project_name -o jsonpath='{.data.universalPassword}' | base64 --decode)
  # sed -i'.bak' -e "s/REPLACEME/$password/g" /tmp/cm.yaml
  sed  -e "s/REPLACEME/$password/g" /tmp/cm.yaml > /tmp/configmap.yaml
  oc delete configmap openldap-customldif -n $openldap_project_name
  oc create -f /tmp/configmap.yaml -n $openldap_project_name
  echo "ConfigMap created successfully"
}


login
configmap
