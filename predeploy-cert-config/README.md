# Title of Component (i.e. dbs)

# Components 

Link to Apollo Repository: [you can find the original feature configured in Ansible here](https://github.com/apollo-business-automation/ibm-cp4ba-enterprise-deployment/tree/main/scripts/roles/global_ca)

* Ultimately this Job performs the same tasks as the Global CA Ansible in the Apollo Repositories 

* This is performed using openssl and bash, and creating oc secrets rather than using Ansible playbooks. 

* This job consists of a bash script (`cert_gen.sh`), a Dockerfile to build the image, and a Jobspec to pull the image into a pod which runs the job. 


* The output of this job is three secrets in the cp4ba namespace in the cluster - 
    ```
    global-ca

    external-tls-secret

    cp4ba-root-ca
    ```

If you wish to create these secrets manually it is possible to use openssl to generate keys and crts as the job does, and the apply them into your cluster as the following types: 
```
    oc create secret tls global-ca --cert=global-ca.crt --key=global-ca.key -n cp4ba

    oc create secret generic external-tls-secret --from-literal=cert.key="$wildcard_key" --from-literal=cert.crt="$wildcard_cert" --from-literal=tls.crt="$wildcard_cert" --from-literal=ca.crt="$global_ca_cert" -n cp4ba

    oc create secret tls cp4ba-root-ca --cert=global-ca.crt --key=global-ca.key -n cp4ba
```

# Deployment order
The certificate configuration needs to happen quite early - before the icp4a cluster is deployed as there are dependencies on CAs in the icp4a Ansible. 


# Usage instructions / configurable parameters

The Jobspec for this job is relatively simple and only takes two 'parameters'. 

Firstly, this job does NEED a Volume mount. OpenSSL creates certificates with certain permissions, and certificates cannot be written to/read from `/tmp` as it is read/writable by all. We overcome this issue by attaching a volume mount at the container level. 

Secondly, a KUBECONFIG path must be specified. In this case, our kubeconfig can be pointed at `/tmp` - this should not need to be changed. 

Once again, this Job utilises the cp4ba Service Account defined in `rbac` of the `otp-gitops-infra` repository. 

```
apiVersion: batch/v1
kind: Job
metadata:
  name: certificate-configuration
  namespace: cp4ba
spec:
  template:
    spec:
      serviceAccountName: cp4ba-sa
      containers:
      - name: init-certs
        image: quay.io/langley_millard_ibm/predeploy-certs # location the image is pushed to i.e. quay.io/langley_millard_ibm/repo_name
        command: ["./cert_gen.sh"]
        volumeMounts:
        - mountPath: /certs
          name: cert-volume
        env:
        - name: KUBECONFIG
          value: "/tmp/config"
        imagePullPolicy: Always
      volumes:
      - name: cert-volume
        emptyDir: {}
      restartPolicy: OnFailure
  backoffLimit: 2
```


# Closing statements and comments

n/a