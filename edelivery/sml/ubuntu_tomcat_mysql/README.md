# Experiamental SML docker image for service meta data locator SML.
Purpose of image is to help SMP and AP sofware developers to create development environment for localy testing Dynamic Discovery using SML and SMP.
Image uses latest version of eDelivery SML setup on tomcat, mysql ubuntu also contains Bind DNS server to setup working local environment for dynamic discover. 
Bind domain is setup to domain: test.edelivery.local

# Image build

docker build -t sml .

# Run container based on sml image
docker run --name sml -it --rm -p [http-port]:8080 -p [https-port]:8443 -p [mysql-port]:3306 -p [dns-port]:53/udp -p [dns-port]:53/tcp -v [local volume]:/data sml
example:
docker run --name sml -it --rm -p 8080:8080 -p 8443:8443 -p 3306:3306 -p 53:53/udp -p 53:53/tcp -v /opt/dockerdata/sml:/data sml

## SML (param: -p 8080:8080 -p 8443:8443)
url: http://localhost:8080/edelivery-sml/
For testing https authentication:
url: https://localhost:8443/edelivery-sml/

## MYSQL (param: -p 3306:3306)
Database client connection (for testing and debugging )
url: jdbc:mysql://localhost:3306/bdmsl
Username: sml
Password:  sml

## Local dns server (-p 53:53/udp -p 53:53/tcp)

Default domain for bind is test.edelivery.local and ip: 192.168.56.102. 
To change initial network sertings alter configuration in bind folder and rebuild image


## Volume (-v /opt/dockerdata/sml:/data)
Mysql database files, bind configuration files and tomcat configuration (and logs) can be externalized for experimenting with different SML settings.




