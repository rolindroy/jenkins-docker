########################################################
# @Author: Rolind Roy <rolindroy>
# @Date:   2019-02-07T12:06:37+05:30
# @Email:  hello@rolindroy.com
# @Filename: Dockerfile
# @Last modified by:   rolindroy
# @Last modified time: 2019-02-07T12:07:12+05:30
#######################################################
# Docker file for Jenkins
#######################################################

# Using parent image as openjdk:8-jdk-stretch
FROM openjdk:8-jdk-stretch

# Dockerfile Maintainer
MAINTAINER Rolind Roy

# Setting default arguments.
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home

# Running updates
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Setting Environment variable for jenkins home directory.
# And Jenkins slave port
ENV JENKINS_HOME $JENKINS_HOME
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}

# Creating jenkins user and home directory with user and group permission.
RUN mkdir -p $JENKINS_HOME \
  && chown ${uid}:${gid} $JENKINS_HOME \
  && groupadd -g ${gid} ${group} \
  && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Setting persisted volume for Jenkins Home directory
VOLUME $JENKINS_HOME

# Use tini as subreaper in Docker container to adopt zombie processes
# Ref:- https://github.com/docker-library/official-images#init
ARG TINI_VERSION=v0.16.1
COPY tini_pub.gpg ${JENKINS_HOME}/tini_pub.gpg
RUN curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture) -o /sbin/tini \
  && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture).asc -o /sbin/tini.asc \
  && gpg --no-tty --import ${JENKINS_HOME}/tini_pub.gpg \
  && gpg --verify /sbin/tini.asc \
  && rm -rf /sbin/tini.asc /root/.gnupg \
  && chmod +x /sbin/tini

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy
COPY basic-security.groovy /usr/share/jenkins/ref/init.groovy.d/basic-security.groovy

# Added plugin file
COPY plugin.txt /usr/share/jenkins/ref/plugin.txt
# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.163}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=fdf78f2348d88e6abd7807a3d61c02f2c2faa6b917a2a6018eaf498afd4a9454

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh
COPY tini-shim.sh /bin/tini

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]

# RUN /usr/local/bin/install-plugins.sh /usr/share/jenkins/ref/plugin.txt

RUN /usr/local/bin/install-plugins.sh `tr '\n' ' ' < /usr/share/jenkins/ref/plugin.txt`

# jenkins-admin-user.groovy will creaet admin user with administrator previlage.
# username :admin
# password: admin
COPY jenkins-admin-user.groovy /usr/share/jenkins/ref/init.groovy.d/jenkins-admin-user.groovy
CMD ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
