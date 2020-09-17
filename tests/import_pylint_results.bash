#!/usr/bin/env bash

# User story:
# As a user of this image, I want to be able to import the results
# of a pylint analysis to SonarQube.

. tests/functions.bash

ruleViolated="Pylint:C0326"
expected_sensor="INFO: Sensor PylintSensor \[python\]"
expected_import="INFO: Sensor PylintImportSensor \[python\]"
test_import_analysis_results "Pylint" "Pylint Dummy Project" "pylint-dummy-project" "CNES_PYTHON_A" "py" \
    "tests/python" "src" "$ruleViolated" "$expected_sensor" "$expected_import"

exit $?
