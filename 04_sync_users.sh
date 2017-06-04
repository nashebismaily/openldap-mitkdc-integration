#!/bin/bash
###
# This scripts will:
# 1. Sync all users to Ambari and Ranger from LDAP
#
# Author: Nasheb Ismaily
#
# All rights reserved - Do Not Redistribute
###

## User Defined Variables ##

#ambari admin username/password
ambari_user=admin
ambari_password=admin

#ambari url
ambari_host_url=http(s)://<ambari_host>:<port>

#hdp cluster name
hdp_cluster_name=<HDP_CLUSTER_NAME>

function wait(){
  finished=0
  while [ $finished -ne 1 ]
  do
    str=$(curl -s -k -u $ambari_user:$ambari_password $ambari_host_url/api/v1/clusters/$hdp_cluster_name/services/$1 |grep "state" |grep $2 | wc -l)
    if [ $str -eq 1 ]
    then
      echo "Ranger State is now $2"
      finished=1
    fi
    echo "Waiting For Ranger State: $2..."
    echo "Sleeping 3 seconds"
    sleep 3
  done
}

## Verify No Kerberos Tickets ##

kdestroy

#Sync Ambari

expect supporting_scripts/sync_ambari_expect.exp $ambari_user $ambari_password

echo -e "\nFINISHED SYNCING AMBARI\n"

#Sync Ranger

#Stop
curl -k -u $ambari_user:$ambari_password -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER_USERSYNC via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' $ambari_host_url/api/v1/clusters/$hdp_cluster_name/services/RANGER

#Wait
wait RANGER "INSTALLED"

#Start
curl -k -u $ambari_user:$ambari_password -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start RANGER_USERSYNC via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' $ambari_host_url/api/v1/clusters/$hdp_cluster_name/services/RANGER

#Wait
wait RANGER "STARTED"

## Verify No Kerberos Tickets ##

kdestroy

echo -e "\nFINISHED SYNCING RANGER\n"


exit 0
