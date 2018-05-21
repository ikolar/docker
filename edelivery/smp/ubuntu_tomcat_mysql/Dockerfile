FROM ubuntu:16.04
MAINTAINER Joze Rihtarsic


# Set the SMP_VERSION env variable  \
ENV SMP_VERSION=4.0.0  \
    SMP_DISTRIBUTION_URL=https://ec.europa.eu/cefdigital/artifact/content/repositories/eDelivery/eu/europa/ec/edelivery/smp  \
    SMP_SHA1=52ba09257948233e920638f7a90f9bfa120910ca  \
    SMP_CONF_SHA1=af40537d2874775f2ab34c538682ef7ac50efdb3  \
    SMP_HOME=/opt/smp  \
    MYSQL_DRV_VERSION=5.1.46  \
    MYSQL_DRV_SHA1=9a3e63b387e376364211e96827bc27db8d7a92e9	  \
    TOMCAT_MAJOR=8    \
    TOMCAT_VERSION=8.5.31   \
    TOMCAT_SHA512=51d8877782bc975b8c566263df7e55f383e617aa3c81ea2c219fed18e1f5d9e8233a92100de95b9a8df69ce5c0ad89a195d5b7e5647fcf9df26231870073a9cb   \
    DB_SCHEMA=smp  \
    DB_USER=smp  \ 
    DB_USER_PASSWORD=secret123  \
    MYSQL_ROOT_PASSWORD=root  

# install utils, java, mysql   \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        mysql-server \
        openjdk-8-jdk \
	curl \
        unzip   \
    && rm -rf /var/lib/apt/lists/*  \
# set user 
    && addgroup mysql mysql   \
# download SMP, SMP setup, tomcat mysql driver
    && mkdir -p $SMP_HOME   \
    && cd $SMP_HOME    \
    && curl -o smp.war "$SMP_DISTRIBUTION_URL/$SMP_VERSION/smp-$SMP_VERSION.war"   \
    && sha1sum smp.war | grep $SMP_SHA1   \
    && curl -o smp-setup.zip "$SMP_DISTRIBUTION_URL/$SMP_VERSION/smp-$SMP_VERSION-setup.zip"    \
    && sha1sum smp-setup.zip | grep $SMP_CONF_SHA1    \
    && curl -O  https://repo1.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_DRV_VERSION/mysql-connector-java-$MYSQL_DRV_VERSION.jar    \
    && sha1sum mysql-connector-java-$MYSQL_DRV_VERSION.jar  | grep $MYSQL_DRV_SHA1    \
    && curl -o tomcat.zip "https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.zip"    \
    && sha512sum tomcat.zip | grep $TOMCAT_SHA512    \
# install SMP
    && unzip tomcat.zip -d $SMP_HOME    \
    && unzip smp-setup.zip -d $SMP_HOME    \
    && mv mysql-connector-java-$MYSQL_DRV_VERSION.jar $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/lib/    \
    && mv smp.war $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/webapps/     \
    && rm -rf $SMP_HOME/*.zip    \
    && mkdir -p $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/  \
    && echo "export CLASSPATH=$SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf" >   $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/bin/setenv.sh  \
    && cp $SMP_HOME/smp-$SMP_VERSION/smp.config.properties  $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/  \
    && cp $SMP_HOME/smp-$SMP_VERSION/sample_signatures_keystore.jks  $SMP_HOME/apache-tomcat-$TOMCAT_VERSION/smp/conf/

VOLUME ["/data"]

COPY ./entrypoint.sh /sbin/entrypoint.sh  \
    && chmod u+x /sbin/entrypoint.sh

EXPOSE 3306 8080

ENTRYPOINT ["/sbin/entrypoint.sh"]

