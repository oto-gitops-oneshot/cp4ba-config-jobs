#!/bin/bash


NAMESPACE="cp4ba"
SLEEP_DURATION="30"

function isCartridgeReady {

   while [[ $(oc get Cartridge icp4ba -n $NAMESPACE -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]];
   do echo "waiting for Cartridge installation to complete" && sleep $SLEEP_DURATION;
   done

   echo "Cartridge Ready"
}



function isCRReady {

  while [[ $(oc get ICP4ACluster icp4adeploy -n $NAMESPACE -o 'jsonpath={..status.components.prereq.iafStatus}') != "Ready" ]];
  do echo "Waiting for iafStatus to be ready" && sleep $SLEEP_DURATION;
  done

  echo "iafStatus is Ready"


  while [[ $(oc get ICP4ACluster icp4adeploy -n $NAMESPACE -o 'jsonpath={..status.components.prereq.iamIntegrationStatus}') != "Ready" ]];
  do echo "Waiting for iamIntegrationStatus to be ready" && sleep $SLEEP_DURATION;
  done

  echo "iamIntgrationStatus is Ready"

  while [[ $(oc get ICP4ACluster icp4adeploy -n $NAMESPACE -o 'jsonpath={..status.components.prereq.rootCAStatus}') != "Ready" ]];
  do echo "Waiting for rootCAStatus to be ready" && sleep $SLEEP_DURATION;
  done

  echo "rootCAStatus is Ready"


}



function isRRReady {

  while [[ $(oc get ICP4ACluster icp4adeploy -n $NAMESPACE -o 'jsonpath={..status.components.resource-registry.rrCluster}') != "Ready" ]];
  do echo "Waiting for RRCluster to be ready" && sleep $SLEEP_DURATION;
  done
 
  echo "RRCluster is Ready"

  while [[ $(oc get ICP4ACluster icp4adeploy -n $NAMESPACE -o 'jsonpath={..status.components.resource-registry.rrService}') != "Ready" ]];
  do echo "Waiting for RRService to be ready" && sleep $SLEEP_DURATION;
  done

  echo "RRService is Ready"
}

echo "Health check - CP4BA Core Components Check Init....."

isCartridgeReady
isCRReady
isRRReady


echo "Health check - CP4BA Core Components Check Done"