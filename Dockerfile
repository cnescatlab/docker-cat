# This image is based on a LTS version of SonarQube
FROM lequal/sonarqube:3.2.2

LABEL maintainer="CATLab"

ENV HOME=/home/sonarqube \
    SONAR_SCANNER_HOME=/opt/sonar-scanner \
    SONAR_USER_HOME=/opt/sonar-scanner/.sonar \
    PATH="$PATH:/opt/sonar-scanner/bin:/usr/local/bin" \
    PYTHONPATH="$PYTHONPATH:/opt/python/cnes-pylint-extension-6.0.0/checkers/" \
    PYLINTHOME="$HOME/.pylint.d"

USER root

# Download software
ADD https://github.com/cnescatlab/i-CodeCNES/releases/download/4.1.2/icode-4.1.2.zip \
    https://github.com/danmar/cppcheck/archive/refs/tags/2.13.0.tar.gz \
    https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006.zip \
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
    && unzip /tmp/icode-4.1.2.zip -d /tmp \
    && chmod +x /tmp/icode/icode \
    && mv /tmp/icode/* /usr/bin \
    && rm -r /tmp/icode \
    && rm /tmp/icode-4.1.2.zip \
    ## Install Sonar Scanner
    && unzip /tmp/sonar-scanner-cli-5.0.1.3006.zip -d /opt/ \
    && mv /opt/sonar-scanner-5.0.1.3006 /opt/sonar-scanner \
    && rm -rf /tmp/sonar-scanner-cli-5.0.1.3006.zip

## Python, Pylint & CNES Pylint setup
RUN tar -xvzf /tmp/python/v6.0.0.tar.gz -C /opt/python \
    && rm -rf /tmp/python \
    && pip install --no-cache-dir \
    setuptools-scm==8.0.4 \
    pytest-runner==6.0.1 \
    wrapt==1.16.0 \
    six==1.16.0 \
    lazy-object-proxy==1.10.0 \
    mccabe==0.7.0 \
    isort==5.13.2 \
    typed-ast==1.5.5 \
    astroid==2.15.2 \
    pylint==2.17.2

## C and C++ tools installation
RUN cd /tmp \
    && tar -zxvf 2.13.0.tar.gz \
    && make -C cppcheck-2.13.0/ install MATCHCOMPILER="yes" FILESDIR="/usr/share/cppcheck" HAVE_RULES="yes" CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function -Wno-deprecated-declarations" \
    && cd .. \
    && rm -rf ./2.13.0.tar.gz ./cppcheck-2.13.0/ \
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
