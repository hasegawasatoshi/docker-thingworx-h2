FROM ubuntu:latest
MAINTAINER shasegawa <shasegawa@ptc.com>

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
    && apt-get update \
    && apt-get install -y software-properties-common python-software-properties \
    && add-apt-repository ppa:webupd8team/java \
    && apt-get update \
    && apt-get install -y oracle-java8-installer

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.41
ENV TOMCAT_TGZ_URL http://www-eu.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

WORKDIR /tmp
RUN wget -O tomcat.tar.gz $TOMCAT_TGZ_URL \
    && mkdir -p /usr/share/tomcat8/$TOMCAT_VERSION \
    && tar xf tomcat.tar.gz -C /usr/share/tomcat8/$TOMCAT_VERSION --strip-components=1 \
    && rm tomcat.tar.gz

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV CATALINA_HOME /usr/share/tomcat8/$TOMCAT_VERSION

WORKDIR $CATALINA_HOME

RUN addgroup --system tomcat8 --quiet \
    && adduser --system --home /usr/share/tomcat8 --no-create-home --ingroup tomcat8 --disabled-password --shell /bin/false tomcat8 \
    && chown -Rh tomcat8:tomcat8 bin/ lib/ webapps/ \
    && chmod 775 bin/ lib/ webapps \
    && chown -R root:tomcat8 conf/ \
    && chmod 640 conf/* \
    && chown -R tomcat8:adm logs/ temp/ work/ \
    && chmod 750 logs/ temp/ work/ \
    && echo "export JAVA_OPTS=\"-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dserver -Dd64 -XX:+UseNUMA -XX:+UseConcMarkSweepGC -Dfile.encoding=UTF-8 -Djava.library.path=./webapps/Thingworx/WEB-INF/extensions\"" > ./bin/setenv.sh \
    && echo "export JRE_HOME=/usr/lib/jvm/java-8-oracle/jre" >> ./bin/setenv.sh \
    && sed -e 's/<Connector port="8080" protocol="HTTP\/1.1"/<Connector port="8080" protocol="org.apache.coyote.http11.Http11NioProtocol"/g' conf/server.xml \
    && mkdir /ThingworxStorage \
    && chown tomcat8:tomcat8 /ThingworxStorage \
    && mkdir /ThingworxBackupStorage \
    && chown tomcat8:tomcat8 /ThingworxBackupStorage \
    && mkdir /ThingworxPlatform \
    && chown tomcat8:tomcat8 /ThingworxPlatform

ADD Thingworx.war ./webapps
ADD license.bin /ThingworxPlatform

EXPOSE 8080

USER tomcat8
CMD ./bin/startup.sh && wait && tail -f ./logs/catalina.out
