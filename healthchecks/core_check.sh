#!/bin/bash

# simple healthcheck for core functions: RR, Cartridge and ICP4ACluster

# include health check functions
source ./hc_functions.sh

cartridge_not_ready=$(isCartridgeReady icp4ba)
icp4a_cluster_not_ready=$(isICP4AClusterReady icp4adeploy)
rr_not_ready=$(isRRReady)

if [[ $cartridge_not_ready || $icp4a_cluster_not_ready || $rr_not_ready ]]; then
  exit 1;
else
  exit 0;
fi