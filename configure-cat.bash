#!/bin/bash

# CONSTANTS
SONARQUBE_URL="http://localhost:9000"

##
# Parameters :
#  - 1 : status
#  - 2 : errors
#
log_error(){
  msg="[ERROR] docker-cat, $1 due to : $2."
  echo ${msg}
}

##
# Parameters :
#  - 1 : status
#  - 2 : errors
#
log_warning(){
  msg="[WARNING] docker-cat, $1 due to : $2."
  echo ${msg}
}


##
# Parameters
#  - 1 : status
log_info(){
 msg="[INFO] docker-cat, $1."
 echo ${msg}
}


#
# Parameters (not optional):
#  - 1 : metric_name
#  - 2 : metric_key
#  - 3 : metric_operator [EQ,NE, LT or GT]
#  - 4 : gate_id
#  - 5 : metric's error threshold ("none" if not to set)
add_condition(){
  metric_name=$1
  metric_key=$2
  metric_operator=$3
  gate_id=$4
  metric_errors=$5


  log_info "adding CNES quality gate condition : ${metric_name} ${metric_operator} thresholds : [ errors: ${metric_errors} ]"

  if [ "${metric_errors}" != "none" ]
  then
    threshold="&error=${metric_errors}"
  fi
  echo "threshold=${threshold}"

  RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/qualitygates/create_condition?gateId=${gate_id}&metric=${metric_key}&op=${metric_operator}${threshold}")
  if [ "$(echo ${RES} | jq '(.errors | length)')" == "0" ]
  then
    log_info "metric $metric_name condition succesfully added."
  else
    log_warning "impossible to add $metric_name condition" "$( echo ${RES} | jq '.errors[].msg' )"
  fi

}


create_quality_gates(){

  FILE=$1
  NAME=$(jq -r '.name' "$FILE")
  log_info "creating '$NAME' quality gate."
  res=$(curl -su "admin:admin" \
                --data-urlencode "name=$NAME" \
                "${SONARQUBE_URL}/api/qualitygates/create")
  if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
  then
      log_info "successfully created '$NAME' quality gate... now configuring it."
  else
      log_warning "impossible to create quality gate" "$(echo "${res}" | jq '.errors[].msg')"
  fi

  # Retrieve CNES quality gates ID
  log_info "retrieving '$NAME' quality gate ID."
  res=$(curl -su "admin:admin" \
              -G \
              --data-urlencode "name=$NAME" \
              "${SONARQUBE_URL}/api/qualitygates/show")
  if [ "$(echo "${res}" | jq '(.errors | length)')" == "0" ]
  then
      GATEID="$(echo "${res}" |  jq -r '.id')"
      log_info "successfully retrieved quality gate ID (ID=$GATEID)."
  else
      log_error "impossible to reach quality gate ID" "$(echo "${res}" | jq '.errors[].msg')"
  fi

  # Setting it as default quality gate
  if [ "$NAME" = "CNES" ]
  then
      log_info "setting CNES quality gate as default gate."
      res=$(curl -su "admin:admin" \
                  --data-urlencode "id=${GATEID}" \
                  "${SONARQUBE_URL}/api/qualitygates/set_as_default")
      if [ -z "$res" ]
      then
          log_info "successfully set CNES quality gate as default gate."
      else
          log_error "impossible to set CNES quality gate as default gate" "$(echo "${res}" | jq '.errors[].msg')"
      fi
  fi

  # add quality gate conditions
  # Adding all conditions of the JSON file
    log_info "adding all conditions of $FILE to the gate."
    len=$(jq '(.conditions | length)' "$FILE")
    cnes_quality_gate=$(jq '(.conditions)' "$FILE")
    actual_quality_gate=$(curl -su "admin:admin" \
                -G \
                --data-urlencode "name=$NAME" \
                "${SONARQUBE_URL}/api/qualitygates/show")
    conditions=$(echo "$actual_quality_gate" | jq -r '.conditions[]')
    for i in $(seq 0 $((len - 1)))
    do
        metric=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].metric)')
        op=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].op)')
        error=$(echo "$cnes_quality_gate" | jq -r '(.['"$i"'].error)')
        add_condition_to_quality_gate "$GATEID" "$conditions" "$metric" "$op" "$error"
    done
}

