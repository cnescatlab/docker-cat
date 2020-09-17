#!/usr/bin/env bash

# User story:
# As a user of this image, I want to run cppcheck from within a container
# so that it produces a report.

. tests/functions.bash

ref="tests/c_cpp/reference-cppcheck-results.xml"
output="tests/c_cpp/tmp-cppcheck-results.xml"
cmd="cppcheck --xml-version=2 tests/c_cpp/cppcheck/main.c --output-file=$output"
test_analysis_tool "cppcheck" "$cmd" "$ref" "$output" "no"

exit $?
