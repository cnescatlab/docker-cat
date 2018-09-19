FROM sonarqube:6.7.4
ENV SONAR_RUNNER_HOME=/opt/sonar-scanner
ENV PATH $PATH:/opt/sonar-scanner
ENV HOME /opt/sonarqube 
RUN mkdir /opt/sonar
COPY ./conf /tmp/conf  

# Download Sonarqubes plugins.
RUN wget -P /opt/sonarqube/extensions/plugins/ \
    https://github.com/lequal/sonar-cnes-scan-plugin/releases/download/v1.2.0/sonar-cnes-scan-plugin-1.2.jar \
    https://github.com/checkstyle/sonar-checkstyle/releases/download/3.7/checkstyle-sonar-plugin-3.7.jar \
    https://github.com/lequal/sonar-cnes-cxx-plugin/releases/download/v1.1.0/sonar-cnes-cxx-plugin-1.1.jar \
    https://github.com/lequal/sonar-cnes-export-plugin/releases/download/v1.1.0/sonar-cnes-export-plugin-1.1.jar \
    https://github.com/lequal/sonar-cnes-python-plugin/releases/download/1.1/sonar-cnes-python-plugin-1.1.jar \
    https://github.com/galexandre/sonar-cobertura/releases/download/1.9.1/sonar-cobertura-plugin-1.9.1.jar \
    https://github.com/SonarSource/sonar-csharp/releases/download/6.1.0.2359/sonar-csharp-plugin-6.1.0.2359.jar \
    https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-0.9.7/sonar-cxx-plugin-0.9.7.jar \
    https://github.com/spotbugs/sonar-findbugs/releases/download/3.7.0/sonar-findbugs-plugin-3.7.0.jar \
    https://sonarsource.bintray.com/Distribution/sonar-flex-plugin/sonar-flex-plugin-2.4.0.1222.jar \
    https://sonarsource.bintray.com/Distribution/sonar-java-plugin/sonar-java-plugin-5.4.0.14284.jar \
    https://sonarsource.bintray.com/Distribution/sonar-javascript-plugin/sonar-javascript-plugin-3.1.1.5128.jar \
    https://sonarsource.bintray.com/Distribution/sonar-php-plugin/sonar-php-plugin-2.10.0.2087.jar \
    https://sonarsource.bintray.com/Distribution/sonar-pmd-plugin/sonar-pmd-plugin-2.5.jar \
    https://sonarsource.bintray.com/Distribution/sonar-python-plugin/sonar-python-plugin-1.8.0.1496.jar \
    https://github.com/willemsrb/sonar-rci-plugin/releases/download/sonar-rci-plugin-1.0.1/sonar-rci-plugin-1.0.1.jar \
    https://sonarsource.bintray.com/Distribution/sonar-scm-git-plugin/sonar-scm-git-plugin-1.2.jar \
    https://sonarsource.bintray.com/Distribution/sonar-scm-svn-plugin/sonar-scm-svn-plugin-1.4.0.522.jar \
    #Outdated
    #https://github.com/stefanrinderle/sonar-softvis3d-plugin/releases/download/sonar-softVis3D-plugin-0.3.5/sonar-softVis3D-plugin-0.3.5.jar \
    https://sonarsource.bintray.com/Distribution/sonar-typescript-plugin/sonar-typescript-plugin-1.1.0.1079.jar \
    https://sonarsource.bintray.com/Distribution/sonar-web-plugin/sonar-web-plugin-2.5.0.476.jar \
    https://sonarsource.bintray.com/Distribution/sonar-xml-plugin/sonar-xml-plugin-1.4.3.1027.jar \
    && ls /opt/sonarqube/extensions/plugins

# CNES report installation
RUN wget -P /opt/sonar/extensions/cnes/ \
    https://github.com/lequal/sonar-cnes-report/releases/download/v1.1.0/sonar-report-cnes.jar \
    https://github.com/lequal/sonar-cnes-report/releases/download/v1.1.0/issues-template.xlsx \
    https://github.com/lequal/sonar-cnes-report/releases/download/v1.1.0/code-analysis-template.docx

