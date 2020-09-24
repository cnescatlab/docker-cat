#!/usr/bin/env bash

# User story:
# As a user of this image, I want to be able to import the results
# of a Frama-C analysis to SonarQube.

. tests/functions.bash

ruleViolated="framac-rules:KERNEL.0"
expected_sensor="INFO: Sensor SonarFrama-C \[framac\]"
expected_import="INFO: Results file frama-c.csv has been found and will be processed."
test_import_analysis_results "Frama-C" "Frama-C Dummy Project" "framac-dummy-project" "CNES_CPP_A" "c++" "tests/c_cpp" "framac" \
    "$ruleViolated" "$expected_sensor" "$expected_import"

exit $?
