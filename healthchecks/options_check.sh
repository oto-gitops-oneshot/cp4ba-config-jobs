#!/bin/bash

# simple healthcheck for options

# include pattern definitions
source ./patterns.sh

# include health check functions
source ./hc_functions.sh

# obtain deployed options
sc_optional_components=$($oc_path get ICP4ACluster icp4adeploy -o jsonpath='{.spec.shared_configuration.sc_optional_components}')

for component in ${sc_optional_components//,/ }
do
  for deploy_name in ${!component}
  do
    not_ready=$(isDeployReady $deploy_name)
    if [[ $not_ready ]]; then
      exit 1;
    fi
  done
done

