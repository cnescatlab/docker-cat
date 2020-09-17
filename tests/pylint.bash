#!/usr/bin/env bash

# User story:
# As a user of this image, I want to run pylint from within a container
# so that it produces a report.

. tests/functions.bash

cmd="pylint -f json --rcfile=/opt/python/pylintrc_RNC_sonar_2017_A_B tests/python/src/*.py"
test_analysis_tool "pylint" "$cmd" "tests/python/reference-pylint-results.json" "tests/python/tmp-pylint-results.json"

exit $?
