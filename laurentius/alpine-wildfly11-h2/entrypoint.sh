#!/bin/sh

#set -e

# parameters
DOMAIN=${DOMAIN:-"test.laurentius.si"}
DATABASE_FILENAME="laurentius-db.mv.db"


DATA_DIR=/data




if [ ! -d ${DATA_DIR} ]; then
   mkdir -p ${DATA_DIR}
fi

init_wildfly() {

  echo "[INFO] init WILDFLY folders: $tfile"
  if [ ! -d ${DATA_DIR}/log ]; then
    if [ ! -d ${WILDFLY_HOME}/standalone/log ]; then
      mkdir -p ${WILDFLY_HOME}/standalone/log
    fi
    mv ${WILDFLY_HOME}/standalone/log ${DATA_DIR}/
  fi
  rm -rf ${WILDFLY_HOME}/standalone/log
  ln -sf ${DATA_DIR}/log ${WILDFLY_HOME}/standalone/log
  chown -R lovro:lovro  ${WILDFLY_HOME}/standalone/log

  if [ ! -d ${DATA_DIR}/data ]; then
    if [ ! -d ${WILDFLY_HOME}/standalone/data ]; then
      mkdir -p ${WILDFLY_HOME}/standalone/data
    fi
    mv ${WILDFLY_HOME}/standalone/data ${DATA_DIR}/
  fi
  rm -rf ${WILDFLY_HOME}/standalone/data
  ln -sf ${DATA_DIR}/data ${WILDFLY_HOME}/standalone/data
  chown -R lovro:lovro ${WILDFLY_HOME}/standalone/data
  chown -R lovro:lovro  ${DATA_DIR}
}


init_wildfly


echo '[INFO] start running laurentius'
if [ ! -f ${DATA_DIR}/data/$DATABASE_FILENAME ]; then
  exec su -c "$WILDFLY_HOME/bin/laurentius-init.sh --init -d $DOMAIN" -s /bin/sh  lovro
else 
 exec su -c "$WILDFLY_HOME/bin/laurentius-demo.sh" -s /bin/sh  lovro
fi





