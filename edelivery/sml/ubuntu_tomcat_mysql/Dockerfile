FROM ubuntu:16.04

MAINTAINER jrc


ENV SML_VERSION=3.1.2 \
    SML_DISTRIBUTION_URL=https://ec.europa.eu/cefdigital/artifact/content/repositories/eDelivery/eu/europa/ec/bdmsl/bdmsl-webapp \
    SML_SHA1=2000b1db9739e04559b7bf47faffed9abded137e  \
    DATA_DIR=/data  \
    BIND_USER=bind  \
    TOMCAT_MAJOR=8  \
    TOMCAT_VERSION=8.5.31 \
    TOMCAT_SHA512=51d8877782bc975b8c566263df7e55f383e617aa3c81ea2c219fed18e1f5d9e8233a92100de95b9a8df69ce5c0ad89a195d5b7e5647fcf9df26231870073a9cb \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ \
    MYSQL_DRV_VERSION=5.1.46  \
    MYSQL_DRV_SHA1=9a3e63b387e376364211e96827bc27db8d7a92e9 \
    DB_SCHEMA=bdmsl \
    DB_USER=sml \
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
   && groupadd tomcat \
   && useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat \
# get tomcat, mysql driver, bdmsl 
   && cd /opt \
   && wget -O /opt/tomcat.zip "https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.zip" \
   && sha512sum /opt/tomcat.zip | grep $TOMCAT_SHA512 \
   && wget -O mysql-connector-java-$MYSQL_DRV_VERSION.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_DRV_VERSION/mysql-connector-java-$MYSQL_DRV_VERSION.jar \
   && sha1sum mysql-connector-java-$MYSQL_DRV_VERSION.jar  | grep $MYSQL_DRV_SHA1 \
   && wget -O "edelivery-sml.war" "$SML_DISTRIBUTION_URL/$SML_VERSION/bdmsl-webapp-$SML_VERSION-tomcat-mysql.war"  \
   && sha1sum edelivery-sml.war  | grep $SML_SHA1 \
#install 
   && unzip tomcat.zip  \
   && chgrp -R tomcat "$TOMCAT_HOME" \
   && cd "$TOMCAT_HOME" \
   && sed -i -e "s/<\/Context>/<Resource name=\"jdbc\/edelivery\" auth=\"Container\" type=\"javax.sql.DataSource\" maxTotal=\"100\" maxIdle=\"30\" maxWaitMillis=\"10000\" username=\"$DB_USER\" password=\"$DB_USER\" driverClassName=\"com.mysql.jdbc.Driver\" url=\"jdbc:mysql:\/\/localhost:3306\/$DB_SCHEMA\"\/><\/Context>/g" "$TOMCAT_HOME/conf/context.xml"  \
   && cd "$TOMCAT_HOME" \
   && chmod -R g+r conf \
   && chmod g+x conf \	
   && chown -R tomcat webapps/ work/ temp/ logs/ \
   && chmod ug+x bin/*.sh  \
   && mv /opt/mysql-connector-java-$MYSQL_DRV_VERSION.jar $TOMCAT_HOME/lib/ \
   && mv /opt/edelivery-sml.war $TOMCAT_HOME/webapps/edelivery-sml.war \
   && rm /opt/tomcat.zip \
   && mkdir -p $TOMCAT_HOME/webapps/WEB-INF/classes/liquibase/ \
   && cp /temp/db.* $TOMCAT_HOME/webapps/WEB-INF/classes/liquibase/ \
   && jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.changelog-master.xml \
   && jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.init-data-inserts.xml \
# bugfix for mysql: fixed in 3.1.3
   && jar -uf  $TOMCAT_HOME/webapps/edelivery-sml.war -C $TOMCAT_HOME/webapps/ WEB-INF/classes/liquibase/db.changelog-update-3.1.RC1.xml \
   && rm -rf $TOMCAT_HOME/webapps/WEB-INF \
   && mkdir /opt/smlconf \
   && mkdir /opt/smlconf/bind \
   && echo "[mysqld]" >> /etc/mysql/my.cnf  \
   && echo "lower_case_table_names = 1" >> /etc/mysql/my.cnf  \
   && sed -i -e "s/127.0.0.1/0.0.0.0/g" /etc/mysql/mysql.conf.d/mysqld.cnf
RUN cd $TOMCAT_HOME/bin \
	&& tar xfz tomcat-native.tar.gz \
	&& cd tomcat-native-1.2.16-src/native \
        && ./configure && make && make install 

ENV LD_LIBRARY_PATH=/usr/local/apr/lib


COPY bdmsl/keystore.jks /opt/smlconf/keystore.jks 
COPY bdmsl/encriptionPrivateKey.private /opt/smlconf/encriptionPrivateKey.private
COPY bind/db.test.edelivery.local /opt/smlconf/bind/db.test.edelivery.local 
COPY bind/db.192.168 /opt/smlconf/bind/db.192.168
COPY bind/named.conf /opt/smlconf/bind/named.conf 
COPY bind/named.conf.local /opt/smlconf/bind/named.conf.local
COPY entrypoint.sh /sbin/entrypoint.sh 

RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 53/udp 53/tcp 3306 8080 8443

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/usr/sbin/named"]
