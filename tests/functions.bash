#!/usr/bin/env bash

# This file contains useful functions for tests
# of the sonar-scanner.

# Default values of environment variables
if [ -z "$CAT_CONTAINER_NAME" ]
then
    export CAT_CONTAINER_NAME=cat
fi

if [ -z "$CAT_URL" ]
then
    export CAT_URL="http://localhost:9000"
fi

# ============================================================================ #

# log
#
# This function logs a line.
# Log levels are: INFO, ERROR
# INFO are logged on STDOUT.
# ERROR are logged on STDERR.
#
# Parameters:
#   1: level of log
#   2: message to log
#
# Example:
#   $ log "$ERROR" "Something went wrong"
export INFO="INFO"
export ERROR="ERROR"
log()
{
    msg="[$1] Test Docker-CAT: $2"
    if [ "$1" = "$INFO" ]
    then
        echo "$msg"
    else
        >&2 echo "$msg, raised by ${0##*/}"
    fi
}

# wait_cat_ready
#
# This function waits for CAT to be configured by
# the configure-cat.bash script.
# If this function is run in background, call wait
# at some point.
#
# Parameters:
#   1: name of the container running lequal/docker-cat
#
# Example:
#   $ wait_cat_ready cat-container
wait_cat_ready()
{
    container_name="$1"
    while ! docker container logs "$container_name" 2>&1 | grep -q '\[INFO\] Docker CAT is ready to go and find bugs!';
    do
        log "$INFO" "Waiting for Docker-CAT to be ready."
        sleep 5
    done
}

# test_language
#
# This function tests that docker-cat can analyze
# a project.
#
# Parameters:
#   1: language name to display
#   2: language key for SonarQube
#   3: folder name, relative to the tests/ folder
#   4: array of lines of sensors to look for in the scanner output
#   5: project key (sonar.projectKey of sonar-project.properties)
#   6: number of issues with the Sonar way Quality Profile
#   7: (optional) name of the CNES Quality Profile to apply, if any
#   8: (optional) number of issues with the CNES Quality Profile, if specified
#
# Environment variables used:
#   * CAT_CONTAINER_NAME
#   * CAT_URL
#
# Example:
#   sensors=(
#       "INFO: Sensor CheckstyleSensor \[checkstyle\]"
#       "INFO: Sensor FindBugs Sensor \[findbugs\]"
#       "INFO: Sensor PmdSensor \[pmd\]"
#       "INFO: Sensor CoberturaSensor \[cobertura\]"
#   )
#   test_language "Java" "java" "java" sensors "java-dummy-project" 3 "CNES_JAVA_A" 6
test_language()
{
    # Args
    languageName=$1
    languageKey=$2
    folder=$3
    local -n sensorsInfo=$4
    projectKey=$5
    nbIssues=$6
    cnesQp=$7
    nbIssuesCnesQp=$8

    # Run analysis
    output=$(docker exec "$CAT_CONTAINER_NAME" sonar-scanner \
                    "-Dsonar.host.url=http://localhost:9000" \
                    "-Dsonar.projectBaseDir=/media/sf_Shared/tests/$folder" \
                    2>&1)
    echo -e "$output"

    # Make sure all non-default for this language plugins were executed by the scanner
    for line in "${sensorsInfo[@]}"
    do
        if ! echo -e "$output" | grep -q "$line";
        then
            [[ $line =~ .*\[(.*)\\\] ]]
            log "$ERROR" "Failed: the scanner did not use ${BASH_REMATCH[1]}."
            log "$ERROR" "docker exec $CAT_CONTAINER_NAME sonar-scanner -Dsonar.host.url=http://localhost:9000 -Dsonar.projectBaseDir=/media/sf_Shared/tests/$folder"
            >&2 echo -e "$output"
            return 1
        fi
    done

    # Wait for SonarQube to process the results
    sleep 8

    # Check that the project was added to the server
    output=$(curl -su "admin:admin" \
                    "$CAT_URL/api/projects/search?projects=$projectKey")
    key=$(echo -e "$output" | jq -r '(.components[0].key)')
    if [ "$key" != "$projectKey" ]
    then
        log "$ERROR" "Failed: the project is not on the server."
        log "$ERROR" "curl -su admin:admin $CAT_URL/api/projects/search?projects=$projectKey"
        echo -e "$output" | >&2 jq
        return 1
    fi

    # Get the number of issues of the project
    output=$(curl -su "admin:admin" \
                    "$CAT_URL/api/issues/search?componentKeys=$projectKey")
    issues=$(echo -e "$output" | jq '.issues | map(select(.status == "OPEN" or .status == "TO_REVIEW")) | length')
    if [ "$issues" -ne "$nbIssues" ]
    then
        log "$ERROR" "Failed: there should be $nbIssues issues on the $languageName dummy project with the Sonar way QP but $issues were found"
        log "$ERROR" "curl -su admin:admin $CAT_URL/api/issues/search?componentKeys=$projectKey"
        echo -e "$output" | >&2 jq
        return 1
    fi

    log "$INFO" "Analysis with Sonar way QP ran as expected."

    # If the language does not have any CNES QP, the test ends
    if [ -z "$cnesQp" ]
    then
        log "$INFO" "Analyses succeeded, $languageName is supported."
        return 0
    fi

    # Switch to a CNES QP
    curl -su "admin:admin" \
        --data-urlencode "language=$languageKey" \
        --data-urlencode "project=$projectKey" \
        --data-urlencode "qualityProfile=$cnesQp" \
        "$CAT_URL/api/qualityprofiles/add_project"

    # Rerun the analysis
    docker exec "$CAT_CONTAINER_NAME" sonar-scanner \
            "-Dsonar.host.url=http://localhost:9000" \
            "-Dsonar.projectBaseDir=/media/sf_Shared/tests/$folder" \
                2>&1

    # Wait for SonarQube to process the results
    sleep 8

    # Switch back to the Sonar way QP (in case the test needs to be rerun)
    curl -su "admin:admin" \
        --data-urlencode "language=$languageKey" \
        --data-urlencode "project=$projectKey" \
        --data-urlencode "qualityProfile=Sonar way" \
        "$CAT_URL/api/qualityprofiles/add_project"

    # Get the new number of issues
    output=$(curl -su "admin:admin" \
                    "$CAT_URL/api/issues/search?componentKeys=$projectKey")
    issues=$(echo -e "$output" | jq '.issues | map(select(.status == "OPEN"  or .status == "TO_REVIEW")) | length')
    if [ "$issues" -ne "$nbIssuesCnesQp" ]
    then
        log "$ERROR" "Failed: there should be $nbIssuesCnesQp issues on the $languageName dummy project with the $cnesQp QP but $issues were found"
        log "$ERROR" "curl -su admin:admin $CAT_URL/api/issues/search?componentKeys=$projectKey"
        echo -e "$output" | >&2 jq
        return 1
    fi

    log "$INFO" "Analysis with $cnesQp QP ran as expected."
    log "$INFO" "Analyses succeeded, $languageName is supported."
    return 0
}

