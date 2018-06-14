#!/bin/bash

# CONSTANTS
SONARQUBE_URL="http://localhost:9000"

##
# Parameters : 
#  - 1 : status
#  - 2 : errors
#
log_error(){
  status=$1
  errors=$2
  msg="[ERROR] docker-cat, ${status} due to : ${errors}."
  echo ${msg}
  exit 1
}

##
# Parameters : 
#  - 1 : status
#  - 2 : errors
#
log_warning(){
  status=$1
  errors=$2
  msg="[WARNING] docker-cat, ${status} due to : ${errors}."
  echo ${msg}
}


##
# Parameters
#  - 1 : status
log_info(){
 status=$1 
 msg="[INFO] docker-cat, $status."
 echo ${msg}
}


#
# Parameters (not optional): 
#  - 1 : metric_name
#  - 2 : metric_key
#  - 3 : metric_operator [EQ,NE, LT or GT]
#  - 4 : gate_id
#  - 5 : overleak period 1 or 0
#  - 6 : metric's warning threshold ("none" if not to set)
#  - 7 : metric's error threshold ("none" if not to set)
add_condition(){
  metric_name=$1
  metric_key=$2
  metric_operator=$3
  gate_id=$4
  overleak=$5
  metric_warnings=$6
  metric_errors=$7


  log_info "adding CNES quality gate condition : ${metric_name} ${metric_operator} thresholds : [ warnings: ${metric_warnings} ] [ errors: ${metric_errors}] and overleak set on ${overleak}"

  if [ "${metric_warnings}" != "none" ] && [ "${metric_errors}" != "none" ]
  then
    threshold="&warning=${metric_warnings}&error=${metric_errors}"
  elif [ "${metric_errors}" != "none" ]
  then
    threshold="&error=${metric_errors}"
  elif [ "${metric_warnings}" != "none" ]
  then
    threshold="&warning=${metric_warnings}"
  fi
  echo "threshold=${threshold}"
  if [ "${overleak}" != "1" ]
  then
    unset overleak
  else
    overleak="&period=1"
  fi
  RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/qualitygates/create_condition?gateId=${gate_id}&metric=${metric_key}&op=${metric_operator}${overleak}${threshold}")
  if [ "$(echo ${RES} | jq '(.errors | length)')" == "0" ] 
  then
    log_info "metric $metric_name condition succesfully added."
  else
    log_warning "impossible to add $metric_name condition" "$( echo ${RES} | jq '.errors[].msg' )"
  fi

  
}


create_quality_gates(){
 
  log_info "creating CNES quality gate"
  RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/qualitygates/create?name=CNES")
  if [ "$(echo ${RES} | jq '(.errors | length)')" == "0" ] 
  then
    log_info "successfully created CNES quality gate... now configuring it."
  else
    log_warning "impossible to create quality gate" "$( echo ${RES} | jq '.errors[].msg' )"
  fi

  # Retrieve CNES quality gates ID
  log_info "retrieving CNES quality gate ID"
  RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/qualitygates/show?name=CNES")
  if [ "$( echo ${RES} | jq '(.errors | length)')" == "0" ] 
  then
    GATEID=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/qualitygates/show?name=CNES" |  jq '.id')
    log_info "successfully retrived CNES quality gate ID (ID=$GATEID)"
  else
    log_error "impossible to reach CNES quality gate ID" "$( echo ${RES} | jq '.errors[].msg' )"
  fi 

  # Configure ratio comment
  log_info "setting CNES quality get as default gate"
  RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/qualitygates/set_as_default?id=${GATEID}")
  if [ "$( echo ${RES} | jq '(.errors | length)')" == "0" ] 
  then
    log_info "successfully set CNES quality gate ID as default gate"
  else
    log_warning "impossible to set CNES quality gate as default gate" "$( echo ${RES} | jq '.errors[].msg' )"
  fi

  # add comment_lines condition
  add_condition "Blocker violations" blocker_violations NE ${GATEID} 0 none 0
  add_condition "Comment (%)" comment_lines_density LT ${GATEID} 0 30 20
  add_condition "Comment (%)" comment_lines_density LT ${GATEID} 1 0 none
  add_condition "Critical Issues" critical_violations NE ${GATEID} 0 none 0
  add_condition "Duplicated Lines (%)" duplicated_lines_density GT ${GATEID} 0 10 15
  add_condition "Duplicated Lines on New Code (%)" new_duplicated_lines_density GT ${GATEID} 1 0 10
  add_condition "Major Issues" major_violations NE ${GATEID} 0 0 none 
  add_condition "New Major Issues" new_major_violations GT ${GATEID} 1 none 0
  #add_condition "Technical Debt ratio" sqale_rating GT ${GATEID} 1 0 5
}

########################################################
# function configure_sonarqube
#
# Description : 
# Periodically verify Sonarqube's server status and wait until it's UP
# Once run, import quality profiles from /tmp/conf directory (Regex : *-quality-profile.xml)
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

create_quality_profiles(){
  sonar_status="DOWN"
  log_info "initiating connection with Sonarqube"
  sleep 15
  while [ "${sonar_status}" != "UP" ]
  do
    sleep 8
    log_info "retrieving Sonarqube's service status."
    sonar_status=$(curl -s -X GET "${SONARQUBE_URL}/api/system/status" | jq -r '.status')
    log_info "detected status ${sonar_status} for Sonarqube, expecting it to be UP."
  done
  log_info "detected status ${sonar_status} for Sonarqube, starting configuration of quality profiles."

  find /tmp/conf -name "*.xml" -type f -print0 | while IFS= read -rd $'\0' file; do
    add_profile "${file}"
  done 

  log_info "finished to configure quality profiles".
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


#run_sonarqube&
create_quality_profiles&&
create_quality_gates


#stop_sonarqube


exit 0
