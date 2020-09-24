#!/usr/bin/env bash

# User story:
# As a user of this image, I want to analyze a Python project
# so that I can see its level of quality on the SonarQube server.

. tests/functions.bash

sensors=()
test_language "Python" "py" "python" sensors "python-dummy-project" 2 "CNES_PYTHON_A" 3

exit $?
