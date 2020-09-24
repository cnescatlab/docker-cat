#!/usr/bin/env bash

# User story:
# As a user of this image, I want to analyze a java project
# so that I can see its level of quality on the SonarQube server.

. tests/functions.bash

sensors=(
    "INFO: Sensor CheckstyleSensor \[checkstyle\]"
    "INFO: Sensor FindBugs Sensor \[findbugs\]"
    "INFO: Sensor PmdSensor \[pmd\]"
    "INFO: Sensor CoberturaSensor \[cobertura\]"
)
test_language "Java" "java" "java" sensors "java-dummy-project" 3 "CNES_JAVA_A" 6

exit $?
