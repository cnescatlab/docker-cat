#!/usr/bin/env bash

# User story:
# As a user of this image, I want to run RATS from within a container
# so that it produces a report.

. tests/functions.bash

ref="tests/c_cpp/reference-rats-results.xml"
output="tests/c_cpp/tmp-rats-results.xml"
cmd="rats --quiet --nofooter --xml -w 3 tests/c_cpp/rats"
test_analysis_tool "RATS" "$cmd" "$ref" "$output"

exit $?
