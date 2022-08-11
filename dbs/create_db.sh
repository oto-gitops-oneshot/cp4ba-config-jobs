#!/bin/bash

supported_databases='IER FNCM BAN'
source ./init_db.sh

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
  
      for i in "${argv[@]}"; do
        if [[ $supported_databases =~ (^|[[:space:]])$i($|[[:space:]]) ]];  then
          # spit create db commands to stdout
          init_db $i
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
