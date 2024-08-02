# This image is based on a LTS version of SonarQube
FROM lequal/sonarqube:3.2.5

LABEL maintainer="CATLab"

ENV HOME=/home/sonarqube \
    SONAR_SCANNER_HOME=/opt/sonar-scanner \
    SONAR_USER_HOME=/opt/sonar-scanner/.sonar \
    PATH="$PATH:/opt/sonar-scanner/bin:/usr/local/bin"

USER root

# Download software
ADD https://github.com/cnescatlab/i-CodeCNES/releases/download/5.0.0/icode-5.0.0.zip \
    https://github.com/danmar/cppcheck/archive/refs/tags/2.14.2.tar.gz \
    https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006.zip \
    https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 \
    https://github.com/cnescatlab/sonar-cnes-scan-plugin/releases/download/2.1.0/sonar-cnes-scan-plugin-2.1.0.jar \
    /tmp/

# Add CNES pylintrc A_B, C, D
COPY pylintrc.d/ /opt/python/

#Add CNES hadolint config
COPY hadolint.d/ /opt/hadolint/

## ====================== INSTALL DEPENDENCIES ===============================

ENV PATH=/usr/local/bin:${PATH}

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    gpg=2.2.27-* \
    dirmngr=2.2.27-* \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    unzip=6.0-* \
    python3=3.10.6-* \
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
    && unzip /tmp/icode-5.0.0.zip -d /tmp \
    && chmod +x /tmp/icode/icode \
    && mv /tmp/icode/* /usr/bin \
    && rm -r /tmp/icode \
    && rm /tmp/icode-5.0.0.zip \
    ## Install Sonar Scanner
    && unzip /tmp/sonar-scanner-cli-5.0.1.3006.zip -d /opt/ \
    && mv /opt/sonar-scanner-5.0.1.3006 /opt/sonar-scanner \
    && rm -rf /tmp/sonar-scanner-cli-5.0.1.3006.zip\
    ## Install Hadolint
    && mv /tmp/hadolint-Linux-x86_64 /usr/bin/hadolint \
    && chown sonarqube:sonarqube /usr/bin/hadolint \
    && chmod +x /usr/bin/hadolint \
    ## Install Cnes Scan Plugin
    && mv /tmp/sonar-cnes-scan-plugin-2.1.0.jar /opt/sonarqube/extensions/plugins/ \
    && chown sonarqube:sonarqube /opt/sonarqube/extensions/plugins/sonar-cnes-scan-plugin-2.1.0.jar


## Python, Pylint & CNES Pylint setup
RUN pip install --no-cache-dir \
    setuptools-scm==8.1.0 \
    pytest-runner==6.0.1 \
    wrapt==1.16.0 \
    six==1.16.0 \
    lazy-object-proxy==1.10.0 \
    mccabe==0.7.0 \
    isort==5.13.2 \
    typed-ast==1.5.5 \
    astroid==3.2.4 \
    pylint==3.2.6 \
    pylint_sonarjson_catlab==2.0.0 \
    cnes-pylint-extension==7.0.0

## C and C++ tools installation
WORKDIR /tmp

RUN tar -zxvf 2.14.2.tar.gz \
    && make -C cppcheck-2.14.2/ install MATCHCOMPILER="yes" FILESDIR="/usr/share/cppcheck" HAVE_RULES="yes" CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function -Wno-deprecated-declarations" \
    && rm -rf /2.14.2.tar.gz /cppcheck-2.14.2/ \
    && chown sonarqube:sonarqube -R /opt \
    && chown sonarqube:sonarqube -R /home \
    && apt-get autoremove -y \
    make \
    g\+\+ \
    libpcre3-dev

WORKDIR /opt/sonarqube

## ====================== CONFIGURATION ===============================

# Entry point files
COPY configure-cat.bash \
    init.bash \
    /tmp/


# Make sonarqube owner of it's installation directories
RUN chmod 750 /tmp/init.bash \
    ###### Disable telemetry
    && sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties \
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
