#!/usr/bin/env bash

# User story:
# As a user of this image, I want to run Vera++ from within a container
# so that it produces a report.

. tests/functions.bash

ref="tests/c_cpp/reference-vera-results.xml"
output="tests/c_cpp/tmp-vera-results.xml"
cmd="vera++ -s -c $output tests/c_cpp/vera/main.cpp"
test_analysis_tool "Vera++" "$cmd" "$ref" "$output" "no"

exit $?