# add_condition_to_quality_gate
#
# This function adds a condition to an existing Quality Gate
# on a SonarQube server.
#
# Parameters:
#   1: gate_id
#   2: conditions
#   3: metric_key
#   4: metric_operator (EQ, NE, LT or GT)
#   5: metric's error threshold ("none" not to set it)
#
# Example:
#   $ add_condition_to_quality_gate "blocker_violations" "GT" "$GATEID" 0
add_condition_to_quality_gate()
{
    gate_id=$1
    conditions=$2
    metric_key=$3
    metric_operator=$4
    metric_errors=$5

    # Check if the metric is already configured
    existing_condition=$(echo "${conditions}" | jq -r "select(.metric == \"${metric_key}\")")

    # If the metric is already configured, update it
    if [ -n "$existing_condition" ]; then
        log_info "The metric '${metric}' is already configured. Updating it."
        condition_id=$(echo "${existing_condition}" | jq -r ".id")
        update_condition "$condition_id" "$metric_key" "$metric_operator" "$metric_errors"
    else
        # Add the new condition
        log_info "adding CNES quality gate condition: ${metric_key} ${metric_operator} ${metric_errors}."

        threshold=()
        if [ "${metric_errors}" != "none" ]
        then
            threshold=("--data-urlencode" "error=${metric_errors}")
        fi

        res=$(curl -su "admin:admin" \
                    --data-urlencode "gateId=${gate_id}" \
                    --data-urlencode "metric=${metric_key}" \
                    --data-urlencode "op=${metric_operator}" \
                    "${threshold[@]}" \
                    "${SONARQUBE_URL}/api/qualitygates/create_condition")
        if [ "$(echo "${res}" | jq '(.errors | length)')" != "0" ]; then
            log_warning "impossible to add ${metric_key} condition" "$(echo "${res}" | jq '.errors[].msg')"  
        fi
    fi
}

# update_condition
#
# Updates a condition in an existing Quality Gate
# on a SonarQube server.
#
# Parameters:
#   1: condition_id
#   2: metric_key
#   3: metric_operator (EQ, NE, LT or GT)
#   4: metric's error threshold ("none" not to set it)
#
# Example:
#   $ add_condition_to_quality_gate "blocker_violations" "GT" "$GATEID" 0
update_condition()
{
    condition_id=$1
    metric_key=$2
    metric_operator=$3
    metric_errors=$4

    threshold=()
    if [ "${metric_errors}" != "none" ]
    then
        threshold=("--data-urlencode" "error=${metric_errors}")
    fi

    res=$(curl -su "admin:admin" \
                --data-urlencode "id=${condition_id}" \
                --data-urlencode "metric=${metric_key}" \
                --data-urlencode "op=${metric_operator}" \
                "${threshold[@]}" \
                "${SONARQUBE_URL}/api/qualitygates/update_condition")
    if [ "$(echo "${res}" | jq '(.errors | length)')" != "0" ]; then
        log_warning "Impossible to update ${metric_key} condition" "$(echo "${res}" | jq '.errors[].msg')"
    fi
}


########################################################
# function add_profile
#
# Parameters :
# - 1 : Quality profile's file to import
#
# Description :
# Add quality profile in parameter in Sonarqube's
# 
################################################################################
add_profile(){
  file=$1
  log_info "processing profile addition for file ${file}"
  RES=$(curl POST -su admin:admin "${SONARQUBE_URL}/api/qualityprofiles/restore" --form backup=@${file})
  if [ "$(echo ${RES} | jq '(.errors | length)')" == "0" ]
  then
    log_info "quality profile ${file} successfully created."
  else
    log_warning "impossible to create ${file} quality profile" "$( echo ${RES} | jq '.errors[].msg' )"
  fi
}

########################################################
# function create_quality_profiles
#
# Description :
# Periodically verify Sonarqube's server status and wait until it's UP
# Once run, import quality profiles from /tmp/conf directory (Regex : *-quality-profile.xml)
################################################################################
create_quality_profiles(){
  sonar_status="DOWN"
  log_info "initiating connection with Sonarqube"
  sleep 15
  while [ "${sonar_status}" != "UP" ]
  do
    sleep 20
    log_info "retrieving Sonarqube's service status."
    sonar_status=$(curl -s -X GET "${SONARQUBE_URL}/api/system/status" | jq -r '.status')
    log_info "detected status ${sonar_status} for Sonarqube, expecting it to be UP."
  done
  log_info "detected status ${sonar_status} for Sonarqube, starting configuration of quality profiles."

  for file in $(find /opt/sonarqube/conf/quality_profiles -mindepth 2 -maxdepth 2 -type f)
  do
    add_profile "${file}"
  done
  log_info "added all quality profiles."
}

run_sonarqube(){

  set -e
  if [ "${1:0:1}" != '-' ]; then
    exec "$@"
  fi

  chown -R sonarqube:sonarqube $SONARQUBE_HOME
  exec gosu sonarqube \
    java -jar $SONARQUBE_HOME/lib/sonar-application-$SONAR_VERSION.jar \
    -Dsonar.log.console=true \
    -Dsonar.jdbc.username="$SONARQUBE_JDBC_USERNAME" \
    -Dsonar.jdbc.password="$SONARQUBE_JDBC_PASSWORD" \
    -Dsonar.jdbc.url="$SONARQUBE_JDBC_URL" \
    -Dsonar.web.javaAdditionalOpts="$SONARQUBE_WEB_JVM_OPTS -Djava.security.egd=file:/dev/./urandom" \
    "$@"
}

stop_sonarqube(){
  pkill -u sonarqube
}


create_quality_profiles

for qg_file in /opt/sonarqube/conf/quality_gates/*
do
  create_quality_gates "$qg_file"
done



echo "[INFO] Docker CAT is ready to go and find bugs!"

exit 0
