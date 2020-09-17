#!/usr/bin/env bash

# User story:
# As a user of this image, I want to be able to import the results
# of a RATS analysis to SonarQube.

. tests/functions.bash

ruleViolated="rats:fixed size global buffer"
expected_sensor="INFO: Sensor C++ (Community) RatsSensor \[cxx\]"
expected_import="INFO: CXX-RATS processed = 1"
test_import_analysis_results "RATS" "RATS Dummy Project" "rats-dummy-project" "CNES_CPP_A" "c++" \
    "tests/c_cpp" "rats" "$ruleViolated" "$expected_sensor" "$expected_import" "yes"

exit $?
