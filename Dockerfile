FROM centos:7

COPY installer/"*.zip" /installer/
COPY installer/oraInst.loc /etc/

ENV ORACLE_BASE=/u01/app/oracle \
    ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1 \
    PATH=${PATH}:/u01/app/oracle/product/11.2.0/dbhome_1/bin \
    _JAVA_OPTIONS=-Xmx1024M

COPY installer/db_install.rsp installer/netca.rsp installer/dbca.rsp ${ORACLE_BASE}/

RUN yum -y install wget && \
        wget https://yum.oracle.com/RPM-GPG-KEY-oracle-ol7 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle && \
        gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle && \
        curl http://public-yum.oracle.com/public-yum-ol7.repo -#o /etc/yum.repos.d/public-yum-ol7.repo && \
        rpm -e --nodeps $(rpm -qa | grep "centos-release") && \
        yum -y install oracle-rdbms-server-11gR2-preinstall perl unzip && \
        mkdir -p ${ORACLE_BASE} && chown oracle:oinstall ${ORACLE_BASE} && \
        chown -R oracle:oinstall ${ORACLE_BASE}/db_install.rsp ${ORACLE_BASE}/netca.rsp ${ORACLE_BASE}/dbca.rsp /installer

WORKDIR /installer

USER oracle
RUN unzip "*.zip" && \
    /installer/database/runInstaller -ignoresysprereqs -ignoreprereq -waitforcompletion -force -silent ORACLE_HOME=${ORACLE_HOME} ORACLE_HOME_NAME=orcl -responseFile ${ORACLE_BASE}/db_install.rsp DECLINE_SECURITY_UPDATES=true ORACLE_BASE=${ORACLE_BASE} && \
    rm -rf /installer/*

USER root
RUN $ORACLE_HOME/root.sh && \
    yum -y remove wget unzip

COPY installer/entrypoint.sh /
RUN chown -R oracle:oinstall /entrypoint.sh && chmod u+x /entrypoint.sh

USER oracle

WORKDIR ${ORACLE_HOME}
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 1521 5500 5520

ENV MEMORY_PERCENTAGE=30 EM_CONFIGURATION=LOCAL ORACLE_SGA_TARGET=512m ORACLE_PGA_TARGET=512m DISPLAY=hostname:0.0
