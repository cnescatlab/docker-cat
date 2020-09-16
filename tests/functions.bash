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
