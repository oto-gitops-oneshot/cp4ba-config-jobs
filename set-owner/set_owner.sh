#!/bin/bash

## Script to patch CP4BA resources as defined in the static list with ownership information if it's not specified already
oc_path="oc"

# check if we have a list of resources to work on
if [[ ! -e resources.txt ]]; then
  echo "Please define a list of resources to set ownership for in resources.txt";
  exit 1;
fi

# populate the list of resources
resources=$(cat resources.txt)

# get UID of the CP4BA cluster Resource
cp4ba_uid=$($oc_path get ICP4ACluster icp4adeploy -o jsonpath='{.metadata.uid}')

# obtain all resources and their types from the namespace
all_resources=`oc get $(oc api-resources --namespaced=true --verbs=list -o name | awk '{printf "%s%s",sep,$0;sep=","}')  --ignore-not-found -n cp4ba -o=custom-columns=KIND:.kind,NAME:.metadata.name --sort-by='kind' --no-headers`

for resource_name in $resources
do

  # get resource type and also check if it is present in the cluster
  resource_type=$(echo "$all_resources" | grep $resource_name | awk '{print $1}')
  if [ $resource_type ]; then
    resource_owners=$($oc_path get $resource_type $resource_name -o jsonpath='{.metadata.ownerReferences}');

    # only add resource owner reference to those resources that don't have owner already
    if [ -z "$resource_owners" ]; then
      echo "Patching resource with type: " $resource_type " and name: " $resource_name;
      patch=$(echo oc patch $resource_type $resource_name --patch "'{ \"metadata\":{\"ownerReferences\": [ {\"apiVersion\": \"icp4a.ibm.com/v1\", \"kind\": \"ICP4ACluster\", \"name\": \"icp4adeploy\", \"uid\": \"${cp4ba_uid}\" } ]}}'");
      eval $patch;
    else
      echo "There is an owner already for " $resource_name;
    fi
  else
    echo $resource_name " is not found in the cluster"
  fi
done
