#!/usr/bin/env bash

# User Story:
# As a SonarQube user, I want the SonarQube server to have the
# CNES Quality Profiles available so that I can use them.

. tests/functions.bash

cnes_quality_profiles=$(curl -s "$CAT_URL/api/qualityprofiles/search" \
                    | jq -r '.profiles | map(select(.name | startswith("CNES"))) | .[].name')

required_quality_profiles=(
    "CNES_JAVA_A"
    "CNES_JAVA_B"
    "CNES_JAVA_C"
    "CNES_JAVA_D"
    "CNES_PYTHON_A"
    "CNES_PYTHON_B"
    "CNES_PYTHON_C"
    "CNES_PYTHON_D"
    "CNES_CPP_A"
    "CNES_CPP_B"
    "CNES_CPP_C"
    "CNES_CPP_D"
    "CNES_C_A"
    "CNES_C_B"
    "CNES_C_C"
    "CNES_C_D"
    "CNES_C_EMBEDDED_A"
    "CNES_C_EMBEDDED_B"
    "CNES_C_EMBEDDED_C"
    "CNES_C_EMBEDDED_D"
)

for profile in "${required_quality_profiles[@]}"
do
    if ! echo "$cnes_quality_profiles" | grep -q "$profile";
    then
        log "$ERROR" "SonarQube server does not contain the profile $profile"
        >&2 echo "curl -s $CAT_URL/api/qualityprofiles/search"
        curl -s "$CAT_URL/api/qualityprofiles/search" | >&2 jq
        exit 1
    fi
done

log "$INFO" "all CNES quality profiles are available."
exit 0
