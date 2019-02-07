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
