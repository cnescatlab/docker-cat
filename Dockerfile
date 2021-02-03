FROM sonarqube:7.9.4-community AS framac

## ====================== INSTALL FRAMA-C =============================

USER root
WORKDIR /tmp/framac

ADD https://frama-c.com/download/frama-c-20.0-Calcium.tar.gz \
    /tmp/framac

RUN echo 'deb http://ftp.fr.debian.org/debian/ bullseye main contrib non-free' >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y \
        make \
        unzip \
        ocaml \
        ocaml-findlib \
        libfindlib-ocaml-dev \
        libocamlgraph-ocaml-dev \
        libyojson-ocaml-dev \
        libzarith-ocaml-dev \
        menhir \
    && rm -rf /var/lib/apt/lists/* \
    && tar -zxvf frama-c-20.0-Calcium.tar.gz \
    && cd frama-c-20.0-Calcium \
    && ./configure --disable-gui --disable-wp \
    && make \
    && make install

## ====================== BUILD FINAL IMAGE ===================================

FROM sonarqube:7.9.4-community
ENV HOME=/home/sonarqube \
    SONAR_SCANNER_HOME=/opt/sonar-scanner \
    SONAR_USER_HOME=/opt/sonar-scanner/.sonar \
    PATH="$PATH:/opt/sonar-scanner/bin:/usr/local/bin" \
    PYTHONPATH="$PYTHONPATH:/opt/python/cnes-pylint-extension-5.0.0/checkers/"
USER root
COPY conf /tmp/conf


## ====================== DOWNLOAD DEPENDENCIES ===============================

# Download SonarQube plugins
ADD https://github.com/checkstyle/sonar-checkstyle/releases/download/4.21/checkstyle-sonar-plugin-4.21.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/1.9.1/sonar-cobertura-plugin-1.9.1.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-1.3.1/sonar-cxx-plugin-1.3.1.1807.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/3.11.0/sonar-findbugs-plugin-3.11.0.jar \
    https://github.com/willemsrb/sonar-rci-plugin/releases/download/sonar-rci-plugin-1.0.1/sonar-rci-plugin-1.0.1.jar \
    https://binaries.sonarsource.com/Distribution/sonar-flex-plugin/sonar-flex-plugin-2.5.1.1831.jar \
    https://github.com/cnescatlab/sonar-cnes-cxx-plugin/releases/download/v1.1.0/sonar-cnes-cxx-plugin-1.1.jar \
    https://github.com/cnescatlab/sonar-cnes-export-plugin/releases/download/v1.2.0/sonar-cnes-export-plugin-1.2.jar \
    https://github.com/cnescatlab/sonar-cnes-python-plugin/releases/download/1.3/sonar-cnes-python-plugin-1.3.jar \
    https://github.com/cnescatlab/sonar-icode-cnes-plugin/releases/download/2.0.2/sonar-icode-cnes-plugin-2.0.2.jar \
    https://github.com/cnescatlab/sonar-frama-c-plugin/releases/download/V2.1.1/sonar-frama-c-plugin-2.1.1.jar \
    https://github.com/cnescatlab/sonar-cnes-scan-plugin/releases/download/1.5.0/sonar-cnes-scan-plugin-1.5.jar \
    https://github.com/cnescatlab/sonar-cnes-report/releases/download/3.3.0/sonar-cnes-report-3.3.0.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/3.2.1/sonar-pmd-plugin-3.2.1.jar \
    https://github.com/cnescatlab/sonar-hadolint-plugin/releases/download/1.0.0/sonar-hadolint-plugin-1.0.0.jar \
    /opt/sonarqube/extensions/plugins/


# Download software
ADD https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rough-auditing-tool-for-security/rats-2.4.tgz \
    http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz \
    https://github.com/cnescatlab/i-CodeCNES/releases/download/v4.1.0/icode-4.1.0.zip \
    https://netix.dl.sourceforge.net/project/cppcheck/cppcheck/1.90/cppcheck-1.90.tar.gz \
    https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.4.0.2170.zip \
    /tmp/

# CNES Pylint extension
ADD https://github.com/cnescatlab/cnes-pylint-extension/archive/v5.0.0.tar.gz \
    /tmp/python/

# Add CNES pylintrc A_B, C, D
COPY pylintrc.d/ /opt/python/

## ====================== INSTALL DEPENDENCIES ===============================

## Install Frama-C from previous stage
COPY --from=framac /usr/local/ /usr/local/
ENV PATH /usr/local/bin:${PATH}

RUN echo 'deb http://ftp.fr.debian.org/debian/ bullseye main contrib non-free' >> /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get install -y \
       unzip \
       python3 \
       python3-pip \
       vera\+\+=1.2.1-* \
       shellcheck=0.7.1-* \
       gcc=4:10.2.0-* \
       make=4.3-* \
       g\+\+ \
       libpcre3 \
       libpcre3-dev \
       libfindlib-ocaml \
       libocamlgraph-ocaml-dev \
       libzarith-ocaml \
       libyojson-ocaml \
       jq \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /home/sonarqube \
    ## Hadolint tool
    && curl -ksSLO https://github.com/hadolint/hadolint/releases/download/v1.21.0/hadolint-Linux-x86_64 \
    ## Install i-Code CNES
    && unzip /tmp/icode-4.1.0.zip -d /tmp \
    && chmod +x /tmp/icode/icode \
    && mv /tmp/icode/* /usr/bin \
    && rm -r /tmp/icode \
    && rm /tmp/icode-4.1.0.zip \
    ## Install Sonar Scanner
    && unzip /tmp/sonar-scanner-cli-4.4.0.2170.zip -d /opt/ \
    && mv /opt/sonar-scanner-4.4.0.2170 /opt/sonar-scanner \
    && rm -rf /tmp/sonar-scanner-cli-4.4.0.2170.zip \
    ## Python, Pylint & CNES Pylint setup
    && tar -xvzf /tmp/python/v5.0.0.tar.gz -C /opt/python \
    && rm -rf /tmp/python \
    && pip install --no-cache-dir \
       setuptools-scm==3.5.0 \
       pytest-runner==5.2 \
       wrapt==1.12.1 \
       six==1.14.0 \
       lazy-object-proxy==1.4.3 \
       mccabe==0.6.1 \
       isort==4.3.21 \
       typed-ast==1.4.1 \
       astroid==2.4.0 \
       pylint==2.5.0 \
    ## C and C++ tools installation
    && cd /tmp \
    && tar -xvzf expat-2.0.1.tar.gz \
    && cd expat-2.0.1 \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf ./expat-2.0.1.tar.gz ./expat-2.0.1 \
    && tar -xzvf rats-2.4.tgz \
    && cd rats-2.4 \
    && ./configure --with-expat-lib=/usr/local/lib \
    && make \
    && make install \
    && ./rats \
    && cd .. \
    && rm -rf ./rats-2.4.tgz ./rats-2.4 \
    && tar -zxvf cppcheck-1.90.tar.gz \
    && cd cppcheck-1.90/ \
    && make install MATCHCOMPILER="yes" FILESDIR="/usr/share/cppcheck" HAVE_RULES="yes" CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function -Wno-deprecated-declarations" \
    && cd .. \
    && rm -rf ./cppcheck-1.90.tar.gz ./cppcheck-1.90/ \
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
    && mkdir -p /opt/sonarqube/frama-c/ \
    && ln -s /usr/local/bin/frama-c /opt/sonarqube/frama-c/frama-c \
###### Disable telemetry
    && sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties \
###### Set list of patterns matching Dockerfiles for hadolint
    && echo 'sonar.lang.patterns.dockerfile=Dockerfile,Dockerfile.*' >> /opt/sonarqube/conf/sonar-scanner.properties \
###### Set default report path for Cppcheck
    && echo 'sonar.cxx.cppcheck.reportPath=cppcheck-report.xml' >> /opt/sonar-scanner/conf/sonar-scanner.properties \
###### Set default report path for Vera++
    && echo 'sonar.cxx.vera.reportPath=vera-report.xml' >> /opt/sonar-scanner/conf/sonar-scanner.properties \
###### Set default report path for RATS
    && echo 'sonar.cxx.rats.reportPath=rats-report.xml' >> /opt/sonar-scanner/conf/sonar-scanner.properties \
###### Set default report path for Pylint
    && echo 'sonar.python.pylint.reportPath=pylint-report.txt' >> /opt/sonar-scanner/conf/sonar-scanner.properties \
###### Solve following error: https://github.com/cnescatlab/docker-cat/issues/30
    && chmod -R 777 /opt/sonarqube/temp \
###### Create pylint workdir
    && mkdir -p "$HOME/.pylint.d" \
    && chown -R sonarqube:sonarqube "$HOME/.pylint.d" \
    && chmod -R 777 "$HOME/.pylint.d"


## ====================== STARTING ===============================

ENTRYPOINT ["/tmp/init.bash"]
