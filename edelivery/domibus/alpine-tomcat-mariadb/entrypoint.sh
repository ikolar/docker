#!/bin/sh

#set -e

# parameters
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root"}
DB_USER=${DB_USER:-"edelivery"}
DB_USER_PASSWORD=${DB_USER:-"edelivery"}
DB_SCHEMA=${DB_SCHEMA:-"domibus"}

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
  if [ ! -d ${TOMCAT_DIR}/logs ]; then
    if [ ! -d  ${DOMIBUS_HOME}/domibus/logs  ]; then
      mkdir -p ${TOMCAT_DIR}/logs
    else 
      mv ${DOMIBUS_HOME}/domibus/logs ${TOMCAT_DIR}/
      rm -rf ${DOMIBUS_HOME}/domibus/logs 
    fi
    ln -sf ${TOMCAT_DIR}/logs ${DOMIBUS_HOME}/domibus/logs
  fi

  # move domibus conf folder to data folder
 if [ ! -d ${TOMCAT_DIR}/conf ]; then
    mv ${DOMIBUS_HOME}/domibus/conf ${TOMCAT_DIR}/
    rm -rf ${DOMIBUS_HOME}/domibus/conf 
    ln -sf ${TOMCAT_DIR}/conf ${DOMIBUS_HOME}/domibus/conf
  fi
  chown -R tomcat:tomcat ${TOMCAT_DIR}
  chown -R tomcat:tomcat ${DOMIBUS_HOME}/domibus
  chmod u+x $DOMIBUS_HOME/domibus/bin/*.sh
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

  if [ -d ${MYSQL_DATA_DIR}/${DB_SCHEMA} ]; then
    echo '[INFO] MySQL ${DB_SCHEMA} already present, skipping creation'
  else 
    echo "[INFO] MySQL ${DB_SCHEMA}  not found, creating initial DBs"

    echo 'create domibus database'
   # create temp file
    tfile=`mktemp`
    if [ ! -f "$tfile" ]; then
        return 1
    fi

    # save sql
    echo "[INFO] Create temp file: $tfile"
    cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
DELETE FROM mysql.user;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;
EOF

    echo "[INFO] Creating database: $DB_SCHEMA"
    echo "CREATE DATABASE IF NOT EXISTS \`$DB_SCHEMA\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
    # set new User and Password
    echo "[INFO] Creating user: $DB_USER with password $DB_USER_PASSWORD"
    echo "GRANT ALL ON \`$DB_SCHEMA\`.* to '$DB_USER'@'%' IDENTIFIED BY '$DB_USER';" >> $tfile

    echo 'FLUSH PRIVILEGES;' >> $tfile
    echo "" >> $tfile
    echo "USE $DB_SCHEMA;" >> $tfile
    cat  "$DOMIBUS_HOME/sql-scripts/mysql5innoDb-$DOMIBUS_VERSION.ddl"  >>  $tfile

    # run sql in tempfile
    echo "[INFO] run tempfile: $tfile"
    /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile

    rm -f $tfile
  fi
  # start mysql 
  echo "[INFO] start mysql"
  /usr/bin/mysqld --user=mysql &

}

init_mysql
init_tomcat


echo '[INFO] start running domibus'


exec su -c "$DOMIBUS_HOME/domibus/bin/catalina.sh run" -s /bin/sh  tomcat




