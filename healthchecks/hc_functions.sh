#!/bin/bash

## Library to emulate Ansible-style unconditional health checks for CP4BA resources post-deployment
## Functions return 0 if all requested resources are Ready or 1 if not all requested resources are ready (and does not elaborate which and why)

# arguments:
# <$1>,<$2>
# $1: Resource type. Currently supported: Cartridge, ICP4ACluster, RR or Deploy
# $2: Resource name (deployment name or its substring, not required for RR)

supported_types="Cartridge ICP4ACluster RR Deploy"
oc_path="oc"
cp4ba_namespace="cp4ba"

function isCartridgeReady () {
  # Returns:
  # 0 if the condition is met
  # 1 all other cases (including wrong resource name, kind and any other problems)

  state=""

  for try in {36..1}
  do
    command="$oc_path get Cartridge $1 -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}'"
    state=$(eval $command)

    if [[ $state =~ "True" ]]; then
      # echo The resource is up;
      return 0;
    else
      # echo "The resource is not up"
      sleep 300;
    fi
  done

  if [[ $state =~ "True" ]]; then
    # echo The resource is up;
    return 0;
  else
    # echo "The resource is not up"
    return 1;
  fi
}

function isICP4AClusterReady () {
  # Returns:
  # 0 if the condition is met
  # 1 all other cases (including wrong resource name, kind and any other problems)

  iafStatus=""
  iamIntegrationStatus=""
  rootCAStatus=""

  # echo "Parameters: $1"
  for try in {30..1}
  do
    iafStatus=$($oc_path get ICP4ACluster $1 -o jsonpath='{.status.components.prereq.iafStatus}')
    iamIntegrationStatus=$($oc_path get ICP4ACluster $1 -o jsonpath='{.status.components.prereq.iamIntegrationStatus}')
    rootCAStatus=$($oc_path get ICP4ACluster $1 -o jsonpath='{.status.components.prereq.rootCAStatus}')

    if [[ $iafStatus =~ "Ready" ]] && [[ $iamIntegrationStatus =~ "Ready" ]] && [[ $rootCAStatus =~ "Ready" ]]; then
      # echo The resource is up;
      return 0;
    else
      # echo "The resource is not up"
      sleep 120;
    fi
  done

  if [[ $iafStatus =~ "Ready" ]] && [[ $iamIntegrationStatus =~ "Ready" ]] && [[ $rootCAStatus =~ "Ready" ]]; then
    # echo The resource is up;
    return 0;
  else
    # echo "The resource is not up"
    return 1;
  fi

}

function isRRReady () {
  # Returns:
  # 0 if the condition is met
  # 1 all other cases (including wrong resource name, kind and any other problems)
  # there is no parameters to this function as we just making sure all three pods are up

  up_count=0;

  for try in {30..1}
  do
    command="$oc_path get pods -l app.kubernetes.io/component=etcd-server -n $cp4ba_namespace -o 'jsonpath={..status.conditions[?(@.type==\"Ready\")].status}'| wc -w";
    up_count=$(eval $command);
    if [[ ! $up_count -eq 3 ]]; then
      sleep 120;
    else
      return 0;
    fi
  done

  if [[ $up_count -eq 3 ]]; then
    # echo The resource is up;
    return 0;
  else
    # echo "The resource is not up"
    return 1;
  fi
}

function isDeployReady (){
  # Returns:
  # 0 if the condition is met
  # 1 all other cases (including wrong resource name, kind and any other problems)
  # needs deployment name to look up its status
  # 
  # echo "Parameters: $1"

  deploy_state=""

  for try in {30..1}
  do
    command="$oc_path get deploy | awk '{if (\$1 ~ \"$1\") print \$1}'"
    deploy_name=$(eval $command)

    if [[ $deploy_name ]]; then
      command="$oc_path get deploy $deploy_name -o jsonpath='{.status.conditions[?(@.type==\"Available\")].status}'";
      deploy_state=$(eval $command);
      
      if [[ $deploy_state =~ "True" ]]; then
        # echo "The deployment is available";
        return 0;
      else
        # echo "The deployment exists but not yet Available";
        sleep 120;
      fi
    else
      # echo "The deployment does not exist"
      sleep 120;
    fi
  done

  if [[ $deploy_state =~ "True" ]]; then
    # echo "The deployment is available";
    return 0;
  else
    # echo "The deployment not yet Available or does not exist";
    return 1;
  fi

}

