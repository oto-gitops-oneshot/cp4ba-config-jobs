#!/bin/bash

source ./init_db.sh

echo "started"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
DB2_NAMESPACE="db2"
CP4BA_NAMESPACE="cp4ba"

echo "configuring db2"
set -e 

# fetches instancepassword secret and returns base64 encoded password
function fetch_db2_password {
    local DB2_SECRET=$(oc get secrets -n $DB2_NAMESPACE  | grep instancepassword | awk '{print $1}')
    echo "found secret $DB2_SECRET"
    DB2_PASSWORD=$(oc get secret -n $DB2_NAMESPACE $DB2_SECRET -o jsonpath='{..password}')
}

# patch value of secret when given secret name, key and new value
function patch_secret {
    local SECRET=$1
    local KEY=$2
    local NEW_VALUE=$3

    echo "patching secret: $SECRET key:$KEY"
    oc patch secret -n $CP4BA_NAMESPACE $SECRET --type='json' -p="[{\"op\": \"replace\", \"path\": \"$KEY\", \"value\":\"$NEW_VALUE\"}]"
}


function update_secrets {
    echo "fetching db2 instance password from db2 project: $DB2_NAMESPACE"
    fetch_db2_password
    echo "starting secret patch in namespace: $CP4BA_NAMESPACE"
    patch_secret ibm-fncm-secret /data/gcdDBPassword $DB2_PASSWORD
    patch_secret ibm-fncm-secret /data/os1DBPassword $DB2_PASSWORD
    patch_secret ibm-fncm-secret /data/os2DBPassword $DB2_PASSWORD
    patch_secret ibm-ban-secret /data/navigatorDBPassword $DB2_PASSWORD
    patch_secret ibm-dba-ums-secret /data/oauthDBPassword $DB2_PASSWORD
    patch_secret ibm-dba-ums-secret /data/tsDBPassword $DB2_PASSWORD
    echo "complete!"
}

function seed_databases {
    cat $execstr > /tmp/commands
    DB2_COMMANDS="/tmp/commands"
    
    echo "setting project to $DB2_NAMESPACE" && echo
    oc project $DB2_NAMESPACE

    echo "Identifying DB2 pod" && echo
    DB2_POD_NAME=$(oc get pod -l role=db -ojsonpath='{.items[0].metadata.name}')

    echo "Listing current databases on pod $DB2_POD_NAME" && echo
    oc exec $DB2_POD_NAME -c db2u -- su - db2inst1 -c "db2 list database directory"

    echo "Starting database creation on pod $DB2_POD_NAME" && echo
    oc cp $DB2_COMMANDS $DB2_POD_NAME:/tmp/$DB2_COMMANDS -c db2u
    oc exec $DB2_POD_NAME -it -c db2u -- chmod +rwx /tmp/$DB2_COMMANDS
    oc exec $DB2_POD_NAME -it -c db2u -- su - db2inst1 -c "nohup /tmp/$DB2_COMMANDS &"

    echo "Database setup in progress" && echo
    echo "To list the databases, run:"
    echo "oc exec $DB2_POD_NAME -c db2u -- su - db2inst1 -c \"db2 list database directory\""
}

while getopts ":i:" opt; do
  case $opt in
    i)
      set -f; IFS=','
      argv=($2)
      argc=${#argv[@]}
      echo "Total Number of databases to initialise = $argc" >&2
      echo -n "Requested databases: "
      for i in "${argv[@]}"; do
        echo -n "$i "
      done
      echo ""

      oc_token=$(cat ${TOKEN_PATH}/token)
      oc_server='https://kubernetes.default.svc'
      oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"
      # echo "Updating secrets"
      # update_secrets

      for i in "${argv[@]}"; do
        if [[ $supported_databases =~ (^|[[:space:]])$i($|[[:space:]]) ]];  then
          # spit create db commands to stdout and capture them into a variable
          execstr=$(init_${i}_db);
          echo "Executing create DB commands for $i: ";
          echo $execstr;
          seed_databases
        else
          echo "Initialisation of database $i is not yet supported"
        fi
      done
      
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
