#!/usr/bin/env bash

# This script is a test launcher.
# It runs a container of the image and launch all the scripts in
# the tests/ folder.
# It does not build the image.
#
# It must be launched from the root folder of the project like this:
#   $ ./tests/run_tests.bash
#
# Parameters:
#   --no-run: if this option is specified, the script will not run
#             the container. It will only launch the tests.
#             In this case, make sur to set necessary environment
#             variables.
#
# Environment:
#   CAT_CONTAINER_NAME: the name to give to the container running
#                             the image.
#   CAT_URL: URL of lequal/docker-cat container if already running
#                  without trailing / from the host.
#                  e.g. http://localhost:9000
#
# Examples:
#   $ ./tests/run_tests.bash
#   $ CAT_CONTAINER_NAME=my-cat ./tests/run_tests.bash --no-run

# Include default values of environment variables and functions
. tests/functions.bash

# Unless required not to, a container is run
if [ "$1" != "--no-run" ]
then
    # Run a container
    docker run --name "$CAT_CONTAINER_NAME" \
            -d --rm \
            -p 9000:9000 \
            -v tests:/media/sf_Shared:rw \
            -e ALLOWED_GROUPS="$(id -g)" \
            lequal/docker-cat:latest

    # When the script ends stop the container
    atexit()
    {
        docker container stop "$CAT_CONTAINER_NAME" > /dev/null
    }
    trap atexit EXIT
fi

# Wait the configuration of the image before running the tests
wait_cat_ready "$CAT_CONTAINER_NAME"

# Launch tests
failed="0"
nb_test="0"
for script in tests/*
do
    if [ -f "$script" ] && [ -x "$script" ] && [ "$script" != "tests/run_tests.bash" ]
    then
        # Launch each test (only print warnings and errors)
        echo -n "Launching test $script..."
        if ! ./"$script" > /dev/null;
        then
            echo "failed"
            ((failed++))
        else
            echo "success"
        fi
        ((nb_test++))
    fi
done
log "$INFO" "$failed tests failed out of $nb_test"

exit "$failed"
