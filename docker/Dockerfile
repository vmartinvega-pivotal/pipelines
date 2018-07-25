# Pull base image.
FROM pivotalservices/docker-concourse-cf-tools

RUN \
  apt-get update \
  && apt-get -y install gettext-base \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install unzip
RUN \
  apt-get update \
  && apt-get install unzip -y

# Install groovy
RUN \
  apt-get update \
  && apt-get install tar \
  && apt-get install groovy -y

# Installs Ant
COPY apache-ant-1.10.4-bin.tar.gz /tmp/apache-ant-1.10.4-bin.tar.gz

RUN \
    cd /tmp \
    && tar -xzf apache-ant-1.10.4-bin.tar.gz \
    && mv apache-ant-1.10.4 /opt/ant \
    && rm apache-ant-1.10.4-bin.tar.gz
ENV ANT_HOME /opt/ant
ENV PATH ${PATH}:/opt/ant/bin

# Install ruamel.yaml
RUN \
  apt-get update \
  && apt-get install software-properties-common -y

RUN \
  apt-add-repository universe -y

RUN \
  apt-get update \
  && apt-get install python-pip -y

RUN pip install -U pip setuptools wheel

RUN pip install ruamel.yaml

# Install fly
COPY fly /usr/local/bin

RUN chmod +x /usr/local/bin/fly

# Install SoapUI
ENV SOAPUI_VERSION 5.3.0

COPY SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz /tmp/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz

RUN mkdir -p /opt

RUN gunzip -c /tmp/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz | tar -xf - -C /opt

RUN ln -s /opt/SoapUI-${SOAPUI_VERSION} /opt/SoapUI

ENV PATH ${PATH}:/opt/SoapUI/bin

RUN rm -f /tmp/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz

# Add common jar libraries to SoapUI
COPY SoapUI-ext-common-libraries.zip /tmp/SoapUI-ext-common-libraries.zip

RUN \
  unzip /tmp/SoapUI-ext-common-libraries.zip -d /opt/SoapUI/bin

RUN rm -f /tmp/SoapUI-ext-common-libraries.zip
  

# Install Subversion
RUN \
  apt-get update \
  && apt-get install subversion -y

# Install Java.
RUN \
  apt-get update \
  && apt-get install software-properties-common -y

RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer


# Define working directory.
WORKDIR /data

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Define default command.
CMD ["bash"]


ARG MAVEN_VERSION=3.5.3
ARG USER_HOME_DIR="/root"
ARG SHA=b52956373fab1dd4277926507ab189fb797b3bc51a2a267a193c931fffad8408
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
COPY settings-docker.xml /usr/share/maven/ref/

ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
CMD ["mvn"]
