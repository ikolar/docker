FROM alpine:3.7
MAINTAINER Joze Rihtarsic


# Set the LAURENTIUS_VERSION env variable
ENV LAURENTIUS_VERSION=2.0.6 \
    LAURENTIUS_BUILD_VERSION=2.0-20180320_1439 \
    LAURENTIUS_DISTRIBUTION_URL=https://github.com/VsrsCif/Laurentius/releases/download/ \
    LAURENTIUS_SHA256=866e2d4fac5ef6bfec42a244acd0839cb636f7e13c6f55133e852caec0dd9a5f  \
    INSTALL_FOLDER=/opt/servers \ 
    DOMAIN=test.laurentius.si \
    WILDFLY_VERSION=11.0.0.Final  \
    WILDFLY_SHA256=d9144a241d533ffb486fc884955bcc5725158e941f600b784742c6378935e217  
  
ENV WILDFLY_HOME=$INSTALL_FOLDER/wildfly-$WILDFLY_VERSION

#download tool 
RUN  apk update \
    && apk add openjdk8 \
		curl \
		unzip \
    && rm -rf /var/cache/apk/* \
# set users \
    &&  mkdir -p $INSTALL_FOLDER \
    && cd $INSTALL_FOLDER  \
    && addgroup lovro \
    && adduser -D -S -h $INSTALL_FOLDER -G lovro lovro \
# set LAURENTIUS install dir 
    && mkdir -p $INSTALL_FOLDER \
    && cd $INSTALL_FOLDER \
# download laurentius, wildfly , driver  
    && curl -L -O https://github.com/VsrsCif/Laurentius/releases/download/$LAURENTIUS_VERSION/Laurentius-$LAURENTIUS_BUILD_VERSION.zip  \
    && sha256sum Laurentius-$LAURENTIUS_BUILD_VERSION.zip | grep $LAURENTIUS_SHA256  \
    && curl -O http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.zip  \
    && sha256sum wildfly-$WILDFLY_VERSION.zip | grep $WILDFLY_SHA256 \
# unzip and configure LAURENTIUS
    && unzip Laurentius-$LAURENTIUS_BUILD_VERSION.zip  \
    && unzip wildfly-$WILDFLY_VERSION.zip \
    && rm Laurentius-$LAURENTIUS_BUILD_VERSION.zip  wildfly-$WILDFLY_VERSION.zip \
    && cd  Laurentius-$LAURENTIUS_BUILD_VERSION/wildfly-11.0/ \
    && chmod u+x *.sh \
    && ./deploy-laurentius.sh --init -s "../../wildfly-$WILDFLY_VERSION" \
    && chown -R lovro $INSTALL_FOLDER/wildfly-$WILDFLY_VERSION

   

VOLUME ["/data"]

COPY ./entrypoint.sh /sbin/entrypoint.sh
RUN chmod u+x /sbin/entrypoint.sh

EXPOSE 8080 8081 8443

ENTRYPOINT ["/sbin/entrypoint.sh"]
#ENTRYPOINT ["/bin/sh"]
