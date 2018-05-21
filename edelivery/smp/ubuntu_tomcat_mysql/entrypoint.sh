#!/bin/sh

#set -e

# parameters
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root"}
DB_USER=${DB_USER:-"smp"}
DB_USER_PASSWORD=${DB_USER_PASSWORD:-"secret123"}
DB_SCHEMA=${DB_SCHEMA:-"smp"}

DATA_DIR=/data
MYSQL_DATA_DIR=${DATA_DIR}/mysql
TOMCAT_DIR=${DATA_DIR}/tomcat


if [ ! -d ${DATA_DIR} ]; then
   mkdir -p ${DATA_DIR}
fi

init_tomcat() {
  echo "[INFO] init tomcat folders: $tfile"
  if [ ! -d ${TOMCAT_DIR} ]; then
    mkdir -p ${TOMCAT_DIR}
  fi

  # move tomcat log folder to data folder
  if [ ! -d ${TOMCAT_DIR}/log ]; then
    if [ ! -d  ${SMP_HOME}/apache-tomcat-$TOMCAT_VERSION/log  ]; then
      mkdir -p ${TOMCAT_DIR}/log
    else 
      mv ${SMP_HOME}/apache-tomcat-$TOMCAT_VERSION/log ${TOMCAT_DIR}/
      rm -rf ${SMP_HOME}/apache-tomcat-$TOMCAT_VERSION/log 
    fi
    ln -sf ${TOMCAT_DIR}/log ${SMP_HOME}/apache-tomcat-$TOMCAT_VERSION/log
  fi

  # move domibus conf folder to data folder
 if [ ! -d ${TOMCAT_DIR}/conf ]; then
    mv $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp ${TOMCAT_DIR}/
    rm -rf $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp
    ln -sf ${TOMCAT_DIR}/smp $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp
  fi

  sed -i -e "s#jdbc:mysql://localhost:3306/smp#jdbc:mysql://localhost:3306/$DB_SCHEMA#g" "$SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/smp.config.properties"
  sed -i -e "s#jdbc.user\s*=\s*smp#jdbc.user=$DB_USER#g" "$SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/smp.config.properties"
  sed -i -e "s#jdbc.password\s*=\s*secret123#jdbc.password=$DB_USER_PASSWORD#g" "$SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/smp.config.properties"
  sed -i -e "s#/keystores/sample_signatures_keystore.jks#$SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/sample_signatures_keystore.jks#g" "$SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/smp.config.properties"
 

}


init_mysql() {
  echo "[INFO] init database: $tfile"
  if [ ! -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
  fi

  if [ ! -d ${MYSQL_DATA_DIR} ]; then
    mv /var/lib/mysql ${DATA_DIR}
  fi
  
  rm -rf /var/lib/mysql
  ln -sf ${MYSQL_DATA_DIR} /var/lib/mysql
  chmod -R 0777 ${MYSQL_DATA_DIR}
  chown -R mysql:mysql ${MYSQL_DATA_DIR}
  echo '[INFO] start MySQL'
  service mysql start

  if [ -d ${MYSQL_DATA_DIR}/${DB_SCHEMA} ]; then
    echo '[INFO] MySQL ${DB_SCHEMA} already present, skipping creation'
  else 
    echo "[INFO] MySQL ${DB_SCHEMA}  not found, creating initial DBs"

    echo 'create smp database'
    mysql -h localhost -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';drop schema if exists $DB_SCHEMA;DROP USER IF EXISTS $DB_USER;  create schema $DB_SCHEMA;alter database $DB_SCHEMA charset=utf8; create user $DB_USER identified by '$DB_USER_PASSWORD';grant all on $DB_SCHEMA.* to $DB_USER;"

    mysql -h localhost -u root --password=$MYSQL_ROOT_PASSWORD $DB_SCHEMA < "$SMP_HOME/smp-$SMP_VERSION/database-scripts/create-Mysql.sql"
  fi
  # start mysql 
 
}

init_mysql
init_tomcat


echo '[INFO] start running domibus'
chmod u+x $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/bin/*.sh

exec $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/bin/catalina.sh run




