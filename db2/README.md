# DB2 Configuration Job

Link to Original DB2 deployment in Apollo Repository: [Apollo DB2 scripts](https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tree/main/scripts/roles/db2)


# Components 


* Configuring DB2 intiially is a prerequisite step to performing dbs config [here](https://)
* This db2 job is the third step in the predeploy phase for cp4ba - the two previous being a job to deploy a global ca, and an argo app to create instances of secrets using external secrets.


This DB2 Job consists of two shell scripts, a Dockerfile to build an image and a yaml Jobspec. 
* The Dockerfile makes use of the OpenShift origin CLI - an earlier version of the CLI was used to avoid image vulnerabilities in later versions. 
* The entrypoint of the shell script is `configure_db2.sh` 
    * Inside this configure_db2.sh there is a refernece to the db2-cmd.sh file which houses all relevant db2 commands for the chosen CP4BA services. 


# Deployment order

This particular Job has a sync wave of 281 in Argo meaning it occurs directly after the creation of Secrets, and the creation of a global ca, but before the `dbs-cp4ba-configuration` Job 

Additionally, this job does depend on the creation of a Service Account with permissions to exec to pods, get pods and perform the relevant oc steps in the DB2 namespace. This SA should already be deployed by the pattern. 

# Usage instructions / configurable parameters

## Using and modifying Dockerfile [optional] 

* The Dockerfile given in this repository can be used to package the relevant shell scripts into an image based on the openshift-origin cli. 
* if you wish to add additional linux components you may need to change the image, but the rest of the Dockerfile should remain the same. 
* **KEEP IN MIND THE OPENSHIFT CLI IS NECESSARY TO RUN THIS JOB**


## Using and modifying the shell scripts [only necessary to add additional components]

As you can see from the below functions the shell script creates several databases including 
- OS1DB
- OS2DB 
- UMS 
- GCDDB 
- NAVDB 

All of these databases are necessary for CP4BA - once this job is executed it is recommended you check the databases manually `oc exec $DB2_POD_NAME -c db2u -- su - db2inst1 -c \"db2 list database directory\` - if this output is concatenated you can run the same command inside the db2 pod to see the full output.

The create_dbs function creates all the relevant dbs, and the setup of osdb takes an osdb database and configures it with the relevant tablespaces 
```
function create_dbs {
    echo "Starting OS1DB creation"
    db2 -v "CREATE DATABASE OS1DB AUTOMATIC STORAGE YES PAGESIZE 32 K"

    echo "Starting OS2DB creation"
    db2 -v "CREATE DATABASE OS2DB AUTOMATIC STORAGE YES PAGESIZE 32 K"

    echo "Starting UMS creation"
    db2 -v "CREATE DATABASE UMS AUTOMATIC STORAGE YES PAGESIZE 32 K"

    echo "Starting GCDDB creation"
    db2 -v "CREATE DATABASE GCDDB AUTOMATIC STORAGE YES PAGESIZE 32 K"

    echo "Starting NAVDB creation"
    db2 -v "CREATE DATABASE NAVDB AUTOMATIC STORAGE YES PAGESIZE 32 K"
}

function setup_osdb {
    dbname=$1
    echo "starting $dbname setup"

    db2 -v connect to $dbname
    db2 -v DROP TABLESPACE USERSPACE1
    db2 -v UPDATE DATABASE CONFIGURATION FOR $dbname USING APPLHEAPSZ 2560
    db2 -v UPDATE DATABASE CONFIGURATION FOR $dbname USING CUR_COMMIT ON DEFERRED
    db2 -v CREATE LARGE TABLESPACE "DATA_TS" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE USING STOGROUP IBMSTOGROUP AUTORESIZE YES BUFFERPOOL IBMDEFAULTBP OVERHEAD INHERIT TRANSFERRATE INHERIT DROPPED TABLE RECOVERY ON DATA TAG INHERIT
    db2 -v CREATE LARGE TABLESPACE "INDEX_TS" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE USING STOGROUP IBMSTOGROUP AUTORESIZE YES BUFFERPOOL IBMDEFAULTBP OVERHEAD INHERIT TRANSFERRATE INHERIT DROPPED TABLE RECOVERY ON DATA TAG INHERIT
    db2 -v CREATE LARGE TABLESPACE "LOB_TS" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE USING STOGROUP IBMSTOGROUP AUTORESIZE YES BUFFERPOOL IBMDEFAULTBP OVERHEAD INHERIT TRANSFERRATE INHERIT DROPPED TABLE RECOVERY ON DATA TAG INHERIT
    db2 -v CREATE USER TEMPORARY TABLESPACE "TEMP_TS" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE USING STOGROUP IBMSTOGROUP BUFFERPOOL IBMDEFAULTBP OVERHEAD INHERIT TRANSFERRATE INHERIT DROPPED TABLE RECOVERY OFF
    db2 -v CREATE LARGE TABLESPACE "VWDATA_TS" IN DATABASE PARTITION GROUP IBMDEFAULTGROUP PAGESIZE 32768 MANAGED BY AUTOMATIC STORAGE USING STOGROUP IBMSTOGROUP AUTORESIZE YES BUFFERPOOL IBMDEFAULTBP OVERHEAD INHERIT TRANSFERRATE INHERIT DROPPED TABLE RECOVERY ON DATA TAG INHERIT
    db2 -v connect reset

    echo "setup for $dbname complete"
}
```


## Using and modifying the Jobspec 

The jobspec for this job only takes one parameter as args to the container: a -a flag with the preconfigure argument. 

The service account passed in is the service account created in [The rbac directory in the infra repository](https://github.com/oto-gitops-oneshot/otp-gitops-infra/tree/master/rbac/db2/db2-config)

Be sure to change the image if you push your own version. 

```apiVersion: batch/v1
kind: Job
metadata:
  name: db2-configuration
  namespace: db2
spec:
  template:
    spec:
      serviceAccountName: db2-configure-sa
      containers:
      - name: db2-config
        image: quay.io/langley_millard_ibm/configure-db2
        command: ["./configure_db2.sh"]
        env:
        - name: KUBECONFIG
          value: "/tmp/config"
        args: ["-a", "preconfigure"]
        imagePullPolicy: Always
      restartPolicy: OnFailure
  backoffLimit: 2
  ```


# Closing statements and comments

Ultimately, configuring DB2 for CP4BA is fairly straightforward and should run the same every time. 