[![Build Status](https://travis-ci.org/lequal/docker-cat.svg?branch=master)](https://travis-ci.org/lequal/docker-cat)
# docker-cat
Docker Code Analysis Tools (CAT) is a SonarQube docker image containing configuration to realize code analysis.
# Quick install
Step by step : 

Find group IDs to allow SonarQube analysis to (for Sonar CNES Scan plugin):
* Using `getent group <group_name> | cut -d : -f3` to reach a group id from a known group name;
* Using `cat /etc/group`to list all group IDs.

Run a container :
```
docker pull lequal/docker-cat
docker run -v <host_project_folder>:/media/sf_Shared:rw -p 9000:9000 -p 9001:9001 -e ALLOWED_GROUPS="<GID_1>;<GID_2>;<GID_...>" lequal/docker-cat
```
Once the container is active, use the [Sonar CNES Scan plugin](https://github.com/lequal/sonar-cnes-scan-plugin) documentation to run an analysis.

# Content

## Analysis tools
- Sonarqube 7.9.1
- Sonar scanner 3.0.3.778
- gcc *latest*
- make *latest*
- cppcheck *latest*
- vera++ *latest*
- ShellCheck *latest*
- Frama-C 19.0
- expat 2.0.1
- rats 2.4  
- Python :
  - python 2.7.13 
  - colorama 0.3.3
  - python-lazy-object-proxy 1.2.1
  - python-six 1.9.0
  - wrapt 1.10.5
  - astroid 1.4.9
  - pylint 1.5
  - cnes-pylint-extension 1.0
  - python-setuptools *latest*
  
## SonarQube plugins
- Checkstyle sonar plugin 4.21
- Sonar CNES CXX plugin 1.1.0
- Sonar CNES Export plugin 1.2.0
- Sonar CNES Python plugin 1.1.0
- Sonar CNES I-Code plugin 1.3.0
- Sonar CNES Scan plugin 1.5
- Sonar CNES frama-c plugin 2.1.0
- Sonar CNES Report 3.1.0
- Sonar Corbetura plugin 1.9.1
- Sonar C# plugin 7.15
- Sonar CXX plugin 1.1.0
- Sonar Findbugs plugin 3.11.0
- Sonar Flex plugin  2.5.1.1831
- Sonar Java plugin 5.13.1
- Sonar JavaScript plugin 5.2.1
- Sonar PHP plugin 3.2.0.4868
- Sonar PMD plugin 3.2.1
- Sonar Python plugin 1.14.1
- Sonar RCI plugin 1.0.1
- Sonar Typescript plugin 1.9.0.3766
- Sonar Web plugin 3.1
- Sonar XML plugin 2.0.1


