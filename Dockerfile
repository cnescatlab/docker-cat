## ====================== DOWNLOAD DEPENDENCIES STAGE ===============================

FROM sonarqube:6.7.4 AS download-stage
ENV SONAR_RUNNER_HOME=/opt/sonar-scanner
ENV PATH $PATH:/opt/sonar-scanner
ENV HOME /opt/sonarqube
RUN mkdir /opt/sonar
COPY ./conf /tmp/conf

# Download Sonarqubes plugins.
ADD https://github.com/checkstyle/sonar-checkstyle/releases/download/3.7/checkstyle-sonar-plugin-3.7.jar \
    https://github.com/lequal/sonar-cnes-cxx-plugin/releases/download/v1.1.0/sonar-cnes-cxx-plugin-1.1.jar \
    https://github.com/lequal/sonar-cnes-export-plugin/releases/download/v1.1.0/sonar-cnes-export-plugin-1.1.jar \
    https://github.com/lequal/sonar-cnes-python-plugin/releases/download/1.1/sonar-cnes-python-plugin-1.1.jar \
    https://github.com/lequal/sonar-icode-cnes-plugin/releases/download/1.1.0/sonaricode-1.1.0.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/1.9.1/sonar-cobertura-plugin-1.9.1.jar \
    https://github.com/SonarSource/sonar-csharp/releases/download/6.1.0.2359/sonar-csharp-plugin-6.1.0.2359.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-1.1.0/sonar-cxx-plugin-1.1.0.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/3.7.0/sonar-findbugs-plugin-3.7.0.jar \
    https://binaries.sonarsource.com/Distribution/sonar-flex-plugin/sonar-flex-plugin-2.5.1.1831.jar \
    https://binaries.sonarsource.com/Distribution/sonar-java-plugin/sonar-java-plugin-5.4.0.14284.jar \
    https://binaries.sonarsource.com/Distribution/sonar-javascript-plugin/sonar-javascript-plugin-3.1.1.5128.jar \
    https://binaries.sonarsource.com/Distribution/sonar-php-plugin/sonar-php-plugin-2.10.0.2087.jar \
    https://binaries.sonarsource.com/Distribution/sonar-pmd-plugin/sonar-pmd-plugin-2.5.jar \
    https://binaries.sonarsource.com/Distribution/sonar-python-plugin/sonar-python-plugin-1.14.0.3086.jar \
    https://github.com/willemsrb/sonar-rci-plugin/releases/download/sonar-rci-plugin-1.0.1/sonar-rci-plugin-1.0.1.jar \
    https://binaries.sonarsource.com/Distribution/sonar-scm-git-plugin/sonar-scm-git-plugin-1.8.0.1574.jar \
    https://binaries.sonarsource.com/Distribution/sonar-scm-svn-plugin/sonar-scm-svn-plugin-1.8.0.1168.jar \
    https://binaries.sonarsource.com/Distribution/sonar-typescript-plugin/sonar-typescript-plugin-1.9.0.3766.jar \
    https://binaries.sonarsource.com/Distribution/sonar-web-plugin/sonar-web-plugin-2.5.0.476.jar \
    https://binaries.sonarsource.com/Distribution/sonar-xml-plugin/sonar-xml-plugin-1.4.3.1027.jar \
    https://github.com/lequal/sonar-cnes-scan-plugin/releases/download/1.4.0/sonar-cnes-scan-plugin-1.4.jar \
    https://github.com/lequal/sonar-frama-c-plugin/releases/download/V2.0.0/sonarframac-2.0.0.jar \
    /opt/sonarqube/extensions/plugins/



# CNES report installation
ADD https://github.com/lequal/sonar-cnes-report/releases/download/3.0.0/sonar-cnes-report.jar \
    /opt/sonarqube/extensions/plugins/cnesreport.jar

# Download softwares
ADD https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rough-auditing-tool-for-security/rats-2.4.tgz \
    http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz \
    https://github.com/lequal/i-CodeCNES/releases/download/v3.1.0/i-CodeCNES-3.1.0-CLI-linux.gtk.x86_64.zip \
    /tmp/

