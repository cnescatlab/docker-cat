# This image is based on a LTS version of SonarQube
FROM sonarqube:9.9.4-community

LABEL maintainer="CNES CAT Lab"

ENV HOME=/home/sonarqube \
    SONAR_SCANNER_HOME=/opt/sonar-scanner \
    SONAR_USER_HOME=/opt/sonar-scanner/.sonar \
    PATH="$PATH:/opt/sonar-scanner/bin:/usr/local/bin" \
    PYTHONPATH="$PYTHONPATH:/opt/python/cnes-pylint-extension-6.0.0/checkers/" \
    PYLINTHOME="$HOME/.pylint.d"

USER root
COPY conf/. /tmp/conf/


## ====================== DOWNLOAD DEPENDENCIES ===============================
# Tools versions
ARG ANSIBLE_LINT=2.5.1
ARG CXX_VERSION=2.1.0
ARG CXX_VERSION_FULL=${CXX_VERSION}.428
ARG CHECKSTYLE_VERSION=10.9.3
ARG CLOVER_VERSION=4.1
ARG COBERTURA_VERSION=2.0
ARG BRANCH_VERSION=1.14.0
ARG FINDBUGS_VERSION=4.2.3
ARG PMD_VERSION=3.4.0
ARG SHELLCHECK_VERSION=2.5.0
ARG ICODE_VERSION=3.1.1
ARG CNESREPORT_VERSION=4.2.0
ARG SONARTS_VERSION_REPO=2.1.0.4359
ARG SONARTS_VERSION=2.1.0.4362
ARG VHDLRC_VERSION=3.4
ARG YAML_VERSION=1.7.0

# Download SonarQube plugins
ADD https://github.com/sbaudoin/sonar-ansible/releases/download/v${ANSIBLE_LINT}/sonar-ansible-plugin-${ANSIBLE_LINT}.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-${CXX_VERSION}/sonar-cxx-plugin-${CXX_VERSION_FULL}.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/${CHECKSTYLE_VERSION}/checkstyle-sonar-plugin-${CHECKSTYLE_VERSION}.jar \
    https://repo1.maven.org/maven2/io/github/sfeir-open-source/sonar-clover-plugin/${CLOVER_VERSION}/sonar-clover-plugin-${CLOVER_VERSION}.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/${COBERTURA_VERSION}/sonar-cobertura-plugin-${COBERTURA_VERSION}.jar \
    https://github.com/mc1arke/sonarqube-community-branch-plugin/releases/download/${BRANCH_VERSION}/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/${FINDBUGS_VERSION}/sonar-findbugs-plugin-${FINDBUGS_VERSION}.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/${PMD_VERSION}/sonar-pmd-plugin-${PMD_VERSION}.jar \
    https://github.com/sbaudoin/sonar-shellcheck/releases/download/v${SHELLCHECK_VERSION}/sonar-shellcheck-plugin-${SHELLCHECK_VERSION}.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/${ICODE_VERSION}/sonar-icode-cnes-plugin-${ICODE_VERSION}.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/${CNESREPORT_VERSION}/sonar-cnes-report-${CNESREPORT_VERSION}.jar \
    https://github.com/SonarSource/SonarTS/releases/download/${SONARTS_VERSION_REPO}/sonar-typescript-plugin-${SONARTS_VERSION}.jar \
    https://github.com/VHDLTool/sonar-VHDLRC/releases/download/v${VHDLRC_VERSION}/sonar-vhdlrc-plugin-${VHDLRC_VERSION}.jar \
    https://github.com/sbaudoin/sonar-yaml/releases/download/v${YAML_VERSION}/sonar-yaml-plugin-${YAML_VERSION}.jar \
    /opt/sonarqube/extensions/plugins/

# Required by the community branch plugin (See https://github.com/mc1arke/sonarqube-community-branch-plugin/tree/1.8.1#installation)
ENV SONAR_WEB_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=web"
ENV SONAR_CE_JAVAADDITIONALOPTS="-javaagent:./extensions/plugins/sonarqube-community-branch-plugin-${BRANCH_VERSION}.jar=ce"

# Download software
ADD https://github.com/cnescatlab/i-CodeCNES/releases/download/v4.1.0/icode-4.1.0.zip \
    https://github.com/danmar/cppcheck/archive/refs/tags/2.10.tar.gz \
    https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856.zip \
    /tmp/