# Sonar scanner installation
RUN apt update && apt install -y unzip && rm -rf /var/lib/apt/lists/* \
    && mkdir /tmp/scanners \
    && wget -P /tmp/scanners \
    https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip \
    && unzip /tmp/scanners/sonar-scanner-cli-3.0.3.778-linux.zip -d /opt/ \
    && mv /opt/sonar-scanner-3.0.3.778-linux /opt/sonar-scanner \ 
    && rm -rf /tmp/scanners

	
# Python, Pylint and CNES pylint setup 	
ENV PYTHONPATH $PYTHONPATH:/opt/python/cnes-pylint-extension-1.0/checkers/

RUN apt update && apt install -y python-setuptools && rm -rf /var/lib/apt/lists/* \
    && mkdir /opt/python && mkdir /tmp/python \
    && wget -P /tmp/python \
    https://github.com/tartley/colorama/archive/v0.3.3.tar.gz \
    https://github.com/ionelmc/python-lazy-object-proxy/archive/v1.2.1.tar.gz \
    https://github.com/CloudAutomationNTools/python-six/archive/1.9.0.tar.gz \
    https://github.com/GrahamDumpleton/wrapt/archive/1.10.5.tar.gz \
    https://github.com/PyCQA/astroid/archive/astroid-1.4.9.tar.gz \
    https://github.com/PyCQA/pylint/archive/pylint-1.5.tar.gz \
    https://github.com/lequal/cnes-pylint-extension/archive/V1.0.tar.gz \
    && find /tmp/python -maxdepth 1 -name \*.tar.gz -exec tar -xvzf {} -C /opt/python \; \
    && ls /opt/python \
    && cd /opt/python/colorama-0.3.3/ && python setup.py install \
    && cd /opt/python/python-lazy-object-proxy-1.2.1/ && python setup.py install \
    && cd /opt/python/python-six-1.9.0/ && python setup.py install \
    && cd /opt/python/wrapt-1.10.5/ && python setup.py install \
    && cd /opt/python/astroid-astroid-1.4.9/ && python setup.py install \
    && cd /opt/python/pylint-pylint-1.5/ && python setup.py install \
    && rm -rf /tmp/python

# C and C++ tools installation
## CPPCheck, gcc, make, vera++
RUN apt update && apt install -y cppcheck vera\+\+ gcc make && rm -rf /var/lib/apt/lists/*
## Expat, rats
RUN wget http://downloads.sourceforge.net/project/expat/expat/2.0.1/expat-2.0.1.tar.gz \
    && tar -xvzf expat-2.0.1.tar.gz \
    && cd expat-2.0.1 \
    && wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rough-auditing-tool-for-security/rats-2.4.tgz \
    && ./configure && make && make install \
    && tar -xzvf rats-2.4.tgz \
    && cd rats-2.4 \
    && ./configure --with-expat-lib=/usr/local/lib && make && make install \
    && ./rats \ 
    && cd ../../ \ 
    && rm -rf ./expat-2.0.1.tar.gz ./expat-2.0.1
## DrMemory --Future version
#RUN wget https://github.com/DynamoRIO/drmemory/releases/download/release_1.11.0/DrMemory-Linux-1.11.0-2.tar.gz \
#    && tar -zvf DrMemory-Linux-1.11.0-2.tar.gz \
#    && mkdir /opt/tools \
#    && mv DrMemory-Linux-1.11.0-2 /opt/tools/DrMemory \
#    && rm DrMemory-Linux-1.11.0-2 \
#    && apt install -y glibc-devel libstdc++-devel.i686 glibec-devel.i686 glibc-devel.i686
## Valgrind --future version
#RUN apt install -y valgrind
## CLang and scan-build --future version
#RUN apt install -y ocaml \
#    && export PATH=/usr/bin/ocaml:$PATH \
#    && apt install -y perl-Digest-MD5 cmake \
#    && export PATH=/usr/bin/cmake:$PATH \
#    && apt install -y cmake3    
	
# Make sonarqube owner of it's installation directories	
RUN chown sonarqube:sonarqube -R /opt \
    && ls -lrta /opt/ \
    && chown sonarqube:sonarqube -R /home \
    && ls -lrta /home/ \
    && chown sonarqube:sonarqube -R /tmp/conf

# jq required for configure-cat script.	
RUN apt update && apt install -y jq && rm -rf /var/lib/apt/lists/*
# Entry point files
COPY ./configure-cat.bash /tmp/
COPY ./init.bash /tmp/
RUN chmod 750 /tmp/init.bash
ENTRYPOINT ["/tmp/init.bash"]

