#!/usr/bin/env bash

# User story:
# As a user of this image, I want to run Frama-C from within a container
# so that it produces a report.

. tests/functions.bash

ref="tests/c_cpp/reference-framac-results.txt"
output="tests/c_cpp/tmp-framac-results.txt"
report="tests/c_cpp/frama-c.csv"
cmd="frama-c tests/c_cpp/framac/CruiseControl*.c -rte -metrics -report-csv $report"
test_analysis_tool "Frama-C" "$cmd" "$ref" "$output"

exit $?
