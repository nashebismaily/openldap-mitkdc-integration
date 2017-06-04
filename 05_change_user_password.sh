#!/bin/bash
###
# This scripts will:
# 1. Change a User's Password
#
# Author: Nasheb Ismaily
#
# All rights reserved - Do Not Redistribute
###

## User Defined Variables ##

#ldap bind credentials
LDAP_HOST="<host>:<port>"
LDAP_ROOT_USER="cn=<cn>,dc=<domian>,dc=<domian>,dc=<domian>"


## Functions ##
valid(){
  retval=$1
  comment=$2
  if [ $retval -ne 0 ]; then
    echo "$comment"
    echo "Exiting"
    exit 2
  fi
}

## Verify No Kerberos Tickets ##

kdestroy

echo -e ""
read -p 'Enter the Username for password change: ' username_var
read -sp 'Enter the New Password: ' password_var

echo -e ""
read -sp 'Re-Enter the Password: ' password_retry_var
if [ "$password_var" != "$password_retry_var" ]; then
  echo "Passwords do not match"
  echo "Exiting..."
  exit 1
fi

if [ ${#password_var} -lt 15 ]; then
  echo "ERROR: Password must be atleast 15 characters"
  echo "Exiting..."
  exit 1
fi

# Capture LDAP Password
echo -e ""
echo -e ""
read -sp 'Enter Root LDAP Password: ' root_password_var

echo -e ""
read -sp 'Re-Enter the root LDAP Password: ' root_password_retry_var
if [ "$root_password_var" != "$root_password_retry_var" ]; then
  echo "Passwords do not match"
  echo "Exiting..."
  exit 1
fi

# Change LDAP Password
expect supporting_scripts/change_ldap_password.exp $username_var $password_var $root_password_var
valid $? "Failed changing LDAP Password"

echo -e "\nFINISHED CHANGEING LDAP PASSWORD FOR $username_var\n"


#Change MIT KDC Password
expect supporting_scripts/kerberos-change-user-password-expect.exp $username_var $password_var $root_password_var
valid $? "Failed changing MIT KDC Password"

## Verify No Kerberos Tickets ##

kdestroy

echo -e "\nFINISHED CHANGEING MIT KDC PASSWORD FOR $username_var\n"
