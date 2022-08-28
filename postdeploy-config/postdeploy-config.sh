#!/bin/bash
POSTDEPLOY_CONFIG_LIST="IER"
# script will take a list of services as args or env variable (i.e. ZEN,IER,IER-TM) and perform the relevant jobs specified in apollo 
# reference the trello for specific tasks relevant to this project
source ./services.sh

echo "started post deploy config"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
 ### OPENSHIFT ###
CP4BA_PROJECT_NAME="cp4ba"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
oc_token=$(cat ${TOKEN_PATH}/token)
oc_server='https://kubernetes.default.svc'
oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"

# set +e so the job executes without failing and doesnt hold up future sync waves
set +e 

function postdeploy_config {
    # postdeploy services we want to configure - 
  echo "performing post deploy tasks for $POSTDEPLOY_CONFIG_LIST"
  if [ -z "$POSTDEPLOY_CONFIG_LIST" ]
  then 
    echo "config list empty" 
   
  else 
    for item in ${POSTDEPLOY_CONFIG_LIST//,/ }
    do 
        case $item in

            ZEN)
                configure_zen
                ;;
            IER) 
                configure_ier
                
                ;;
            TM) 
                configure_ier_tm
                
                ;;
            *)
                echo "Service not yet configured. Please modify bash script or check arguments"
                ;;
        esac
    done

  fi
    
}

postdeploy_config