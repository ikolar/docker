#!/bin/sh

#set -e

# parameters
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"root"}
DB_USER=${DB_USER:-""}
DB_USER=${DB_USER:-""}
DB_SCHEMA=${DB_SCHEMA:-""}

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
    if [ ! -d  ${DOMIBUS_HOME}/domibus/log  ]; then
      mkdir -p ${TOMCAT_DIR}/log
    else 
      mv ${DOMIBUS_HOME}/domibus/log ${TOMCAT_DIR}/
      rm -rf ${DOMIBUS_HOME}/domibus/log 
    fi
    ln -sf ${TOMCAT_DIR}/log ${DOMIBUS_HOME}/domibus/log
  fi

  # move domibus conf folder to data folder
 if [ ! -d ${TOMCAT_DIR}/conf ]; then
    mv ${DOMIBUS_HOME}/domibus/conf ${TOMCAT_DIR}/
    rm -rf ${DOMIBUS_HOME}/domibus/conf 
    ln -sf ${TOMCAT_DIR}/conf ${DOMIBUS_HOME}/domibus/conf
  fi
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

    echo 'create smp database'
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
    echo "[INFO] Creating user: $DB_USER with password $DB_USER"
    echo "GRANT ALL ON \`$DB_SCHEMA\`.* to '$DB_USER'@'%' IDENTIFIED BY '$DB_USER';" >> $tfile

    echo 'FLUSH PRIVILEGES;' >> $tfile
    echo "" >> $tfile
    echo "USE $DB_SCHEMA;" >> $tfile
    # set innodb_default_row_format - else there are problems because of composite key
    #newer version also has not this problem
    # https://stackoverflow.com/questions/1814532/1071-specified-key-was-too-long-max-key-length-is-767-bytes
    # --innodb-file-format=Barracuda --innodb-file-per-table=ON --innodb-large-prefix=1  and SET GLOBAL innodb_default_row_format=DYNAMIC;
    echo "SET GLOBAL innodb_default_row_format=DYNAMIC;"   >> $tfile

    sed -i "s| \/\/|; \/\/|g" /etc/mysql/my.cnf "$SMP_HOME/smp-$SMP_VERSION/database-scripts/create-Mysql.sql"
    sed -i "s|DELIMITER; \/\/|DELIMITER \/\/|g" /etc/mysql/my.cnf "$SMP_HOME/smp-$SMP_VERSION/database-scripts/create-Mysql.sql"
    cat  "$SMP_HOME/smp-$SMP_VERSION/database-scripts/create-Mysql.sql"  >>  $tfile

    # run sql in tempfile
    echo "[INFO] run tempfile: $tfile"
    /usr/bin/mysqld --innodb-file-format=Barracuda --innodb-file-per-table=ON --innodb-large-prefix=1 --user=mysql --bootstrap --verbose=0 < $tfile

    rm -f $tfile
  fi
  # start mysql 
  echo "[INFO] start mysql"
  /usr/bin/mysqld --innodb-file-format=Barracuda --innodb-file-per-table=ON --innodb-large-prefix=1 --user=mysql &

}

init_mysql
init_tomcat


echo '[INFO] start running domibus'
chmod u+x $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/bin/*.sh

exec $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/bin/catalina.sh run




