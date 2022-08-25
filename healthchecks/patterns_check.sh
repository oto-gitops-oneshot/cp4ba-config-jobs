#!/bin/bash

# simple healthcheck for patterns

# include pattern definitions
source ./patterns.sh

# include health check functions
source ./hc_functions.sh

# obtain deployed patterns
sc_deployment_patterns=$($oc_path get ICP4ACluster icp4adeploy -o jsonpath='{.spec.shared_configuration.sc_deployment_patterns}')

for pattern in ${sc_deployment_patterns//,/ }
do
    #  .. ignore the foundation pattern
    if [[ ! $pattern =~ "foundation" ]]; then
      for deploy in ${!pattern}
      do
        not_ready=$(isDeployReady $deploy)
        if [[ $not_ready ]]; then
          exit 1;
        fi
      done
    fi
done

