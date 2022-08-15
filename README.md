# Repository for configuring DB2 and DBS

## How to use this repository: 

The repository has a directory for two different jobs
1. A job for general configuring of DB2 for a cp4ba deployment (`db2`)
2. A job for configuring DBS for specific services ( int his case, DB2 for ier, cp4ba, fncm and ban) (`dbs`)

Each filepath (i.e `db2` ) contains a Dockerfile, shell scripts and an example jobspec. 

How to use: 

* cd to a directory
* update the scripts 
* build using the dockerfile 
* Push to an image repository 
* reference the image repository in the example jobspec 
* apply the example jobspec into the cluster 

