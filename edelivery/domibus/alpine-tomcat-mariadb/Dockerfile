FROM alpine:3.7
MAINTAINER Joze Rihtarsic


# Set the DOMIBUS_VERSION env variable
ENV DOMIBUS_VERSION=3.3.3 \
    DOMIBUS_DISTRIBUTION_URL=https://ec.europa.eu/cefdigital/artifact/service/local/repositories/eDelivery/content/eu/domibus/domibus-distribution \
    DOMIBUS_SHA1=a9814d969ceb1196b05370ef1427e53fc5508615  \
    DOMIBUS_CONF_SHA1=25a36ea576e0e62dcf3f953fa21f681594c1a217  \
    DOMIBUS_EXAMPLE_SHA1=7eb10e88f5ac0d92469abc291ee1144264a952c6  \
    DOMIBUS_HOME=/opt/domibus \
    MYSQL_DRV_VERSION=5.1.46  \
    MYSQL_DRV_SHA1=9a3e63b387e376364211e96827bc27db8d7a92e9 \
    DB_SCHEMA=domibus \
    DB_USER=edelivery \
    DB_USER_PASSWORD=edelivery \
    MYSQL_ROOT_PASSWORD=root \
    MAX_ALLOWED_PACKET=200M

#download tool 
RUN apk update \
    && apk add mysql \
		mysql-client \
		openjdk8 \
		curl \
		unzip \
    && rm -rf /var/cache/apk/* \
# set users 
    && mkdir -p $DOMIBUS_HOME \
    && addgroup mysql mysql \
    && addgroup tomcat \
    && adduser -D -S -h $DOMIBUS_HOME -G tomcat tomcat \
# set domibus install dir 
    && mkdir -p $DOMIBUS_HOME \
    && cd $DOMIBUS_HOME \
# download domibus, conf, driver
    && curl -O $DOMIBUS_DISTRIBUTION_URL/$DOMIBUS_VERSION/domibus-distribution-$DOMIBUS_VERSION-tomcat-full.zip \
    && sha1sum domibus-distribution-$DOMIBUS_VERSION-tomcat-full.zip | grep $DOMIBUS_SHA1 \
    && curl -O $DOMIBUS_DISTRIBUTION_URL/$DOMIBUS_VERSION/domibus-distribution-$DOMIBUS_VERSION-tomcat-configuration.zip \
    && sha1sum domibus-distribution-$DOMIBUS_VERSION-tomcat-configuration.zip | grep $DOMIBUS_CONF_SHA1 \
    && curl -O $DOMIBUS_DISTRIBUTION_URL/$DOMIBUS_VERSION/domibus-distribution-$DOMIBUS_VERSION-sample-configuration-and-testing.zip \
    && sha1sum domibus-distribution-$DOMIBUS_VERSION-sample-configuration-and-testing.zip | grep $DOMIBUS_EXAMPLE_SHA1 \
    && curl -O https://repo1.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_DRV_VERSION/mysql-connector-java-$MYSQL_DRV_VERSION.jar \
    && sha1sum mysql-connector-java-$MYSQL_DRV_VERSION.jar  | grep $MYSQL_DRV_SHA1 \
# unzip and configure domibus
    && unzip domibus-distribution-$DOMIBUS_VERSION-tomcat-full.zip -d $DOMIBUS_HOME \
    && unzip -o domibus-distribution-$DOMIBUS_VERSION-sample-configuration-and-testing.zip -d $DOMIBUS_HOME/domibus \
    && unzip -o domibus-distribution-$DOMIBUS_VERSION-tomcat-configuration.zip -d $DOMIBUS_HOME/domibus/conf/domibus \
    && cp mysql-connector-java-$MYSQL_DRV_VERSION.jar -d $DOMIBUS_HOME/domibus/lib  \
    && echo "export CATALINA_HOME=`readlink -f $DOMIBUS_HOME`/domibus" >> "$DOMIBUS_HOME/domibus/bin/setenv.sh" \
    && echo "JAVA_OPTS=\"\$JAVA_OPTS -Xms4096m -Xmx4096m -XX:MaxPermSize=4096m -Ddomibus.config.location=\$CATALINA_HOME/conf/domibus\"" >> "$DOMIBUS_HOME/domibus/bin/setenv.sh" \
    && rm -rf $DOMIBUS_HOME/*.zip \
# set mariadb 
    && /usr/bin/mysql_install_db --user=mysql \
    && sed -i "s|max_allowed_packet\s*=\s*1M|max_allowed_packet = ${MAX_ALLOWED_PACKET}|g" /etc/mysql/my.cnf  \
    && sed -i "s|max_allowed_packet\s*=\s*16M|max_allowed_packet = ${MAX_ALLOWED_PACKET}|g" /etc/mysql/my.cnf 


VOLUME ["/data"]

COPY ./entrypoint.sh /sbin/entrypoint.sh\
    && chmod u+x /sbin/entrypoint.sh

EXPOSE 3306 8080

ENTRYPOINT ["/sbin/entrypoint.sh"]
