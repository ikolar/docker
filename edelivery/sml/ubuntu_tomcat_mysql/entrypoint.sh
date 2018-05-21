#!/bin/bash
set -e

ROOT_PASSWORD=${ROOT_PASSWORD:-password}
export JAVA_HOME=`type -p javac|xargs readlink -f|xargs dirname|xargs dirname`

BIND_DATA_DIR=${DATA_DIR}/bind
MYSQL_DATA_DIR=${DATA_DIR}/mysql
TOMCAT_LOG_DIR=${DATA_DIR}/tomcat

if [ ! -d ${DATA_DIR} ]; then
   mkdir -p ${DATA_DIR}
fi

init_bind() {

  # move configuration if it does not exist
  if [ ! -d ${BIND_DATA_DIR} ]; then
    mv /etc/bind ${BIND_DATA_DIR}
    cp /opt/smlconf/bind/*.* ${BIND_DATA_DIR}/
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

  if  [ ! -d ${MYSQL_DATA_DIR}/${DB_SCHEMA} ]; then
     mysql -h localhost -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';drop schema if exists $DB_SCHEMA;DROP USER IF EXISTS $DB_USER;  create schema $DB_SCHEMA;alter database     $DB_SCHEMA charset=utf8; create user $DB_USER identified by '$DB_USER';grant all on $DB_SCHEMA.* to $DB_USER;"
  fi
}


init_tomcat() {

  # 
  if [ ! -d ${TOMCAT_LOG_DIR} ]; then
     mkdir -p ${TOMCAT_LOG_DIR}
  fi
  rm -rf ${TOMCAT_HOME}/logs
  ln -sf ${TOMCAT_LOG_DIR} ${TOMCAT_HOME}/logs
  chown -R tomcat:tomcat ${TOMCAT_LOG_DIR}
  chmod -R 0775 ${TOMCAT_LOG_DIR}
  # start tomcat
  cd ${TOMCAT_HOME}/bin/
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

