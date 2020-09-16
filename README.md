# Docker CAT
![](https://github.com/cnescatlab/docker-cat/workflows/CI/badge.svg)
![](https://github.com/cnescatlab/docker-cat/workflows/CD/badge.svg)
[![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/lequal/docker-cat/latest)](https://hub.docker.com/r/lequal/docker-cat)

Docker Code Analysis Tool (CAT) is a SonarQube Docker image containing custom configuration and plugins to realize code analysis.

SonarQube is an open platform to manage code quality.

This project is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

You can get SonarQube on GitHub: [SonarSource/sonarqube](https://github.com/SonarSource/sonarqube).

### Table of contents
- [Quick install](#Quick-install)
- [Advanced configuration](#Advanced-configuration)
- [Analyzing source code](#Analyzing-source-code)
- [Image compatibility matrix](#Image-compatibility-matrix)
- [Configuration of the latest image](#Configuration-of-the-latest-image)
- [How to contribute](#How-to-contribute)
- [Feedback and Support](#Feedback-and-Support)
- [License](#License)

### Quick install
1. Find group IDs to allow SonarQube analysis to (for Sonar CNES Scan plugin):
    - Using `getent group <group_name> | cut -d : -f3` to reach a group id from a known group name;
    - Using `cat /etc/group` to list all group IDs.

:exclamation: This group should have `read` and `execution` permissions on all the project to analyze (to browse and analyze all files) and  `write` permissions on the root of the workspace (to execute C/C++ tools and sonar-scanner).

2. Find the version you want to use on DockerHub: https://hub.docker.com/r/lequal/docker-cat or simply use the `latest` image which correspond to the master branch of this project.

3. Run the Docker CAT container:
```
docker pull lequal/docker-cat
docker run --rm --name=cat -v <your_folder>:/media/sf_Shared:rw -p 9000:9000 -e ALLOWED_GROUPS="<GID_1>;<GID_2>;<GID_...>" lequal/docker-cat:<version>
```

:exclamation: This example use `--rm` option so when the container will stop and will be destroyed with all its data.

:exclamation: Avoid using `0` as GUID (e.g.: `-e ALLOWED_GROUPS=0`): it can cause conflicts with container's root user.

### Advanced configuration

#### Default account
You can log in Docker CAT's SonarQube as administrator with the default SonarQube credentials. As it is not secured (everybody knows it!), be sure to run Docker CAT in a secured environment or change the default credentials.
- **username**: `admin`
- **password**: `admin`

> As administrator you are able to change any configuration you want as default values, activated rules or quality gate conditions...

#### Persisting your Docker CAT instance
By default, Docker CAT use the embedded H2 database which is integrated to SonarQube: it should not be use for long term use. That's why if you expect to keep your data for a while, you should consider setting up a stronger database as described in the [official documentation](https://docs.sonarqube.org/setup/install-server/).

### Analyzing source code

#### Using web user interface
Once the container is active, you can use the web interface provided by [Sonar CNES Scan plugin](https://github.com/cnescatlab/sonar-cnes-scan-plugin) to run an analysis directly via your Web browser.

##### 1. If not already done, move your code in `<your_folder>`
> To be reachable by all included tools, your source code must be placed in the previously mounted Docker volume **and** the group whose GUID has been given to `-e ALLOWED_GROUPS=...` parameter should have permissions on the whole directory.

:exclamation: If you encounter some difficulties with permissions on files in mounted volumes (due to your system configuration) you can directly copy your code into the container. Execute the `docker run` command by removing any `-v` or `--volume` options and copy your directory in the directory `/media/sf_Shared` of the container by using this command `docker cp <my_directory> cat:/media/sf_Shared`.

##### 2. Go to Docker CAT web interface
> Just open your favourite web browser and access the SonarQube interface by typing the Docker CAT IP/URL followed by `:` and the port mapped to the port 9000 of the container. If you start Docker CAT on your workstation with the default previously proposed command you should have type `http://localhost:9000` in your address bar.

##### 3. Go to CNES Analysis page
> When SonarQube has loaded, click on `More` in the black upper toolbar and select `CNES Analysis`. A new page should appear with the analysis form.

![CNES Analysis menu](/img/cnes-menu.png)

##### 4. Fill in the form
> Fill in the form by paying attention to:
> - fields with a red asterisk: they are mandatory
> - `Workspace` fields: by default let a point `.` in this field. If you want to limit the scope of the analysis, type the relative path from the `/mnt/sf_Shared` directory.
> - `Workspace` fields: by default let a point `.` in this field. If you want to limit the files/path considered as source files (by opposition to test files), type a coma-separated list of relative path starting from the `Workspace` directory.
> - `Run C/C++ tools`: turn on ths button if you want to run embedded tools (cppcheck, vera++ and rats). If you analyze C or C++ code and you already have cppcheck, vera++ or rats results in your working directory you can use the `sonar-project.properties` field to designate the location of these results and turn off the analysis. Refer to [sonar-cxx documentation](https://github.com/SonarOpenCommunity/sonar-cxx) for further information.
> - `sonar-project.properties` field: use this field to add more advanced configuration. Refer to [official documentation](https://docs.sonarqube.org/latest/analysis/analysis-parameters/).

![CNES Analysis form](/img/cnes-form.png)

##### 5. Run the analysis
> Just click on the `Analyze` button on the bottom of the page to run the analysis. When successfully run, an archive download should start in your web browser. It contains all the results of your analysis. If you already have analysis in your CAT instance, you can regenerate the report without rerunning analysis by using form in `More` > `CNES Report`.

#### Using classical way
You can run an analysis with the classic method by using one of scanners provided by SonarSource. You simply have to give the `URL` or `IP` where Docker CAT has been launched and the matching port you give in your docker command for port `9000`. For more information use SonarSource's scanners as described in the [official documentation](https://docs.sonarqube.org/display/SONAR/Analyzing%20Source%20Code).

:exclamation: With these methods, autolaunched tools like `cppcheck`, `vera++`, `rats` and `frama-c` may not work, if they are not correctly set.

### Image compatibility matrix

> This table list operating system on which Docker CAT has been tested (marked as :heavy_check_mark:) or not (marked as:question:) or simply not supported (marked as :x:).

| Docker CAT version       | Linux (Centos & Debian) | Mac OS                   | Windows                 |
|:------------------------:|:-----------------------:|:------------------------:|:-----------------------:|
| `2.1.0`                  | :heavy_check_mark:      | :question:               | :question:              |
| `2.0.2`                  | :heavy_check_mark:      | :question:               | :question:              |
| `2.0.1`                  | :heavy_check_mark:      | :question:               | :question:              |
| `< 2.0.0`                | :heavy_check_mark:      | :question:               | :heavy_check_mark:      |
                             

### Configuration of the latest image

> New and updated software are marked with emoji :new:.

| Tool                                                  | Version                                               | 
|-------------------------------------------------------|-------------------------------------------------------|
| SonarQube                                             | `7.9.3`                                               |
| Sonar Scanner                                         | `4.2.0.1873`                                          |
| gcc                                                   | `4:9.2.1`                                             |
| make                                                  | `4.2.1`                                               |
| Cppcheck                                              | `1.90`                                                |
| vera++                                                | `1.2.1`                                               |
| ShellCheck                                            | `0.7.1`                                               |
| i-Code CNES                                           | `4.1.0`                                               |
| Frama-C                                               | `20.0`                                                |
| expat                                                 | `2.0.1`                                               |
| rats                                                  | `2.4`                                                 |
| :new: python3                                               | `3.8.3`                                               |
| :new: pip                                                   | `20.1.1`                                              |
| :new: setuptools                                            | `46.1.3`                                              |
| :new: setuptools-scm                                        | `3.5.0`                                               |
| :new: pytest-runner                                         | `5.2`                                                 |
| :new: wrapt                                                 | `1.12.1`                                              |
| :new: six                                                   | `1.14.0`                                              |
| :new: lazy-object-proxy                                     | `1.4.3`                                               |
| :new: mccabe                                                | `0.6.1`                                               |
| :new: isort                                                 | `4.3.21`                                              |
| :new: typed-ast                                             | `1.4.1`                                               |
| :new: astroid                                               | `2.4.0`                                               |
| :new: pylint                                          | `2.5.0`                                               |
| :new: cnes-pylint-extension                           | `5.0.0`                                               |
 
| SonarQube plugin                                      | Version                                               | 
|-------------------------------------------------------|-------------------------------------------------------|
| Checkstyle sonar plugin                               | `4.21`                                                |
| Sonar CNES CXX plugin                                 | `1.3.1.1807`                                          |
| Sonar CNES Export plugin                              | `1.2.0`                                               |
| Sonar CNES Python plugin                              | `1.3.0`                                               |
| Sonar CNES i-Code plugin                              | `2.0.2`                                               |
| Sonar CNES Scan plugin                                | `1.5`                                                 |
| Sonar CNES frama-c plugin                             | `2.1.1`                                               |
| Sonar CNES Report                                     | `3.2.2`                                               |
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

All details are available in [CONTRIBUTING](https://github.com/cnescatlab/docker-cat/CONTRIBUTING.md).

### Feedback and Support
Bugs and Feature requests: https://github.com/cnescatlab/docker-cat/issues

### License
Licensed under the [GNU General Public License, Version 3.0](https://www.gnu.org/licenses/gpl.txt)
