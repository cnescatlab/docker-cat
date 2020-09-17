#!/usr/bin/env bash

# User story:
# As a user of this image, I want to analyze a C/C++ project
# so that I can see its level of quality on the SonarQube server.

. tests/functions.bash

sensors=(
    "Sensor C++ (Community) SquidSensor \[cxx\]"
    "Sensor SonarFrama-C \[framac\]"
)
test_language "C/C++" "c++" "c_cpp" sensors "c-dummy-project" 0 "CNES_C_A" 1
# 0 issue are expected with the Sonar way Quality Profile for C++ (Community)
# because it does not have any rule enabled.

exit $?