# CNES Pylint extension
ADD https://github.com/cnescatlab/cnes-pylint-extension/archive/refs/tags/v6.0.0.tar.gz \
    /tmp/python/

# Add CNES pylintrc A_B, C, D
COPY pylintrc.d/ /opt/python/

## ====================== INSTALL DEPENDENCIES ===============================

ENV PATH /usr/local/bin:${PATH}

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    gpg=2.2.27-* \
    dirmngr=2.2.27-* \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 605C66F00D6C9793 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y \
    && apt-get install -y \
    unzip=6.0-* \
    python3=3.10.4-* \
    python3-minimal=3.10.4-* \
    libpython3-stdlib=3.10.4-* \
    python3-distutils=3.10.4-* \
    python3-lib2to3=3.10.4-* \
    python3-pip=22.0.2* \
    curl=7.81.0-* \
    shellcheck=0.8.0-* \
    gcc=4:11.2.0-* \
    make=4.3-* \
    g\+\+=4:11.2.0-* \
    libpcre3=2:8.39-* \
    xz-utils=5.2.5-* \
    libpcre3-dev=2:8.39-* \
    jq=1.6-* \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /home/sonarqube \
    ## Install i-Code CNES
    && unzip /tmp/icode-4.1.0.zip -d /tmp \
    && chmod +x /tmp/icode/icode \
    && mv /tmp/icode/* /usr/bin \
    && rm -r /tmp/icode \
    && rm /tmp/icode-4.1.0.zip \
    ## Install Sonar Scanner
    && unzip /tmp/sonar-scanner-cli-4.8.0.2856.zip -d /opt/ \
    && mv /opt/sonar-scanner-4.8.0.2856 /opt/sonar-scanner \
    && rm -rf /tmp/sonar-scanner-cli-4.8.0.2856.zip

## Python, Pylint & CNES Pylint setup
RUN tar -xvzf /tmp/python/v6.0.0.tar.gz -C /opt/python \
    && rm -rf /tmp/python \
    && pip install --no-cache-dir \
    setuptools-scm==7.1.0 \
    pytest-runner==6.0.0 \
    wrapt==1.15.0 \
    six==1.16.0 \
    lazy-object-proxy==1.9.0 \
    mccabe==0.7.0 \
    isort==5.12.0 \
    typed-ast==1.5.4 \
    astroid==2.15.2 \
    pylint==2.17.2

## C and C++ tools installation
RUN cd /tmp \
    && tar -zxvf 2.10.tar.gz \
    && make -C cppcheck-2.10/ install MATCHCOMPILER="yes" FILESDIR="/usr/share/cppcheck" HAVE_RULES="yes" CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function -Wno-deprecated-declarations" \
    && cd .. \
    && rm -rf ./2.10.tar.gz ./cppcheck-2.10/ \
    && chown sonarqube:sonarqube -R /opt \
    && chown sonarqube:sonarqube -R /home \
    && apt-get autoremove -y \
    make \
    g\+\+ \
    libpcre3-dev


## ====================== CONFIGURATION ===============================

# Entry point files
COPY configure-cat.bash \
    init.bash \
    /tmp/

# Make sonarqube owner of it's installation directories
RUN chmod 750 /tmp/init.bash \
    && chown sonarqube:sonarqube -R /tmp/conf \
    ###### Disable telemetry
    && sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties \
    ###### Set default report path for Cppcheck
    && echo 'sonar.cxx.cppcheck.reportPaths=cppcheck-report.xml' >> /opt/sonar-scanner/conf/sonar-scanner.properties \
    ###### Set default report path for Pylint
    && echo 'sonar.python.pylint.reportPaths=pylint-report.txt' >> /opt/sonar-scanner/conf/sonar-scanner.properties \
    #### Set list of patterns matching Dockerfiles
    && echo 'sonar.lang.patterns.dockerfile=Dockerfile,Dockerfile.*' >> /opt/sonarqube/conf/sonar-scanner.properties \
    ###### Solve following error: https://github.com/cnescatlab/docker-cat/issues/30
    && chmod -R 777 /opt/sonarqube/temp \
    ###### Create pylint workdir
    && mkdir -p "$HOME/.pylint.d" \
    && chown -R sonarqube:sonarqube "$HOME/.pylint.d" \
    && chmod -R 777 "$HOME/.pylint.d"


## ====================== STARTING ===============================

ENTRYPOINT ["/tmp/init.bash"]
