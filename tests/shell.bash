#!/usr/bin/env bash

# User story:
# As a user of this image, I want to analyze a shell project
# so that I can see its level of quality on the SonarQube server.

. tests/functions.bash

sensors=(
    "INFO: Sensor Sonar i-Code \[icode\]"
)
test_language "Shell" "shell" "shell" sensors "shell-dummy-project" 58

exit $?
