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

  # add quality gate conditions
  add_condition "Blocker violations" blocker_violations GT ${GATEID} 0
  add_condition "Comment (%)" comment_lines_density LT ${GATEID} 20
  add_condition "Critical Issues" critical_violations GT ${GATEID} 0
  add_condition "Duplicated Lines (%)" duplicated_lines_density GT ${GATEID} 10
  add_condition "Duplicated Lines on New Code (%)" new_duplicated_lines GT ${GATEID} 0
  add_condition "Major Issues" major_violations GT ${GATEID} 0
  add_condition "New Issues" new_violations GT ${GATEID} 0
  add_condition "Technical Debt ratio" new_sqale_debt_ratio GT ${GATEID} 5
  add_condition "Technical Debt ratio" new_coverage LT ${GATEID} 90

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
#############################################################################################
# function add_rules
#
# Parameters :
# - 1 : Rules file in JSON format correponding the the following format (Sonarqube 6.7.1 API /api/rules answer)
#
# Description :
# Read JSON formatted file and add each rules in it with it's parameters into SonarQube's configuration.
#
#
##############################################################################################
add_rules(){
   file=$1
   log_info "Processing rules addition from file ${file}"
   total=$(jq '.total' ${file})
   total=$((${total}-1))
   for i in $(seq 0 ${total});
   do
	log_info "Adding custom rule $(jq -r '.rules['${i}'].key' ${file})"
	############## /API/RULES/CREATE
	#### Rules informations regristred using the rules creation API
	custom_key=$(jq -r '.rules['${i}'].key' ${file})
	markdown_description=$(jq '.rules['${i}'].mdDesc' ${file})
	name=$(jq -r '.rules['${i}'].name' ${file})
	severity=$(jq -r '.rules['${i}'].severity' ${file})
	status=$(jq -r '.rules['${i}'].status' ${file})
	template_key=$(jq -r '.rules['${i}'].templateKey' ${file})
        type=$(jq -r '.rules['${i}'].type' ${file})
	### Handling parameters
	parameters="params="
	for j in $(seq 0 $(($(jq '.rules['${i}'].params | length' ${file})-1)) );
	do
    param_key=$(jq -r '.rules['$i'].params['$j'].key' ${file})
    param_value=$(jq -r '.rules['$i'].params['$j'].defaultValue' ${file})
    parameters="${parameters}${param_key}=\"${param_value}\";"
	done
  parameters="${parameters::-1}"
  RES=$(curl -su admin:admin -X POST -d "custom_key=${custom_key}&markdown_description=${markdown_description}&name=${name}&severity=${severity}&status=${status}&template_key=${template_key}&type=${type}&${parameters}" 'http://localhost:9000/api/rules/create')
  key=$(echo $RES | jq -r '.rule.key')
  if [ "$(echo ${RES} | jq '(.errors | length)')" == "0" ]
	then
	    log_info "rule ${name} created in Sonarqube.."
        else
	    log_warning "impossible to create the rule ${name}" "$( echo ${RES} | jq '.errors[].msg' )"
	fi
	############ /API/RULES/UPDATE
	### Rules informations registred using the rule's update API.
	remediation_fn_base_effort=$(jq -r '.rules['${i}'].remFnBaseEffort' ${file})
	remediation_fn_type=$(jq -r '.rules['${i}'].defaultDebtRemFnType' ${file})
  RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/rules/update?key=$key&${parameters}")
	RES=$(curl -su admin:admin -X POST "${SONARQUBE_URL}/api/rules/update?key=$key&remediation_fn_base_effort=${remediation_fn_base_effort}&remediation_fn_type=${remediation_fn_type}")
	if [ "$(echo ${RES} | jq '(.errors | length)')" == "0" ]
	then
	    log_info "rule ${name} updated in Sonarqube."
        else
	    log_warning  "impossible to update the rule ${name}" "$( echo ${RES} | jq '.errors[].msg' )"
	fi
   done

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
    sleep 8
    log_info "retrieving Sonarqube's service status."
    sonar_status=$(curl -s -X GET "${SONARQUBE_URL}/api/system/status" | jq -r '.status')
    log_info "detected status ${sonar_status} for Sonarqube, expecting it to be UP."
  done
  log_info "detected status ${sonar_status} for Sonarqube, starting configuration of quality profiles."
  # Not executed : expecting news from https://community.sonarsource.com/t/using-rules-create-api/1243
  # API is returnin no detail informations
  # Find all rules templates named "*-rules-template.json" in the folder /tmp/conf and add rules into sonarqube configuration.
  find /tmp/conf -name "*-rules-template.json" -type f -print0 | while IFS= read -rd $'\0' file; do
      add_rules ${file}
  done

  # Find all files named "*-quality-profile.xml" in the folder /tmp/conf and add it in Sonarqube Quality profiles
  find /tmp/conf -name "*-quality-profile.xml" -type f -print0 | while IFS= read -rd $'\0' file; do
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

########################################################
# function custom_server_config
#
# Description :
# Customize SonarQube server configuration
# 
################################################################################
custom_server_config(){
  # Disable telemetry
  sed -i 's/#sonar\.telemetry\.enable=true/sonar\.telemetry\.enable=false/' /opt/sonarqube/conf/sonar.properties
  # Set default report path for Cppcheck
  echo 'sonar.cxx.cppcheck.reportPath=cppcheck-report.xml' >> /opt/sonarqube/conf/sonar.properties
  # Set default report path for Vera++
  echo 'sonar.cxx.vera.reportPath=vera-report.xml' >> /opt/sonarqube/conf/sonar.properties
  # Set default report path for RATS
  echo 'sonar.cxx.rats.reportPath=rats-report.xml' >> /opt/sonarqube/conf/sonar.properties
}

create_quality_profiles&&
create_quality_gates
custom_server_config

echo "[INFO] Docker CAT is ready to go and find bugs!"

exit 0
