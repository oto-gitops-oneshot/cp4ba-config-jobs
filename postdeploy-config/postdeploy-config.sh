#!/bin/bash

# script will take a list of services as args or env variable (i.e. ZEN,IER,IER-TM) and perform the relevant jobs specified in apollo 
# reference the trello for specific tasks relevant to this project
source ./services.sh

echo "started post deploy config"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
CP4BA_NAMESPACE="cp4ba"


# set +e so the job executes without failing and doesnt hold up future sync waves
set +e 

function postdeploy_config {
    # postdeploy services we want to configure - 
  echo "performing post deploy tasks for $POSTDEPLOY_CONFIG_LIST"
  if [ -z "$POSTDEPLOY_CONFIG_LIST" ]
  then 
    echo "config list empty" 
   
  else 
    echo $POSTDEPLOY_CONFIG_LIST
    for item in ${POSTDEPLOY_CONFIG_LIST//,/ }
    do 
        case $item in

            ZEN)
                configure_zen
                ;;
            IER) 
                configure_ier
                
                ;;
            IER-TM) 
                configure_ier_tm
                
                ;;
            TM) 
                configure_tm
                ;;
            *)
                echo "service not yet configured. Please modify bash script or check arguments"
                ;;
        esac
    done

  fi
    
}

postdeploy_config