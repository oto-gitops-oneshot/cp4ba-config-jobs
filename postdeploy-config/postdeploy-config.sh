#!/bin/bash

#POSTDEPLOY_CONFIG_LIST="ZEN,IER,TM"
# script will take a list of services as args or env variable (i.e. ZEN,IER,IER-TM) and perform the relevant jobs specified in apollo 
# reference the trello for specific tasks relevant to this project
source ./services.sh

# set +e so the job executes without failing and doesnt hold up future sync waves
set +e 

echo "started post deploy config"
 ### OPENSHIFT ###
CP4BA_PROJECT_NAME="cp4ba"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
oc_token=$(cat ${TOKEN_PATH}/token)
oc_server='https://kubernetes.default.svc'
oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"


oc project $CP4BA_PROJECT_NAME

function postdeploy_config {
  echo "getting postdeploy components"
  POSTDEPLOY_CONFIG_LIST=$(oc get icp4acluster icp4adeploy -o jsonpath='{.spec.shared_configuration.sc_optional_components}' -n $CP4BA_PROJECT_NAME)


  # postdeploy services we want to configure - 
  echo "performing post deploy tasks for $POSTDEPLOY_CONFIG_LIST"

  ier=false
  tm=false 
  # we always configure zen - the other serivces will depend on what is in postdeploy config list 
  configure_zen

  if [ -z "$POSTDEPLOY_CONFIG_LIST" ]
  then 
    echo "config list empty" 
  
  else 
    for item in ${POSTDEPLOY_CONFIG_LIST//,/ }
    do 
        case $item in
            ier) 
                configure_ier
                ier=true
                
                ;;
            tm) 
                configure_tm
                tm=true
                ;;
            *)
                echo "Service not yet configured. Please modify bash script or check arguments"
                ;;
        esac
    done

  fi
  # if both ier and tm are true then we must do extra configuration 
  if [ $ier = true ] && [ $tm = true ] ; then
    configure_ier_tm
  fi 
    
}

postdeploy_config