# Sonar scanner installation
ADD https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip \
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


RUN apt update && apt install unzip python-setuptools cppcheck vera\+\+ gcc make jq shellcheck -y\
    && rm -rf /var/lib/apt/lists/* \
    #Install i-code
    && unzip /tmp/i-CodeCNES-3.1.0-CLI-linux.gtk.x86_64.zip -d /tmp;chmod +x /tmp/icode/icode;mv /tmp/icode/* /usr/bin \
    && rm -r /tmp/icode \
    && rm /tmp/i-CodeCNES-3.1.0-CLI-linux.gtk.x86_64.zip \
    ## Install sonar scanner
    && unzip /tmp/scanners/sonar-scanner-cli-3.0.3.778-linux.zip -d /opt/ \
    && mv /opt/sonar-scanner-3.0.3.778-linux /opt/sonar-scanner \
    && rm -rf /tmp/scanners \
    ## Python, Pylin et CNES pylint setup
    && mkdir /opt/python \
    && find /tmp/python -maxdepth 1 -name \*.tar.gz -exec tar -xvzf {} -C /opt/python \; \
    && ls /opt/python \
    && cd /opt/python/colorama-0.3.3/ && python setup.py install \
    && cd /opt/python/python-lazy-object-proxy-1.2.1/ && python setup.py install \
    && cd /opt/python/six-1.9.0/ && python setup.py install \
    && cd /opt/python/wrapt-1.10.5/ && python setup.py install \
    && cd /opt/python/astroid-astroid-1.4.9/ && python setup.py install \
    && cd /opt/python/pylint-pylint-1.5/ && python setup.py install \
    && rm -rf /tmp/python \
    ## C and C++ tools installation
    && cd /tmp && tar -xvzf expat-2.0.1.tar.gz \
    && cd expat-2.0.1 \
    && ./configure && make && make install \
    && cd .. \
    && rm -rf ./expat-2.0.1.tar.gz ./expat-2.0.1 \
    && tar -xzvf rats-2.4.tgz \
    && cd rats-2.4 \
    && ./configure --with-expat-lib=/usr/local/lib && make && make install \
    && ./rats \
    && cd .. \
    && rm -rf ./rats-2.4.tgz ./rats-2.4

## Install frama-c
## Need to be installed after, this script resolve mannualy dependencies and fix a python bug
## which generate an error when dpkg try to configure python.

ENV HOME /home/sonarqube
RUN rm /usr/local/lib/libexpat.so.1 \
    && apt update \
    && apt install opam autoconf debianutils libgmp-dev libgtksourceview2.0-dev pkg-config graphviz libgnomecanvas2-dev -y; rm /usr/local/lib/libexpat.so.1 \
    && dpkg --configure -a \
    && opam init -y; opam update; opam install frama-c -y \
    && ln -s /home/sonarqube/.opam/system/bin/frama-c /bin/frama-c \
    && apt remove opam -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*
ENV HOME /opt/sonarqube


## ====================== CONFIGURATION STAGE ===============================

FROM download-stage AS configuration-stage





# Entry point files
COPY ./configure-cat.bash /tmp/
COPY ./init.bash /tmp/

# Make sonarqube owner of it's installation directories
RUN chown sonarqube:sonarqube -R /opt \
    && ls -lrta /opt/ \
    && chmod 750 /tmp/init.bash \
    && chown sonarqube:sonarqube -R /tmp/conf \
    && mkdir -p /opt/sonarqube/extensions/ \
    && ln -s /opt/sonarqube/extensions/plugins /opt/sonar/extensions/plugins \
    && mkdir -p /opt/sonarqube/frama-c/ \
    && ln -s /bin/frama-c /opt/sonarqube/frama-c/frama-c

WORKDIR $SONARQUBE_HOME
ENTRYPOINT ["/tmp/init.bash"]
