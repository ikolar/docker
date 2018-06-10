FROM ubuntu:16.04

MAINTAINER Joze Rihtarsic


ENV SML_VERSION=3.1.2 \
    SML_DISTRIBUTION_URL=https://ec.europa.eu/cefdigital/artifact/content/repositories/eDelivery/eu/europa/ec/bdmsl/bdmsl-webapp \
    SML_SHA1=2000b1db9739e04559b7bf47faffed9abded137e  \
    SMP_VERSION=4.0.0  \
    SMP_DISTRIBUTION_URL=https://ec.europa.eu/cefdigital/artifact/content/repositories/eDelivery/eu/europa/ec/edelivery/smp  \
    SMP_SHA1=52ba09257948233e920638f7a90f9bfa120910ca  \
    SMP_CONF_SHA1=af40537d2874775f2ab34c538682ef7ac50efdb3  \
    DATA_DIR=/data  \
    BIND_USER=bind  \
    SERVER_USER=tomcat  \
    TOMCAT_MAJOR=8  \
    TOMCAT_VERSION=8.5.31 \
    TOMCAT_SHA512=51d8877782bc975b8c566263df7e55f383e617aa3c81ea2c219fed18e1f5d9e8233a92100de95b9a8df69ce5c0ad89a195d5b7e5647fcf9df26231870073a9cb \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ \
    MYSQL_DRV_VERSION=5.1.46  \
    MYSQL_DRV_SHA1=9a3e63b387e376364211e96827bc27db8d7a92e9 \
    DB_SML_SCHEMA=bdmsl \
    DB_SML_USER=sml \
    DB_SML_PASSWORD=sml \
    DB_SMP_SCHEMA=smp \
    DB_SMP_USER=smp \
    DB_SMP_PASSWORD=smp \
    MYSQL_ROOT_PASSWORD=root 

ENV TOMCAT_HOME=/opt/apache-tomcat-$TOMCAT_VERSION  

COPY bdmsl/db.changelog-master.xml /temp/db.changelog-master.xml
COPY bdmsl/db.init-data-inserts.xml /temp/db.init-data-inserts.xml
COPY bdmsl/db.changelog-update-3.1.RC1.xml.bugfix /temp/db.changelog-update-3.1.RC1.xml


