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
- Sonarqube 6.7.4
- Sonar scanner 3.0.3
- gcc *latest*
- make *latest*
- cppcheck *latest*
- vera++ *latest*
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

## SonarQube extensions
- Sonar CNES Report 1.1

## SonarQube plugins
- Checkstyle sonar plugin 3.7
- Sonar CNES CXX plugin 1.1
- Sonar CNES Export plugin 1.1
- Sonar CNES Python plugin 1.1
- Sonar CNES Scan plugin 1.2
- Sonar Corbetura plugin 1.9.1
- Sonar C# plugin 6.1.0.2359
- Sonar CXX plugin 0.9.7
- Sonar Findbugs plugin
- Sonar Flex plugin
- Sonar Java plugin 4.11.0.10660
- Sonar JavaScript plugin 3.1.1.5128
- Sonar PHP plugin 2.10.0.2087
- Sonar PMD plugin 2.6
- Sonar Python plugin 1.8.0.149