# test_analysis_tool
#
# This function tests that the image can run a
# specified code analyzer and that it keeps producing
# the same result given the same source code.
#
# Parameters:
#   1: tool name
#   2: tool command line
#   3: analysis results reference file
#   4: temporary results file
#   5: (optional) store the standard output in the temporary result file, either "yes" or "no" (default: "yes")
#
# Example:
#   $ cmd="pylint -f json --rcfile=/opt/python/pylintrc_RNC_sonar_2017_A_B tests/python/src/*.py"
#   $ test_analysis_tool "pylint" "$cmd" "tests/python/reference-pylint-results.json" "tests/python/tmp-pylint-results.json"
test_analysis_tool()
{
    # Args
    tool=$1
    cmd=($2)
    ref_file=$3
    tmp_file=$4
    store_output=$5

    # Run an analysis with the tool
    if [ "$store_output" = "no" ]
    then
        docker exec -w /media/sf_Shared -u "$(id -u):$(id -g)" "$CAT_CONTAINER_NAME" "${cmd[@]}"
    else
        docker exec -w /media/sf_Shared -u "$(id -u):$(id -g)" "$CAT_CONTAINER_NAME" "${cmd[@]}" > "$tmp_file"
    fi

    # Compare result of the analysis with the reference
    if ! diff "$tmp_file" "$ref_file";
    then
        log "$ERROR" "Failed: $tool reports are different."
        log "$ERROR" "=== Result ==="
        >&2 cat "$tmp_file"
        log "$ERROR" "=== Reference ==="
        >&2 cat "$ref_file"
        return 1
    fi

    log "$INFO" "Analysis succeeded, $tool works as expected."
    return 0
}

