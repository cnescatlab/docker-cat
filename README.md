# Docker CAT

![Workflow CI Badge](https://github.com/cnescatlab/docker-cat/workflows/CI/badge.svg)
![Workflow CD Badge](https://github.com/cnescatlab/docker-cat/workflows/CD/badge.svg)
[![Docker Image Version (tag latest)](https://img.shields.io/docker/v/lequal/docker-cat/latest)](https://hub.docker.com/r/lequal/docker-cat)

Docker Code Analysis Tool (CAT) is a SonarQube Docker image containing custom configuration and plugins to realize code analysis.

SonarQube is an open platform to manage code quality.

This project is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

You can get SonarQube on GitHub: [SonarSource/sonarqube](https://github.com/SonarSource/sonarqube).

## Table of contents

- [Quick install](#quick-install)
- [Advanced configuration](#advanced-configuration)
- [Analyzing source code](#analyzing-source-code)
- [Image compatibility matrix](#image-compatibility-matrix)
- [Configuration of the latest image](#configuration-of-the-latest-image)
- [How to contribute](#how-to-contribute)
- [Feedback and Support](#feedback-and-support)
- [License](#license)

### Quick install

1. Find group IDs to allow SonarQube analysis to (for Sonar CNES Scan plugin):
   - Using `getent group <group_name> | cut -d : -f3` to reach a group id from a known group name;
   - Using `cat /etc/group` to list all group IDs.

   :exclamation: This group should have `read` and `execution` permissions on all the project to analyze (to browse and analyze all files) and `write` permissions on the root of the workspace (to execute C/C++ tools and sonar-scanner).

2. Find the version you want to use on DockerHub: <https://hub.docker.com/r/lequal/docker-cat> or simply use the `latest` image which correspond to the master branch of this project.

3. Run the Docker CAT container:

```shell
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

Once the container is active, you can use the web interface provided by [Sonar CNES Scan plugin](https://github.com/cnescatlab/sonar-cnes-scan-plugin) to run an analysis directly via your Web browser. #TODO

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
>
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

:exclamation: With these methods, autolaunched tool like `cppcheck` may not work, if they are not correctly set.

### Image compatibility matrix

> This table list operating system on which Docker CAT has been tested (marked as :heavy_check_mark:) or not (marked as:question:) or simply not supported (marked as :x:).

| Docker CAT version | Linux (Centos & Debian) |   Mac OS   |      Windows       |
| :----------------: | :---------------------: | :--------: | :----------------: |
|      `3.2.2`       |   :heavy_check_mark:    | :question: |     :question:     |
|      `3.0.0`       |   :heavy_check_mark:    | :question: |     :question:     |
|      `2.1.0`       |   :heavy_check_mark:    | :question: |     :question:     |
|      `2.0.2`       |   :heavy_check_mark:    | :question: |     :question:     |
|      `2.0.1`       |   :heavy_check_mark:    | :question: |     :question:     |
|     `< 2.0.0`      |   :heavy_check_mark:    | :question: | :heavy_check_mark: |

### Configuration of the latest image

> New and updated software are marked with emoji :new:.

| Tools                       | Versions   |
| --------------------------- | ---------- |
| :new: SonarQube-catlab      | 3.2.2      |
| :new: Sonar Scanner         | 5.0.1.3006 |
| :new: Cppcheck              | 2.13.0     |
| :new: i-Code CNES           | 4.1.2      |
| python3                     | 3.10.4     |
| pip                         | 22.0.2     |
| setuptools-scm              | 7.1.0      |
| pytest-runner               | 6.0.0      |
| wrapt                       | 1.15.0     |
| six                         | 1.16.0     |
| lazy-object-proxy           | 1.9.0      |
| mccabe                      | 0.7.0      |
| isort                       | 5.12.0     |
| typed-ast                   | 1.5.4      |
| astroid                     | 2.15.2     |
| pylint                      | 2.17.2     |
| cnes-pylint-extension       | 6.0.0      |
| make                        | 4.3        |
| gcc                         | 4:11.2.0   |
| ShellCheck                  | 0.8.0      |

### How to contribute

If you experienced a problem with the plugin please open an issue. Inside this issue please explain us how to reproduce this issue and paste the log.

If you want to do a PR, please put inside of it the reason of this pull request. If this pull request fix an issue please insert the number of the issue or explain inside of the PR how to reproduce this issue.

All details are available in [CONTRIBUTING](https://github.com/cnescatlab/docker-cat/CONTRIBUTING.md).

### Feedback and Support

Bugs and Feature requests: <https://github.com/cnescatlab/docker-cat/issues>

### License

Licensed under the [GNU General Public License, Version 3.0](https://www.gnu.org/licenses/gpl.txt)
