#!/usr/bin/env bash

# User story:
# As a user of this image, I want to run shellcheck from within a container
# so that it produces a report.

. tests/functions.bash

cmd="shellcheck -s sh -f checkstyle tests/shell/src/*.sh"
test_analysis_tool "shellcheck" "$cmd" "tests/shell/reference-shellcheck-results.xml" "tests/shell/tmp-shellcheck-results.xml"

exit $?
