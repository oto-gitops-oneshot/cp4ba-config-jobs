# Postdeploy configuration 

# Components 

Link to Apollo Repository: https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tree/main/scripts/roles/cp4ba/tasks/postdeploy:[you can find the original feature configured in Ansible here]

* A shell script that contains a switch statement for which services to configure based on the deployments specified in the icp4aCluster object 
* A shell script that contains the necessary methods to perform for each service 
* A large Dockerfile that contains all relevant components for building this image 
    * `tar gzip jq java-11-openjdk wget and oc`
* An example Jobspec 
* An IER directory containing a cp4ba specific java CLI, and relevant JAR files (*this is NOT included in this repository due to size constraints, but can be found inside the image itself, or inside the Apollo repository linked above.*)
* A CP4BA service account with exec, get, create and delete permissions on pods, secrets, icp4a clusters. This SA can be found under `infra/rbac/cp4ba`
# Deployment order

* This Job is used to configure the services deployed by the icp4a cluster object. Due to this, this Job must run AFTER the icp4acluster object is FULLY deployed (see healthchecks repository)
* In addition to this, this job replies on a list of services defined in the icp4acluster CRD - so this CRD must be present in order for this job to run at all. 


# Usage instructions / configurable parameters

* Add the parameters that need to be passed to your script, the jobspec or the yaml job etc. i.e. 
* *The YAML spec for this job only takes a single parameter*
    * The directory for to save a Kubeconfig file. Ultimately, this directory shouldnt need to change. 
* This is because unlike how we need to pass services to the predeploy job as a list, once the icp4acluster object is deployed we can query the icp4acluster to get a list of services and configure based on this

```
apiVersion: batch/v1
kind: Job
metadata:
  name: postdeploy-configuration
  namespace: cp4ba
spec:
  template:
    spec:
      serviceAccountName: cp4ba-sa
      containers:
      - name: postdeploy-configuration
        image: quay.io/langley_millard_ibm/cp4ba-postdeploy-config
        command: ["./postdeploy-config.sh"]
        env:
        - name: KUBECONFIG
          value: "/tmp/config"
        imagePullPolicy: Always
      restartPolicy: OnFailure
  backoffLimit: 2
```

### Currently Available Services: 
* Currently, this job can configure postdeploy steps for ier and tm (and by extension ier & tm together.) 

* Extending this Job script should be fairly simple. 
    1. Add an entry in the switch case for whichever service you wish to configure 
    2. create a method in `services.sh` that performs the configurations required. By default you will have access to `tar gzip jq java-11-openjdk wget and oc` including cURL, but you may need to add services to the Dockerfile. 
        - if this is the case you can use microdnf OR use the wget module to get and extract relevant files. 
        ```
        RUN microdnf update -y && microdnf install -y tar gzip jq java-11-openjdk wget <add service here> && \
        wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.11.0/openshift-client-linux-4.11.0.tar.gz && \
        tar xzvf openshift-client-linux-4.11.0.tar.gz -C /usr/bin && rm openshift-client-linux-4.11.0.tar.gz && rm /usr/bin/README.md && \
        chmod +x /usr/bin/oc && chmod +x /usr/bin/kubectl && \
        # chmod +x /usr/bin/oc && \
        microdnf remove -y wget && microdnf clean all
        # wget https://mirror.openshift.com/pub/openshift-v3/clients/3.11.0-0.10.0/linux/oc.tar.gz && \
        # tar xzvf oc.tar.gz -C /usr/bin && rm oc.tar.gz &&  \
        ```
    3. Call the method in `services.sh` in the switch statement in `postdeploy-config.sh` (below)
```
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
            <add service here>)
                <add method call here>
            *)
                echo "Service not yet configured. Please modify bash script or check arguments"
```

# Closing statements and comments

add anything extra here