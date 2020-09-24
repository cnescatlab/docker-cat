#!/usr/bin/env bash

# User story:
# As a user of this image, I want to be able to import the results
# of a CppCheck analysis to SonarQube.

. tests/functions.bash

ruleViolated="cppcheck:arrayIndexOutOfBounds"
expected_sensor="INFO: Sensor C++ (Community) CppCheckSensor \[cxx\]"
expected_import="INFO: CXX-CPPCHECK processed = 1"
test_import_analysis_results "CppCheck" "CppCheck Dummy Project" "cppcheck-dummy-project" "CNES_C_A" "c++" \
    "tests/c_cpp" "cppcheck" "$ruleViolated" "$expected_sensor" "$expected_import"

exit $?
