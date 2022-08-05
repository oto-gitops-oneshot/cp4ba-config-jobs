#!/bin/sh

set -e

DB2_PROJECT="db2"
DB2_COMMANDS=db2-cmd.sh

echo "setting project to $DB2_PROJECT" && echo
oc project $DB2_PROJECT

echo "Identifying DB2 pod" && echo
DB2_POD_NAME=$(oc get pod -l role=db -ojsonpath='{.items[0].metadata.name}')

echo "Listing current databases on pod $DB2_POD_NAME" && echo
oc exec $DB2_POD_NAME -c db2u -- su - db2inst1 -c "db2 list database directory"

echo "Starting database creation on pod $DB2_POD_NAME" && echo
oc cp $DB2_COMMANDS $DB2_POD_NAME:/tmp/$DB2_COMMANDS -c db2u
oc exec $DB2_POD_NAME -it -c db2u -- chmod +x tmp/$DB2_COMMANDS
oc exec $DB2_POD_NAME -it -c db2u -- su - db2inst1 -c "nohup /tmp/$DB2_COMMANDS &"

echo "Database setup in progress" && echo
echo "To view the log, run:"
echo "oc exec $DB2_POD_NAME -c db2u -- su - db2inst1 -c \"tail -f /tmp/filenet-db2-setup.log\""
echo "To list the databases, run:"
echo "oc exec $DB2_POD_NAME -c db2u -- su - db2inst1 -c \"db2 list database directory\""
