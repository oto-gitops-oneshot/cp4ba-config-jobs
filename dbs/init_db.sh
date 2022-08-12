#!/bin/bash

# define the list of supported databases here
supported_databases='CP4BA IER FNCM BAN'

# setting +e so as the job doesnt fail and hold up future sync waves
set +e

function init_CP4BA_db {
    # initialise BAN DB
    cpba_init_cmd="
    echo Initialising CP4BA DB;\n
    {
        db2 create database CP4BA automatic storage yes using codeset UTF-8 territory US pagesize 32768;
        db2 UPDATE DB CFG FOR CP4BA USING LOGFILSIZ 16384 DEFERRED;
        db2 UPDATE DB CFG FOR CP4BA USING LOGPRIMARY 64 IMMEDIATE;
        db2 UPDATE DB CFG FOR CP4BA USING LOGSECOND 64 IMMEDIATE;
        db2 activate db CP4BA;
        db2 CONNECT TO CP4BA;
        db2 CREATE BUFFERPOOL CP4BA_BP_32K IMMEDIATE SIZE AUTOMATIC PAGESIZE 32K;
        db2 DROP TABLESPACE USERSPACE1;

    } || {
        echo There was an error reported; \n
    }\n"
    
    printf "$cpba_init_cmd"

}



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

function init_FNCM_db {
    # set DB2_WORKLOAD
    printf "db2set DB2_WORKLOAD=FILENET_CM;\n"

    # initialise GCD DB    
    gcd_init_cmd="
    echo Initialising FNCM DB;\n
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
        echo There was an error reported;\n
    }\n"

    printf "$gcd_init_cmd"

    # initialise OS1 DB
    os1_init_cmd="
    echo Initialising OS1 DB;\n
    {
        db2 CONNECT TO CP4BA;
        db2 CREATE LARGE TABLESPACE OS1_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE USER TEMPORARY TABLESPACE OS1_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE SYSTEM TEMPORARY TABLESPACE OS1_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 GRANT DBADM ON DATABASE TO user os1;
        db2 GRANT USE OF TABLESPACE OS1_TS TO user os1;
        db2 GRANT USE OF TABLESPACE OS1_TEMP_TS TO user os1;
        db2 CONNECT RESET;\n
    } || {
        echo There was an error reported;\n
    }\n"
    printf "$os1_init_cmd"
    
}

function init_IER_db {

    # initialise IER FPOS DB
    fpos_init_cmd="
    echo Initialising IER FPOS DB;\n
    {
        db2 CONNECT TO CP4BA;
        db2 CREATE LARGE TABLESPACE FPOS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE USER TEMPORARY TABLESPACE FPOS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE SYSTEM TEMPORARY TABLESPACE FPOS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 GRANT DBADM ON DATABASE TO user fpos;
        db2 GRANT USE OF TABLESPACE FPOS_TS TO user fpos;
        db2 GRANT USE OF TABLESPACE FPOS_TEMP_TS TO user fpos;
        db2 CONNECT RESET;\n
    } || {
        echo There was an error reported;\n
    }\n"
    printf "$fpos_init_cmd"

    # initialise IER ROS DB
    ros_init_cmd="
    echo Initialising IER ROS DB;\n
    {
        db2 CONNECT TO CP4BA;
        db2 CREATE LARGE TABLESPACE ROS_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE USER TEMPORARY TABLESPACE ROS_TEMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 CREATE SYSTEM TEMPORARY TABLESPACE ROS_SYSTMP_TS PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL CP4BA_BP_32K;
        db2 GRANT DBADM ON DATABASE TO user ros;
        db2 GRANT USE OF TABLESPACE ROS_TS TO user ros;
        db2 GRANT USE OF TABLESPACE ROS_TEMP_TS TO user ros;
        db2 CONNECT RESET;\n
    } || {
        echo There was an error reported;\n
    }\n"
    printf "$ros_init_cmd"
}




