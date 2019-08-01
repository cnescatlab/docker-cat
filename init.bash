#!/bin/bash

########################################################
# init.bash
#
# IMPORTANT :
# This file is intended to run be run while running SonarQube on the docker image "docker-cat".
# This file should be run as an ENTRYPOINT of docker's image. If you re-use the docker-cat image, call this file inside your entrypoint.
# The Dockerfile docker-cat inherit Sonarqube 6.7.7 image. This script run Sonarqube's entrypoint.
#
# Description :
# This file configure Sonarqube, also, it's perform permissions modifications to allow CNES scanner to involve in the project (creating sonar-properties files, etc...).
#
########################################################

sonar_configuration="INIT"

########################################################
# function allow_sonarqube
#
# Description :
# For each GID specified in the env variable ALLOWED_GROUPS, create a new group
# siwht the specified GID and then add it to Sonarqube.
################################################################################
allow_sonarqube(){
    IFS=";" read -ra GID <<< "${ALLOWED_GROUPS}"
	if [ ${#GID[@]} -gt 0 ]
    then
        echo "[INFO] Docker-cat is now adding user permissions to Sonarqube."
        for i in "${GID[@]}"
        do
          if ! [[ "${i}" =~ "[0-9]+" ]]
          then
            echo "[INFO] Docker-cat is giving group permissions GID no. ${i} to Sonarqube."
            groupadd group-${i}
            groupmod -g ${i} group-${i}
            usermod -aG group-${i} sonarqube
          else
            echo "[ERROR] Specified GROUP ID ${i} is not a number ! "
          fi
        done
    else
      echo "[INFO] Docker-cat could not find any specified permission for Sonarqube. Use allow-group command to set new ones."
    fi

    echo "[INFO] Docker-cat permissions for sonarqube finished."
}

allow_sonarqube &
wait %1
# Call for configure-cat script to set quality profiles and quality gates.
bash /tmp/configure-cat.bash &
#sudo -u sonarqube exec ${SONARQUBE_HOME}/bin/run.sh
su sonarqube
exec "${SONARQUBE_HOME}/bin/run.sh"
