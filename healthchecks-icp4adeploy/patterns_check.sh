#!/bin/bash


SLEEP_DURATION=30
NAMESPACE=cp4ba

CONTENT="cpe"

function isDeployReady {

  sc_patterns=$(oc get ICP4ACluster icp4adeploy -n cp4ba -o jsonpath='{.spec.shared_configuration.sc_deployment_patterns}')
  for pattern in ${sc_patterns//,/ }
  do
    if [[ ! $pattern =~ "foundation" ]]; then
      local capability
      if [ $pattern == "content" ]; then
         capability="cpe"
      fi
      while [[ deployment=$(oc get deploy -n cp4ba | grep $capability | tail -n 1 | awk '{print $1;}') != *"${capability}-deploy"* ]];
      do echo "Waiting on deployment for component ${capability} to start up" && sleep $SLEEP_DURATION;
      done
      deployment=$(oc get deploy -n cp4ba | grep $capability | tail -n 1 | awk '{print $1;}') 
      echo "Checking on ${deployment} status"
      while [[ $(oc get deploy $deployment -n $NAMESPACE -o 'jsonpath={..status.conditions[?(@.type=="Available")].status}') != "True" ]];
      do echo "waiting for Deployment to complete" && sleep $SLEEP_DURATION;
      done
      echo "${deployment} is ready"
    fi
  done

}

echo "Checking optional components..."

isDeployReady