#!/bin/bash
set -e

ROOT_PASSWORD=${ROOT_PASSWORD:-password}
export JAVA_HOME=`type -p javac|xargs readlink -f|xargs dirname|xargs dirname`

BIND_DATA_DIR=${DATA_DIR}/bind
MYSQL_DATA_DIR=${DATA_DIR}/mysql
TOMCAT_DIR=${DATA_DIR}/tomcat

if [ ! -d ${DATA_DIR} ]; then
   mkdir -p ${DATA_DIR}
fi

init_bind() {

  # move configuration if it does not exist
  if [ ! -d ${BIND_DATA_DIR} ]; then
    mv /etc/bind ${BIND_DATA_DIR}
    cp $TOMCAT_HOME/conf/sml/bindtemplate/*.* ${BIND_DATA_DIR}/
  fi
  rm -rf /etc/bind
  ln -sf ${BIND_DATA_DIR} /etc/bind
  chmod -R 0775 ${BIND_DATA_DIR}
  chown -R ${BIND_USER}:${BIND_USER} ${BIND_DATA_DIR}

}

init_mysql() {
  if [ ! -d ${MYSQL_DATA_DIR} ]; then
    mv /var/lib/mysql ${MYSQL_DATA_DIR}
  fi
  
  rm -rf /var/lib/mysql
  ln -sf ${MYSQL_DATA_DIR} /var/lib/mysql

  chmod -R 0775 ${MYSQL_DATA_DIR}
  
  usermod -d ${MYSQL_DATA_DIR} mysql
  service mysql start

  # create sml schema and user
  if  [ ! -d ${MYSQL_DATA_DIR}/${DB_SML_SCHEMA} ]; then
     # create database
     mysql -h localhost -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';drop schema if exists $DB_SML_SCHEMA;DROP USER IF EXISTS $DB_SML_USER;  create schema $DB_SML_SCHEMA; alter database $DB_SML_SCHEMA charset=utf8; create user $DB_SML_USER identified by '$DB_SML_PASSWORD';grant all on $DB_SML_SCHEMA.* to $DB_SML_USER;"
    # database is created by liquibase
  fi
    # change db init file alway else at new run (not start container) liquibase will return error
   if  [ -f ${DATA_DIR}/init/db.init.xml ]; then
	mkdir -p $TOMCAT_HOME/webapps/WEB-INF/classes/liquibase/
        cp ${DATA_DIR}/init/db.init.xml $TOMCAT_HOME/webapps/WEB-INF/classes/liquibase/db.init-data-inserts.xml
        jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.init-data-inserts.xml 
        rm -rf $TOMCAT_HOME/webapps/WEB-INF 
    fi

# create SMP schema and user
  if  [ ! -d ${MYSQL_DATA_DIR}/${DB_SMP_SCHEMA} ]; then
     # create database
    mysql -h localhost -u root -p$MYSQL_ROOT_PASSWORD -e "drop schema if exists $DB_SMP_SCHEMA;DROP USER IF EXISTS $DB_SMP_USER;  create schema $DB_SMP_SCHEMA; alter database $DB_SMP_SCHEMA charset=utf8; create user $DB_SMP_USER identified by '$DB_SMP_PASSWORD';grant all on $DB_SMP_SCHEMA.* to $DB_SMP_USER;"
     # update init data
   echo "" >> /opt/smp-$SMP_VERSION/database-scripts/create-Mysql.sql
   echo  "update smp_domain set bdmslClientCertHeader='sno=123456&subject=CN=SMP_CEF_SUPPORT, OU=B4, O=DIGIT, L=Brussels, ST=BE, C=BE&validfrom=Jun 1 10:00:00 2015 CEST&validto=Jun 1 10:00:00 2035 CEST&issuer=EMAILADDRESS=root@test.be,CN=TEST Root CN, OU=B4,O=DIGIT,L=Brussels,ST=BE,C=BE'" >> /opt/smp-$SMP_VERSION/database-scripts/create-Mysql.sql
#
  mysql -h localhost -u $DB_SMP_USER -p$DB_SMP_PASSWORD $DB_SMP_SCHEMA < "/opt/smp-$SMP_VERSION/database-scripts/create-Mysql.sql"
  fi
}


init_tomcat() {

  echo "[INFO] init tomcat folders: $tfile"
  if [ ! -d ${TOMCAT_DIR} ]; then
    mkdir -p ${TOMCAT_DIR}
  fi

  # move tomcat log folder to data folder
  if [ ! -d ${TOMCAT_DIR}/logs ]; then
    if [ ! -d  ${TOMCAT_HOME}/logs  ]; then
      mkdir -p ${TOMCAT_DIR}/logs
    else 
      mv ${TOMCAT_HOME}/logs ${TOMCAT_DIR}/
      rm -rf ${TOMCAT_HOME}/logs 
    fi
  fi
  rm -rf ${TOMCAT_HOME}/logs 
  ln -sf ${TOMCAT_DIR}/logs ${TOMCAT_HOME}/logs

  # move domibus conf folder to data folder
  if [ ! -d ${TOMCAT_DIR}/conf ]; then
    mv ${TOMCAT_HOME}/conf ${TOMCAT_DIR}/
  fi
  rm -rf ${TOMCAT_HOME}/conf 
    ln -sf ${TOMCAT_DIR}/conf ${TOMCAT_HOME}/conf
  chown -R tomcat:tomcat ${TOMCAT_DIR}
  chmod u+x $TOMCAT_HOME/bin/*.sh
  # start tomcat - start from tomcat home or fix smp log file
  cd ${TOMCAT_HOME}/bin
  su -c ./startup.sh -s /bin/sh tomcat

}



init_bind
init_mysql
init_tomcat


# allow arguments to be passed to named
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == named || ${1} == $(which named) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch named
if [[ -z ${1} ]]; then
  
  echo "Starting named..."
  exec $(which named) -u ${BIND_USER} -g ${EXTRA_ARGS}
else
  exec "$@"
fi

