#!/usr/bin/env bash

# User story:
# As a user of this image, I want to be able to import the results
# of a Vera++ analysis to SonarQube.

. tests/functions.bash

ruleViolated="vera++:T008"
expected_sensor="INFO: Sensor C++ (Community) VeraxxSensor \[cxx\]"
expected_import="INFO: CXX-VERA++ processed = 4"
test_import_analysis_results "Vera++" "Vera++ Dummy Project" "vera-dummy-project" "CNES_CPP_A" "c++" \
    "tests/c_cpp" "vera" "$ruleViolated" "$expected_sensor" "$expected_import"

exit $?
