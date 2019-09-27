# Oracle11g docker image (centos7)

This is a Oracle image to easily build an Oracle environment for test purposes.

## How to build

- Download the official Oracle 11gR2 installer on the [oracle site](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
- Put the archive `linux.x64_11gR2_database_1of2.zip` and `linux.x64_11gR2_database_2of2.zip` in the `installer` directory
- Execute, two choice 
    - `docker-compose up -d`. It will create the image, install Oracle on it. it can take some time. and auto background run container
    - `docker build -t <image name>:<tag> .`. It will create the image and install Oracle on it. it can take some time.
    
:info: when new version are release, compare the file db_install.rsp with ``/u01/app/oracle/product/11.2.0/dbhome_1/assistants/dbca/dbca.rsp`` in the image

## How to run

A build of the image is available on the [docker hub](https://hub.docker.com/r/bedwuttipong/docsdocker/).

The Oracle instance can be launched with this command :
```
docker run --name oracledb11g -p 1521:1521 -p 5500:5500 -p 5520:5520 -e ORACLE_SID=orcl -e ORACLE_USER=dba -e ORACLE_PASSWORD=secert -e ORACLE_DBA_PASSWORD=password wutti/oracle:11g
```

This will launch Oracle and initialize the database.
The data are persisted on the directory `/u01/app/oracle/data`. To keep them between 2 container restarts, add this parameter to your command line:
```
-v local_datadir:/u01/app/oracle/data
```

## Operating system environment variable
- ORACLE_SID : The oracle sid used to identified the database (mandatory)
- ORACLE_USER : The standard user name allowed to connect to the database (mandatory)
- ORACLE_PASSWORD : The password of the user (mandatory)
- ORACLE_DBA_PASSWORD : Administrator password (mandatory)
- ORACLE_UNQNAME : the database’s unique name value. (optional)
- MEMORY_PERCENTAGE : The argument will specify the percentage of total memory that can be use by Oracle SGA and PGA combined (default: 30)
- EM_CONFIGURATION : Enterprise Manager Configuration Type (default: LOCAL)
    - option, LOCAL, CENTRAL, NOBACKUP, NOEMAIL, and NONE.
    
## Thankful
* [ethicus-solution](https://github.com/ethicus-solution/docker-oracle11g)
* [exo-docker](https://github.com/exo-docker/exo-oracle)
