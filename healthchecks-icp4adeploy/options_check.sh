#!/bin/bash

SLEEP_DURATION=30
NAMESPACE=cp4ba

function isDeployReady {

  sc_optional_components=$(oc get ICP4ACluster icp4adeploy -n cp4ba -o jsonpath='{.spec.shared_configuration.sc_optional_components}')
  for component in ${sc_optional_components//,/ }
  do
    deployment=$(oc get deploy -n cp4ba | grep $component | tail -n 1 | awk '{print $1;}') 
    echo "Checking on ${deployment} status"
    while [[ $(oc get deploy $deployment -n $NAMESPACE -o 'jsonpath={..status.conditions[?(@.type=="Available")].status}') != "True" ]];
    do echo "waiting for Deployment to complete" && sleep $SLEEP_DURATION;
    done
    echo "${deployment} is ready"
  done

}

echo "Checking optional components..."

isDeployReady