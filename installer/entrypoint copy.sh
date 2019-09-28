#!/bin/bash -eu

set +u
[ "${DEBUG}" ] && set -x
set -u

ORA_DATA=${ORACLE_BASE}/oradata

function verify_environment() {
  set +eu
  local error=false

  INITIALIZED=false

  INIT_FILE=$(ls ${ORA_DATA}/init*.ora 2>/dev/null)
  
  if [ -z "$INIT_FILE"]; then INITIALIZED=false; else INITIALIZED=true && ORACLE_SID=$(basename ${INIT_FILE} | cut -f 1 -d"." | cut -b5-); fi

  if [ -z ${ORACLE_SID} ]; then echo "[ERROR] You need to specify the desired ORACLE_SID" && error=true; fi

     if ! $INITIALIZED; then
 	#if [ -z ${ORACLE_DATABASE} ]; then echo "[ERROR] You need to specify the desired ORACLE_DATABASE (8 chars max)" && error=true; fi
 		
 	if [ -z ${ORACLE_USER} ]; then echo "[ERROR] You need to specify the desired ORACLE_USER" && error=true; fi
 		
 	if [ -z ${ORACLE_PASSWORD} ]; then echo "[ERROR] You need to specify the desired ORACLE_PASSWORD" && error=true; fi
 		
 	if [ -z ${ORACLE_DBA_PASSWORD} ]; then echo "[ERROR] You need to specify the desired ORACLE_DBA_PASSWORD" && error=true; fi
     fi

     if ${error}; then exit 1; fi

     echo "[INFO] Oracle SGA and PGA : ${MEMORY_PERCENTAGE}"

     set -eu
}

function stop_database() {
  ${ORACLE_HOME}/bin/sqlplus / as sysdba <<EOF
  shutdown immediate;
  exit;
EOF

}

function start_database() {
  ${ORACLE_HOME}/bin/sqlplus / as sysdba <<EOF
  startup;
  exit;
EOF

}

function start_listener() {
  #export DISPLAY=hostname:0.0
  #$ORACLE_HOME/bin/netca -ignoresysprereqs -ignoreprereq -waitforcompletion -force -silent -responseFile ${ORACLE_BASE}/netca.rsp

  printf "LISTENER=(DESCRIPTION_LIST=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521))(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1521))))\n" > $ORACLE_HOME/network/admin/listener.ora
  $ORACLE_HOME/bin/lsnrctl start
}

function ceate_user() {
  echo "create user ${ORACLE_USER} identified by ${ORACLE_PASSWORD};" | ${ORACLE_HOME}/bin/sqlplus / as sysdba
  echo "GRANT ALL PRIVILEGES to ${ORACLE_USER};" | ${ORACLE_HOME}/bin/sqlplus / as sysdba

  echo "[INFO] user ${ORACLE_USER} created"
}

function update_variables() {
  ${ORACLE_HOME}/bin/sqlplus / as sysdba <<EOF
	alter system set sga_target=${ORACLE_SGA_TARGET} scope=spfile;
	alter system set sga_max_size=${ORACLE_SGA_TARGET} scope=spfile;
	alter system set pga_aggregate_target=${ORACLE_PGA_TARGET} scope=spfile;
	alter system set FILESYSTEMIO_OPTIONS=asynch scope=spfile;
  exit;
EOF
}

function intialize () {
  verify_environment

  start_listener

  if $INITIALIZED; then
    echo "[INFO] Database already initialized, just starting it"
    cp -v ${ORA_DATA}/init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs 
    cp -v ${ORA_DATA}/tnsnames.ora ${ORACLE_HOME}/network/admin

    start_database
    return
  fi

   $ORACLE_HOME/bin/dbca -silent -createDatabase -responseFile ${ORACLE_BASE}/dbca.rsp -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -syspassword ${ORACLE_DBA_PASSWORD} -systempassword ${ORACLE_DBA_PASSWORD} -dbsnmppassword ${ORACLE_DBA_PASSWORD} -memoryPercentage ${MEMORY_PERCENTAGE} -emConfiguration ${EM_CONFIGURATION}

   ceate_user

   update_variables

   #we need to restart after the properties update
   stop_database
   start_database

   cp ${ORACLE_HOME}/dbs/init.ora ${ORA_DATA}/init${ORACLE_SID}.ora
   cp ${ORACLE_HOME}/network/admin/tnsnames.ora ${ORA_DATA}
}

intialize

tail -F /dev/null