# test_import_analysis_results
#
# This function tests that the analysis results produced
# by an analysis tool can be imported in SonarQube. The results
# must be stored in the default file.
#
# Parameters:
#   1: tool name
#   2: project name
#   3: project key
#   4: quality profile to use
#   5: language key
#   6: folder to run the sonar-scanner in (relative to the root of the project)
#   7: folder containing the source files (relative to the previous folder)
#   8: id of a rule violated by a source file
#   9: line of output of the sonar-scanner that tells the import sensor is used
#   10: line of output of the sonar-scanner that tells the result file was imported
#   11: (optional) "yes" if if the rule violated needs to be activated in the Quality Profile for the import sensor to be run (default "no")
#
# Example:
#   $ ruleViolated="cppcheck:arrayIndexOutOfBounds"
#   $ expected_sensor="INFO: Sensor C++ (Community) CppCheckSensor \[cxx\]"
#   $ expected_import="INFO: CXX-CPPCHECK processed = 1"
#   $ test_import_analysis_results "CppCheck" "CppCheck Dummy Project" "cppcheck-dummy-project" "CNES_C_A" "c++" \
#       "tests/c_cpp" "cppcheck" "$ruleViolated" "$expected_sensor" "$expected_import"
test_import_analysis_results()
{
    # Args
    analyzerName=$1
    projectName=$2
    projectKey=$3
    qualityProfile=$4
    languageKey=$5
    languageFolder=$6
    sourceFolder=$7
    ruleViolated=$8
    expected_sensor=$9
    shift
    expected_import=$9
    activateRule="no"
    if [ $# -eq 10 ]
    then
        shift
        activateRule=$9
    fi

    if [ "$activateRule" = "yes" ]
    then
        # Get the key of the Quality Profile to use
        qpKey=$(curl -su "admin:admin" \
                        "$CAT_URL/api/qualityprofiles/search?qualityProfile=$qualityProfile" \
                | jq -r '.profiles[0].key')
        if [ "$qpKey" = "null" ]
        then
            log "$ERROR" "No quality profile named $qualityProfile"
            exit 1
        fi

        # Activate the rule in the Quality Profile to allow the Sensor to be used
        res=$(curl -su "admin:admin" \
                    --data-urlencode "key=$qpKey" \
                    --data-urlencode "rule=$ruleViolated" \
                    "$CAT_URL/api/qualityprofiles/activate_rule")
        if [ -n "$res" ] && [ "$(echo "$res" | jq -r '.errors | length')" -gt 0 ]
        then
            log "$ERROR" "Cannot activate rule $ruleViolated in $qualityProfile because: $(echo "$res" | jq -r '.errors[0].msg')"
            exit 1
        fi
    fi

    # Create a project on SonarQube
    res=$(curl -su "admin:admin" \
                --data-urlencode "name=$projectName" \
                --data-urlencode "project=$projectKey" \
                "$CAT_URL/api/projects/create")
    if [ -n "$res" ] && [ "$(echo "$res" | jq -r '.errors | length')" -gt 0 ]
    then
        log "$ERROR" "Cannot create a project with key $projectKey because: $(echo "$res" | jq -r '.errors[0].msg')"
        return 1
    fi

    # Set its Quality Profile for the given language to the given one
    res=$(curl -su "admin:admin" \
                --data-urlencode "language=$languageKey" \
                --data-urlencode "project=$projectKey" \
                --data-urlencode "qualityProfile=$qualityProfile" \
                "$CAT_URL/api/qualityprofiles/add_project")
    if [ -n "$res" ] && [ "$(echo "$res" | jq -r '.errors | length')" -gt 0 ]
    then
        log "$ERROR" "Cannot set Quality profile of project $projectKey to $qualityProfile for $languageKey language because: $(echo "$res" | jq -r '.errors[0].msg')"
        return 1
    fi

    # Analyse the project and collect the analysis files (that match the default names)
    analysis_output=$(docker exec -w "/media/sf_Shared/$languageFolder" "$CAT_CONTAINER_NAME" sonar-scanner \
                                    "-Dsonar.host.url=http://localhost:9000" \
                                    "-Dsonar.projectKey=$projectKey" \
                                    "-Dsonar.projectName=$projectName" \
                                    "-Dsonar.projectVersion=1.0" \
                                    "-Dsonar.sources=$sourceFolder" \
                                        2>&1)
    for line in "$expected_sensor" "$expected_import"
    do
        if ! echo -e "$analysis_output" | grep -q "$line";
        then
            log "$ERROR" "Failed: the output of the scanner miss the line: $line"
            >&2 echo -e "$analysis_output"
            return 1
        fi
    done
    echo -e "$analysis_output"

    # Wait for SonarQube to process the results
    sleep 10

    # Check that the issue was added to the project
    nbIssues=$(curl -su "admin:admin" \
                    "$CAT_URL/api/issues/search?componentKeys=$projectKey" \
                | jq -r ".issues | map(select(.rule == \"$ruleViolated\")) | length")
    if [ "$nbIssues" -ne 1 ]
    then
        log "$ERROR" "An issue should have been raised by the rule $ruleViolated"
        curl -su "admin:admin" "$CAT_URL/api/issues/search?componentKeys=$projectKey" | >&2 jq
        return 1
    fi

    # Delete the project
    res=$(curl -su "admin:admin" \
                --data-urlencode "project=$projectKey" \
                "$CAT_URL/api/projects/delete")
    if [ -n "$res" ] && [ "$(echo "$res" | jq -r '.errors | length')" -gt 0 ]
    then
        log "$ERROR" "Cannot delete the project $projectKey because: $(echo "$res" | jq -r '.errors[0].msg')"
        return 1
    fi

    if [ "$activateRule" = "yes" ]
    then
        # Deactivate the rule in the Quality Profile
        res=$(curl -su "admin:admin" \
                    --data-urlencode "key=$qpKey" \
                    --data-urlencode "rule=$ruleViolated" \
                    "$CAT_URL/api/qualityprofiles/deactivate_rule")
        if [ -n "$res" ] && [ "$(echo "$res" | jq -r '.errors | length')" -gt 0 ]
        then
            log "$ERROR" "Cannot deactivate rule $ruleViolated in $qualityProfile because: $(echo "$res" | jq -r '.errors[0].msg')"
            exit 1
        fi
    fi

    log "$INFO" "$analyzerName analysis results successfully imported in SonarQube."
    return 0
}
