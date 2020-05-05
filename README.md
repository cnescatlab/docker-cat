# Docker CAT
[![Build Status](https://travis-ci.org/lequal/docker-cat.svg?branch=master)](https://travis-ci.org/lequal/docker-cat)
[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/lequal/docker-cat/latest)](https://hub.docker.com/r/lequal/docker-cat)

Docker Code Analysis Tool (CAT) is a SonarQube Docker image containing configuration to realize code analysis.

SonarQube is an open platform to manage code quality.

This project is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

You can get SonarQube on GitHub: [SonarSource/sonarqube](https://github.com/SonarSource/sonarqube).


### Quick install
Step by step: 

1. Find group IDs to allow SonarQube analysis to (for Sonar CNES Scan plugin):
* Using `getent group <group_name> | cut -d : -f3` to reach a group id from a known group name;
* Using `cat /etc/group`to list all group IDs.

2. Run the Docker CAT container:
```
docker pull lequal/docker-cat
docker run --rm --name=cat -v <host_project_folder>:/media/sf_Shared:rw -p 9000:9000 -p 9001:9001 -e ALLOWED_GROUPS="<GID_1>;<GID_2>;<GID_...>" lequal/docker-cat
```

### Analyzing source code

Once the container is active:
- use the [Sonar CNES Scan plugin](https://github.com/lequal/sonar-cnes-scan-plugin) documentation to run an analysis via your Web browser
- use SonarSource's scanners as described in the [official documentation](https://docs.sonarqube.org/display/SONAR/Analyzing%20Source%20Code)

### Image compatibility matrix

> This table list operating system on which Docker CAT has been tested (marked as :heavy_check_mark:) or not (marked as:question:) or simply not supported (marked as :x:).

| Docker CAT version       | Linux (Centos & Debian) | Mac OS                   | Windows                 |
|:------------------------:|:-----------------------:|:------------------------:|:-----------------------:|
| `< 2.0.0`                | :heavy_check_mark:      | :question:               | :heavy_check_mark:      |
| `2.0.1`                  | :heavy_check_mark:      | :question:               | :question:              |
| `2.0.2`                  | :heavy_check_mark:      | :question:               | :question:              |
| `2.1.0`                  | :heavy_check_mark:      | :question:               | :question:              |
                             

### Configuration of the latest image

> New and updated software are marked with emoji :new:.

| Tool                                                  | Version                                               | 
|-------------------------------------------------------|-------------------------------------------------------|
| :new:SonarQube                                        | `7.9.3`                                               |
| :new:Sonar Scanner                                    | `4.2.0.1873`                                          |
| gcc                                                   | `4:8.3.0-1`                                           |
| make                                                  | `4.2.1-1.2`                                           |
| :new:Cppcheck                                         | `1.90-4`                                              |
| :new:vera++                                           | `1.2.1-2+b5`                                          |
| :new:ShellCheck                                       | `0.5.0-3`                                             |
| :new:i-Code CNES                                      | `4.1.0`                                               |
| :new:Frama-C                                          | `19.1`                                                |
| expat                                                 | `2.0.1`                                               |
| rats                                                  | `2.4`                                                 |
| python                                                | `2.7.13`                                              |
| colorama                                              | `0.3.3`                                               |
| python-lazy-object-proxy                              | `1.2.1`                                               |
| python-six                                            | `1.9.0`                                               |
| wrapt                                                 | `1.10.5`                                              |
| astroid                                               | `1.4.9`                                               |
| Pylint                                                | `1.5`                                                 |
| cnes-pylint-extension                                 | `1.0`                                                 |
| python-setuptools                                     | `40.8.0-1`                                            |
 
| SonarQube plugin                                      | Version                                               | 
|-------------------------------------------------------|-------------------------------------------------------|
| Checkstyle sonar plugin                               | `4.21`                                                |
| Sonar CNES CXX plugin                                 | `1.3.1.1807`                                          |
| Sonar CNES Export plugin                              | `1.2.0`                                               |
| :new:Sonar CNES Python plugin                         | `1.3.0`                                               |
| :new:Sonar CNES i-Code plugin                         | `2.0.2`                                               |
| Sonar CNES Scan plugin                                | `1.5`                                                 |
| :new:Sonar CNES frama-c plugin                        | `2.1.1`                                               |
| :new:Sonar CNES Report                                | `3.2.2`                                               |
| Sonar Corbetura plugin                                | `1.9.1`                                               |
| Sonar C# plugin                                       | `7.15`                                                |
| Sonar CXX plugin                                      | `1.1.0`                                               |
| Sonar Findbugs plugin                                 | `3.11.0`                                              |
| Sonar Flex plugin                                     | `2.5.1.1831`                                          |
| Sonar Java plugin                                     | `5.13.1`                                              |
| Sonar JavaScript plugin                               | `5.2.1`                                               |
| Sonar PHP plugin                                      | `3.2.0.4868`                                          |
| Sonar PMD plugin                                      | `3.2.1`                                               |
| Sonar Python plugin                                   | `1.14.1`                                              |
| Sonar RCI plugin                                      | `1.0.1`                                               |
| Sonar Typescript plugin                               | `1.9.0.3766`                                          |
| Sonar Web plugin                                      | `3.1`                                                 |
| Sonar XML plugin                                      | `2.0.1`                                               |

### How to contribute
If you experienced a problem with the plugin please open an issue. Inside this issue please explain us how to reproduce this issue and paste the log. 

If you want to do a PR, please put inside of it the reason of this pull request. If this pull request fix an issue please insert the number of the issue or explain inside of the PR how to reproduce this issue.

All details are available in [CONTRIBUTING](https://github.com/lequal/docker-cat/CONTRIBUTING.md).

### Feedback and Support
Contact : L-lequal@cnes.fr

Bugs and Feature requests: https://github.com/lequal/docker-cat/issues

### License
Licensed under the [GNU General Public License, Version 3.0](https://www.gnu.org/licenses/gpl.txt)