RUN apt-get update \
# get utils, bind9, java, mysql 
   && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      	bind9 \
        bind9utils  \
        mysql-server \
        openjdk-8-jdk \
	unzip \
        wget \
  	libapr1 \
	libapr1-dev \
	libssl-dev \
	gcc \
	make \
   && rm -rf /var/lib/apt/lists/* \
# create user
   && groupadd $SERVER_USER \
   && useradd -s /bin/false -g $SERVER_USER -d /opt/tomcat $SERVER_USER \
# get tomcat, mysql driver, bdmsl 
   && cd /opt \
   && wget -O /opt/tomcat.zip "https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.zip" \
   && sha512sum /opt/tomcat.zip | grep $TOMCAT_SHA512 \
   && wget -O mysql-connector-java-$MYSQL_DRV_VERSION.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_DRV_VERSION/mysql-connector-java-$MYSQL_DRV_VERSION.jar \
   && sha1sum mysql-connector-java-$MYSQL_DRV_VERSION.jar  | grep $MYSQL_DRV_SHA1 \
   && wget -O "edelivery-sml.war" "$SML_DISTRIBUTION_URL/$SML_VERSION/bdmsl-webapp-$SML_VERSION-tomcat-mysql.war"  \
   && sha1sum edelivery-sml.war  | grep $SML_SHA1 \
   && wget -O smp.war "$SMP_DISTRIBUTION_URL/$SMP_VERSION/smp-$SMP_VERSION.war"   \
   && sha1sum smp.war | grep $SMP_SHA1   \
   && wget -O smp-setup.zip "$SMP_DISTRIBUTION_URL/$SMP_VERSION/smp-$SMP_VERSION-setup.zip"    \
   && sha1sum smp-setup.zip | grep $SMP_CONF_SHA1    \
#install server
   && unzip tomcat.zip  \
   && chgrp -R $SERVER_USER "$TOMCAT_HOME" \
   && cd "$TOMCAT_HOME" \
#install SML
   && sed -i -e "s/<\/Context>/<Resource name=\"jdbc\/edelivery\" auth=\"Container\" type=\"javax.sql.DataSource\" maxTotal=\"100\" maxIdle=\"30\" maxWaitMillis=\"10000\" username=\"$DB_SML_USER\" password=\"$DB_SML_PASSWORD\" driverClassName=\"com.mysql.jdbc.Driver\" url=\"jdbc:mysql:\/\/localhost:3306\/$DB_SML_SCHEMA\"\/><\/Context>/g" "$TOMCAT_HOME/conf/context.xml"  \
   && cd "$TOMCAT_HOME" \
   && chmod -R g+r conf \
   && chmod g+x conf \	
   && chown -R $SERVER_USER:$SERVER_USER webapps/ work/ temp/ logs/ \
   && chmod ug+x bin/*.sh  \
   && mv /opt/mysql-connector-java-$MYSQL_DRV_VERSION.jar $TOMCAT_HOME/lib/ \
   && mv /opt/edelivery-sml.war $TOMCAT_HOME/webapps/edelivery-sml.war \
   && rm /opt/tomcat.zip \
   && mkdir -p $TOMCAT_HOME/webapps/WEB-INF/classes/liquibase/ \
   && cp /temp/db.* $TOMCAT_HOME/webapps/WEB-INF/classes/liquibase/ \
   && jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.changelog-master.xml \
   && jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.init-data-inserts.xml \
# bugfix SML for mysql: fixed in 3.1.3
   && jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.changelog-update-3.1.RC1.xml \
   && rm -rf $TOMCAT_HOME/webapps/WEB-INF \
   && mkdir $TOMCAT_HOME/conf/sml \
   && mkdir $TOMCAT_HOME/conf/sml/bindtemplate \
   && echo "[mysqld]" >> /etc/mysql/my.cnf  \
   && echo "lower_case_table_names = 1" >> /etc/mysql/my.cnf  \
   && sed -i -e "s/127.0.0.1/0.0.0.0/g" /etc/mysql/mysql.conf.d/mysqld.cnf \
# setup https for tomcat
   && cd $TOMCAT_HOME/bin \
   && tar xfz tomcat-native.tar.gz \
   && cd tomcat-native-1.2.16-src/native \
   && ./configure && make && make install \
# install SMP
   && unzip /opt/smp-setup.zip -d /opt    \
   && mv /opt/smp.war $TOMCAT_HOME/webapps/     \
   && rm -rf $SMP_HOME/*.zip    \
   && mkdir -p $TOMCAT_HOME/conf/smp/  \
   && echo "export CLASSPATH=$TOMCAT_HOME/conf/smp/" >  $TOMCAT_HOME/bin/setenv.sh  \
   && cp /opt/smp-$SMP_VERSION/smp.config.properties  $TOMCAT_HOME/conf/smp/  \
   && cp /opt/smp-$SMP_VERSION/smp.config.properties  $TOMCAT_HOME/conf/smp/  \
   && cp /opt/smp-$SMP_VERSION/sample_signatures_keystore.jks  $TOMCAT_HOME/conf/smp/ \
# configure  SMP, SML integration
   && sed -i -e "s#bdmsl.integration.enabled=false#bdmsl.integration.enabled=true#g" "$TOMCAT_HOME/conf/smp/smp.config.properties" \
   && sed -i -e "s#bdmsl.integration.url=http://localhost:8080/manageparticipantidentifier#bdmsl.integration.url=http://localhost:8080/edelivery-sml/manageparticipantidentifier#g" "$TOMCAT_HOME/conf/smp/smp.config.properties" \
   && sed -i -e "s#/keystores/sample_signatures_keystore.jks#$TOMCAT_HOME/conf/smp/sample_signatures_keystore.jks#g" "$TOMCAT_HOME/conf/smp/smp.config.properties"  \
   && sed -i -e "s#jdbc:mysql://localhost:3306/smp#jdbc:mysql://localhost:3306/$DB_SMP_SCHEMA#g" "$TOMCAT_HOME/conf/smp/smp.config.properties"   \
   && sed -i -e "s#jdbc.user\s*=\s*smp#jdbc.user=$DB_SMP_USER#g" "$TOMCAT_HOME/conf/smp/smp.config.properties"   \
   && sed -i -e "s#jdbc.password\s*=\s*secret123#jdbc.password=$DB_SMP_PASSWORD#g" "$TOMCAT_HOME/conf/smp/smp.config.properties"  \
# fix logging
   && cd $TOMCAT_HOME/webapps  \
   && jar -xf smp.war WEB-INF/classes/log4j.properties  \
   && sed -i -e "s#log4j.appender.logfile.File\s*=\s*logs/edelivery-smp.log#log4j.appender.logfile.File=../logs/edelivery-smp.log#g" "$TOMCAT_HOME/webapps/WEB-INF/classes/log4j.properties"   \
   && jar -uf smp.war  -C $TOMCAT_HOME/webapps/ WEB-INF/classes/log4j.properties  \
   && rm -rf TOMCAT_HOME/webapps/WEB-INF



# for tomcate native apr for https 
ENV LD_LIBRARY_PATH=/usr/local/apr/lib


COPY bdmsl/keystore.jks $TOMCAT_HOME/conf/sml/keystore.jks 
COPY bdmsl/encriptionPrivateKey.private $TOMCAT_HOME/conf/sml/encriptionPrivateKey.private
COPY bind/db.test.edelivery.local $TOMCAT_HOME/conf/sml/bindtemplate/db.test.edelivery.local 
COPY bind/db.192.168 $TOMCAT_HOME/conf/sml/bindtemplate/db.192.168
COPY bind/named.conf $TOMCAT_HOME/conf/sml/bindtemplate/named.conf 
COPY bind/named.conf.local $TOMCAT_HOME/conf/sml/bindtemplate/named.conf.local
COPY entrypoint.sh /sbin/entrypoint.sh 

RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 53/udp 53/tcp 3306 8080 8443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/usr/sbin/named"]
