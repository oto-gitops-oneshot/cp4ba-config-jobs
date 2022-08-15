# Repository for configuring cp4ba with GitOps Jobs
## How to use this repository: 

The repository has a directory for several different jobs
1. A job for general configuring of DB2 for a cp4ba deployment (`db2`)
2. A job for configuring DBS for specific services ( int his case, DB2 for ier, cp4ba, fncm and ban) (`dbs`)
3. A job for creating and configuring the relevant certificates (including ca certs etc) (`predeploy-cert-config`)

Each filepath (i.e `db2` ) contains a Dockerfile, shell scripts and an example jobspec. 

How to use: 

* cd to a directory
* update the scripts 
* build using the dockerfile 
* Push to an image repository 
* reference the image repository in the example jobspec 
* apply the example jobspec into the cluster 

