# Jenkins Docker image
The Jenkins Continuous Integration and Delivery server [available on Docker Hub](https://hub.docker.com/r/jenkins/jenkins).

This is a fully functional Jenkins server.
[https://jenkins.io/](https://jenkins.io/).

<img src="https://jenkins.io/sites/default/files/jenkins_logo.png"/>

This is a modified version of jenkins docker image which will disable the setup wizard and "unlock" Jenkins.

# Usage

```
docker run -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home rolindroy/jenkins:2.150.2
```
You can now access you jenkins console http://localhost:8080

```
Default Credentials:

  Username: admin
  Password: admin
```
  
## Setup Wizard

In order to really disable the setup wizard and "unlock" Jenkins you should also use a Groovy init script with contents like:
```
#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.getInstance()

instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
```

```Dockerfile
COPY basic-security.groovy /usr/share/jenkins/ref/init.groovy.d/basic-security.groovy
```
More details available following this [link](https://riptutorial.com/jenkins/example/24925/disable-setup-wizard)
## Preinstalling plugins
You can rely on the `install-plugins.sh` script to pass a set of plugins to download with their dependencies.
This script will perform downloads from update centers, and internet access is required for the default update centers.
You can specify your plugins in [plugin.txt](https://github.com/rolindroy/dockerhub-autobuild-jenkins/blob/master/plugin.txt) and use as below.


### Script usage

You can run the script manually in Dockerfile:

```Dockerfile
FROM rolindroy/jenkins:2.150.2
RUN /usr/local/bin/install-plugins.sh docker-slaves github-branch-source:1.8
```

Furthermore it is possible to pass a file that contains this set of plugins (with or without line breaks).

```Dockerfile
FROM rolindroy/jenkins:2.150.2
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
```
## Create Admin User

In order to create admin user in Jenkins you should also use a Groovy init script with contents like:
```
#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin","admin")
instance.setSecurityRealm(hudsonRealm)
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, "admin")
instance.setAuthorizationStrategy(strategy)
instance.save()

```

```Dockerfile
COPY jenkins-admin-user.groovy /usr/share/jenkins/ref/init.groovy.d/jenkins-admin-user.groovy
CMD ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
```
This will create a user `admin` with administrator previlage.

# Documentation

For more documentation, Please Jump on [Official Github](https://github.com/jenkinsci/docker/blob/master/README.md)
