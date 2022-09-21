# DBS Configuration Job

Link to Original DBS deployment in Apollo Repository: [Apollo DB scripts](https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tree/main/scripts/roles/cp4ba/tasks/db)


# Components 

* This job consists of two shell scripts, a Dockerfile to build an image, and a yaml Jobspec. 
* The Dockerfile makes use of the OpenShift origin CLI - an earlier version of the CLI was used to avoid image vulnerabilities in later versions. 
* The entrypoint of the shell script is `create_db.sh` 
    * Inside this configure_db2.sh there is a refernece to the db2-cmd.sh file which houses all relevant db2 commands for the chosen CP4BA services. 


# Deployment order

This particular Job has a sync wave of 282 in Argo meaning it occurs directly after the configuration of DB2, and some time after the creation of a global ca, but before we move into the `Deploy` phase. 

Additionally, this job does depend on the creation of a Service Account with permissions to exec to pods, get pods and perform the relevant oc steps in the DB2 namespace. This SA should already be deployed by the pattern. 

# Usage instructions / configurable parameters

## Using and modifying Dockerfile [optional] 

* The Dockerfile given in this repository can be used to package the relevant shell scripts into an image based on the openshift-origin cli. 
* if you wish to add additional linux components you may need to change the image, but the rest of the Dockerfile should remain the same. 
* **KEEP IN MIND THE OPENSHIFT CLI IS NECESSARY TO RUN THIS JOB**


## Using and modifying the shell scripts [only necessary to add additional components]

The shell script for DBS performs several functions: 
1. Creates the relevant (service specific) users in the db2 ldap pod 
2. Creates the relevant tables and tablespaces in the prior created DB2 databases. 

* As CP4BA is universal to all CP4BA services, the CP4BA table is always created. 

The additional tables and configuration that happens are **dependent on services passed in the jobspec** as `args ["-i", "list of services"]. 

* The `init_db.sh` script contains all the necessary configuration for IER, TM and BAN. 

i.e. to configure BAN, we define a function and place the configuration inside. 

```
function init_BAN_db {
    # initialise BAN DB
    ban_init_cmd="
    echo Initialising BAN DB;\n
    {
        db2 CONNECT TO CP4BA;
        db2 CREATE REGULAR TABLESPACE ICNDB_TS PAGESIZE 32 K BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE USER TEMPORARY TABLESPACE ICNDB_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE SYSTEM TEMPORARY TABLESPACE ICNDB_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 GRANT DBADM ON DATABASE TO user icndb;
        db2 GRANT USE OF TABLESPACE ICNDB_TS TO user icndb;
        db2 GRANT USE OF TABLESPACE ICNDB_TEMP_TS TO user icndb;
        db2 CONNECT RESET;\n
    } || {
        echo There was an error reported; \n
    }\n"
    
    printf "$ban_init_cmd"
}
```
We pass the BAN argument in to the Jobspec as an argument. 
```
args: ["-i", "BAN"]
```


* To add configuration for additional services (i.e. to extend the Job to perform dbs config for other cp4ba services) you should: 

    1. Find the relevant configuration in the Apollo repositories, or IBM documentation or other services
    2. Convert the configuration code into BASH or SHELL script 
    3. create a new function in the `init_db.sh` shell script with the name convention `function init_<db service>_db { }`
    4. Place the modified code for the CP4BA service into new function declaration 
    5. Pass the new `<db servie>` in as an argument to the jobspec. 
        - note: it is vital that the name passed into the jobspec matches the name defined in the function exactly. 


After this, we create the users in the DB2 ldap pod. Each user is specific to a service. 

In our case, several users have already been catered for. These users are:  
```
"gcd,fpos,ros,icndb,os1"
```
Note: Should you wish to add new users for a new service, you can simply pass them in as arguments to the Jobspec. Users for services can be found in the Apollo repository. 


The configuration for users in bash is quite simple 
```
UNIVERSAL_PASSWORD=$(oc get secret universal-password -n $CP4BA_NAMESPACE -o jsonpath='{.data.universalPassword}' | base64 --decode) 

DB2_LDAP_POD_NAME=$(oc get pod -l role=ldap -ojsonpath='{.items[0].metadata.name}')

# We can pass in a list of separated users as an env variable. 
echo $USER_LIST
for user in ${USER_LIST//,/ }
do 
    echo " creating $user in $DB2_LDAP_POD_NAME" 
    USER=$(oc exec $DB2_LDAP_POD_NAME -it -c ldap -- /opt/ibm/ldap_scripts/addLdapUser.py -u $user -p $UNIVERSAL_PASSWORD -r user)
done
```

* We get the 'universal password' secret that has been created prior to this jobs execution - this universal password will be the 'password' for all database users. 
* We get the name of the db2 ldap pod by finding the pod labelled with role:ldap. 
* We pass in a list of users as an ENV_VARIABLE to the jobspec, which is available as an environment variable inside the container. 
* For each user in the list we exec to the DB2 LDAP pod and run a python script that adds users to the db2 ldap pod. This script accepts the username as a parameter (-u) and the universal password (-p) as the universal password we got from the secret and a type (-r) as user. 


## Using and modifying the Jobspec 

The Jobspec is relatively simple and only takes three configurable parameters: 
1. CP4BA_NAMESPACE - The namespace in which CP4BA is deployed 
2. USER_LIST - The list of users that need to be configured 
3. args - args for which services need to be configured 
4. KUBECONFIG - a directory for Kubeconfig to be stored so we can use the oc cli (shouldnt need to be modified for many circumstances)

```
apiVersion: batch/v1
kind: Job
metadata:
  name: database-configuration
  # can change this to cp4ba if we need to, but the job is ALL about configruing db2 for cp4ba so this seems like good separation to me. 
  namespace: db2
spec:
  template:
    spec:
      serviceAccountName: db2-configure-sa
      containers:
      - name: dbs-config
        image: quay.io/langley_millard_ibm/cp4ba-configure-dbs # location the image is pushed to i.e. quay.io/langley_millard_ibm/repo_name
        command: ["./create_db.sh"]
        env:
        - name: CP4BA_NAMESPACE
          value: "cp4ba"
        - name: USER_LIST
          value: "gcd,fpos,ros,icndb,os1"
        - name: KUBECONFIG
          value: "/tmp/config"
        args: ["-i", "BAN,FNCM,IER"]
        imagePullPolicy: Always
      restartPolicy: OnFailure
  backoffLimit: 2
```
- Modify CP4BA_NAMESPACE if you need to change the namespace that CP4BA is deployed in by changing the value. 
- Modify USER_LIST to add or remove users to/from the list depending on which services you wish to deploy. 
- Modify args to add or remove services you wish to configure - if you add services be sure to modify the bash script to account for this. 
    - NOTE: Any changes to the shell script will require changing the Jobspec image to wherever you have built and pushed your image with the new shell script. 


# Closing statements and comments
n/a