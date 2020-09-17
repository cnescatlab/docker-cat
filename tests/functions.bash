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
    output=$(docker exec "$CAT_CONTAINER_NAME" \
                /opt/sonar-scanner/bin/sonar-scanner \
                    "-Dsonar.host.url=http://localhost:9000" \
                    "-Dsonar.projectBaseDir=/media/sf_Shared/$folder" \
                    2>&1)
    echo -e "$output"

    # Make sure all non-default for this language plugins were executed by the scanner
    for line in "${sensorsInfo[@]}"
    do
        if ! echo -e "$output" | grep -q "$line";
        then
            [[ $line =~ .*\[(.*)\\\] ]]
            log "$ERROR" "Failed: the scanner did not use ${BASH_REMATCH[1]}."
            log "$ERROR" "docker exec $CAT_CONTAINER_NAME /opt/sonar-scanner/bin/sonar-scanner -Dsonar.host.url=http://localhost:9000 -Dsonar.projectBaseDir=/media/sf_Shared/$folder"
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
    docker exec "$CAT_CONTAINER_NAME" \
        /opt/sonar-scanner/bin/sonar-scanner \
            "-Dsonar.host.url=http://localhost:9000" \
            "-Dsonar.projectBaseDir=/media/sf_Shared/$folder" \
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
