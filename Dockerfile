FROM sonarqube:7.9.3-community
ENV SONAR_RUNNER_HOME=/opt/sonar-scanner
ENV PATH $PATH:/opt/sonar-scanner
USER root
RUN mkdir /opt/sonar
COPY ./conf /tmp/conf


## ====================== DOWNLOAD DEPENDENCIES ===============================

# Download SonarQube plugins
ADD https://github.com/checkstyle/sonar-checkstyle/releases/download/4.21/checkstyle-sonar-plugin-4.21.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/1.9.1/sonar-cobertura-plugin-1.9.1.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-1.3.1/sonar-cxx-plugin-1.3.1.1807.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/3.11.0/sonar-findbugs-plugin-3.11.0.jar \
    https://github.com/willemsrb/sonar-rci-plugin/releases/download/sonar-rci-plugin-1.0.1/sonar-rci-plugin-1.0.1.jar \
    https://binaries.sonarsource.com/Distribution/sonar-flex-plugin/sonar-flex-plugin-2.5.1.1831.jar \
    https://github.com/lequal/sonar-cnes-cxx-plugin/releases/download/v1.1.0/sonar-cnes-cxx-plugin-1.1.jar \
    https://github.com/lequal/sonar-cnes-export-plugin/releases/download/v1.2.0/sonar-cnes-export-plugin-1.2.jar \
    https://github.com/lequal/sonar-cnes-python-plugin/releases/download/1.3/sonar-cnes-python-plugin-1.3.jar \
    https://github.com/lequal/sonar-icode-cnes-plugin/releases/download/2.0.2/sonar-icode-cnes-plugin-2.0.2.jar \
    https://github.com/lequal/sonar-frama-c-plugin/releases/download/V2.1.1/sonar-frama-c-plugin-2.1.1.jar \
    https://github.com/lequal/sonar-cnes-scan-plugin/releases/download/1.5.0/sonar-cnes-scan-plugin-1.5.jar \
    https://github.com/lequal/sonar-cnes-report/releases/download/3.2.2/sonar-cnes-report-3.2.2.jar \
    https://github.com/jensgerdes/sonar-pmd/releases/download/3.2.1/sonar-pmd-plugin-3.2.1.jar \
    /opt/sonarqube/extensions/plugins/


# Download software
ADD https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rough-auditing-tool-for-security/rats-2.4.tgz \
    http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz \
    https://github.com/lequal/i-CodeCNES/releases/download/v4.1.0/icode-4.1.0.zip \
    /tmp/


# Sonar Scanner installation
ADD https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.2.0.1873-linux.zip \
    /tmp/scanners/


# Python, Pylint and CNES pylint setup
ENV PYTHONPATH $PYTHONPATH:/opt/python/cnes-pylint-extension-1.0/checkers/
ADD https://github.com/tartley/colorama/archive/v0.3.3.tar.gz \
    https://github.com/ionelmc/python-lazy-object-proxy/archive/v1.2.1.tar.gz \
    https://files.pythonhosted.org/packages/16/64/1dc5e5976b17466fd7d712e59cbe9fb1e18bec153109e5ba3ed6c9102f1a/six-1.9.0.tar.gz \
    https://github.com/GrahamDumpleton/wrapt/archive/1.10.5.tar.gz \
    https://github.com/PyCQA/astroid/archive/astroid-1.4.9.tar.gz \
    https://github.com/PyCQA/pylint/archive/pylint-1.5.tar.gz \
    https://github.com/lequal/cnes-pylint-extension/archive/V1.0.tar.gz \
    /tmp/python/


## ====================== INSTALL DEPENDENCIES ===============================

ENV HOME /home/sonarqube
RUN apt update -y \
    && apt install -y \
       unzip \
       python-setuptools=40.8.0-1 \
       cppcheck \
       vera\+\+=1.2.1-2\+b5 \
       shellcheck=0.5.0-3 \
       gcc=4:8.3.0-1 \
       make=4.2.1-1.2 \
       jq \
    && mkdir /home/sonarqube \
    ## Install i-Code CNES
    && unzip /tmp/icode-4.1.0.zip -d /tmp \
    && chmod +x /tmp/icode/icode \
    && mv /tmp/icode/* /usr/bin \
    && rm -r /tmp/icode \
    && rm /tmp/icode-4.1.0.zip \
    ## Install Sonar Scanner
    && unzip /tmp/scanners/sonar-scanner-cli-4.2.0.1873-linux.zip -d /opt/ \
    && mv /opt/sonar-scanner-4.2.0.1873-linux /opt/sonar-scanner \
    && rm -rf /tmp/scanners \
    ## Python, Pylint & CNES Pylint setup
    && mkdir /opt/python \
    && find /tmp/python -maxdepth 1 -name \*.tar.gz -exec tar -xvzf {} -C /opt/python \; \
    && ls /opt/python \
    && cd /opt/python/colorama-0.3.3/ \
    && python setup.py install \
    && cd /opt/python/python-lazy-object-proxy-1.2.1/ \
    && python setup.py install \
    && cd /opt/python/six-1.9.0/ \
    && python setup.py install \
    && cd /opt/python/wrapt-1.10.5/ \
    && python setup.py install \
    && cd /opt/python/astroid-astroid-1.4.9/ \
    && python setup.py install \
    && cd /opt/python/pylint-pylint-1.5/ \
    && python setup.py install \
    && rm -rf /tmp/python \
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
    && chown sonarqube:sonarqube -R /opt \
    && chown sonarqube:sonarqube -R /home

    ## Install Cppcheck
RUN echo 'deb http://ftp.de.debian.org/debian bullseye main' >> /etc/apt/sources.list \
    && apt update -y \
    && apt install -y cppcheck=1.90-4

    
    ## Install tools & Frama-C
RUN apt-get update -y \
    && apt-get install -y \
       git \
       ocaml \
       ocaml-native-compilers \
       liblablgtk2-ocaml-dev \
       liblablgtksourceview2-ocaml-dev \
       menhir \
       why3 \
       libyojson-ocaml-dev=1.7.0-1\+b3 \
       libocamlgraph-ocaml-dev \
       libzarith-ocaml-dev \
       build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --single-branch https://github.com/Frama-C/Frama-C-snapshot.git /tmp/framac \
    && cd /tmp/framac \
    && git checkout -b tags/19.1 \
    &&  ./configure \
    && make \
    && make install \
    && rm -rf /tmp/framac


## ====================== CONFIGURATION ===============================

# Entry point files
COPY ./configure-cat.bash /tmp/
COPY ./init.bash /tmp/

# Make sonarqube owner of it's installation directories
RUN ls -lrta /opt/ \
    && chmod 750 /tmp/init.bash \
    && chown sonarqube:sonarqube -R /tmp/conf \
    && mkdir -p /opt/sonar/extensions/ \
    && ln -s /opt/sonarqube/extensions/plugins /opt/sonar/extensions/plugins \
    && mkdir -p /opt/sonarqube/frama-c/ \
    && ln -s /bin/frama-c /opt/sonarqube/frama-c/frama-c


## ====================== STARTING ===============================

WORKDIR $SONARQUBE_HOME
ENTRYPOINT ["/tmp/init.bash"]
