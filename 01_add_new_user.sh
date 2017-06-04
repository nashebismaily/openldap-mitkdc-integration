#!/bin/bash
###
# This scripts will:
# 1. Add a user to OpenLDAP
# 2. Add a kereberos principle to the MIT KDC
# 3. Create the hdfs user directories and set permissions
#
# Author: Nasheb Ismaily
#
# All rights reserved - Do Not Redistribute
###

## User Defined Variables ##

#ldap bind credentials
LDAP_HOST="<host>:<port>"
LDAP_ROOT_USER="cn=<cn>,dc=<domian>,dc=<domian>,dc=<domian>"

#ldap - linux user home directory
user_home_dir="/home/<DOMAIN>"

#ldap manager user
ldap_manager="cn=Manager,dc=<domian>,dc=<domian>,dc=<domian>"

#ldap domain
ldap_domain="dc=<domian>,dc=<domian>,dc=<domain>"

#hdfs_keytab
hdfs_keytab="hdfs-<hdp_cluster_name>@<DOMAIN>"

## Script Variables ##

#ldap groups
groups_var="wheel,ssh"

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

## Add a user to OpenLDAP ##

echo -e ""
read -p 'Enter the New Username: ' username_var
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

# Create localuser
useradd -d $user_home_dir/$username_var $username_var

# Export User and Group
grep $username_var /etc/passwd > /tmp/users
valid $? "Failed creating /tmp/users"
grep $username_var /etc/group > /tmp/groups 
valid $? "Failed creating /tmp/groups"

#Create Ldif Files
/usr/share/migrationtools/migrate_passwd.pl /tmp/users /tmp/users.ldif
valid $? "Failed creating /tmp/users.ldif"
/usr/share/migrationtools/migrate_group.pl /tmp/groups /tmp/groups.ldif
valid $? "Failed creating /tmp/groups.ldif"


#Import Files to LDAP
#Ignore failure from groups already existing
ldapadd -x -D $ldap_manager -w $root_password_var -f /tmp/groups.ldif 
ldapadd -x -D $ldap_manager -w $root_password_var -f /tmp/users.ldif 
valid $? "Failed adding /tmp/users.ldif to LDAP"

# Verify User Exists in LDAP
result=$(ldapsearch -v -w $root_password_var -H ldap://$LDAP_HOST -D $LDAP_ROOT_USER -b $ldap_domain | grep -w $username_var | wc -l)

if [ $result -eq 0 ]; then
  echo "Unable to verify user in ldap"
  echo "Exiting..."
  exit 3
fi

#Add User to Password Policy
tmp_policy_file=/tmp/policy_tmp.ldif
rm -f $tmp_policy_file
cat <<EOT >> $tmp_policy_file
dn: uid=$username_var,ou=People,$ldap_domain
changetype: modify
add: pwdPolicySubentry
pwdPolicySubentry: cn=passwordDefault,ou=Policies,$ldap_domain
EOT

ldapmodify -w $root_password_var -H ldap://$LDAP_HOST -D $LDAP_ROOT_USER -f $tmp_policy_file
valid $? "Failed modifying policy for user in LDAP"

rm -f $tmp_policy_file

# Change User Password

## Call Expect Script

expect supporting_scripts/change_ldap_password.exp $username_var $password_var $root_password_var
valid $? "Failed changing LDAP Password"

#ldappasswd -h ldap://$ldap_host -d $ldap_root_user -w $root_password_var -s "uid=$username_var,ou=people,$ldap_domain"

# Modify Group Password
tmp_group_file=/tmp/groups_tmp.ldif
rm -f $tmp_group_file
cat <<EOT >> $tmp_group_file


dn: cn=wheel,ou=Group,$ldap_domain
changetype: modify
add: memberuid
memberuid: $username_var 

dn: cn=sshusers,ou=Group,$ldap_domain
changetype: modify
add: memberuid
memberuid: $username_var 

EOT

ldapmodify -w $root_password_var -H ldap://$LDAP_HOST -D $LDAP_ROOT_USER -f $tmp_group_file
valid $? "Failed modifying groups for user in LDAP"
rm -f $tmp_group_file

echo -e "\nFINISHED ADDING USER $username_var TO LDAP\n"


## Add Principle to MIT KDC ##

expect supporting_scripts/kerberos-add-user-expect.exp $username_var $password_var $root_password_var
valid $? "Failed Creating Kerberos Principal"
echo -e "\nFINISHED ADDING KERBEROS PRINCIPLE FOR $username_var\n"


## Create HDFS User directory and set permissions ##

# Create Directory
hdfs_user_home_dir="/user/$username_var"
kinit -kt /etc/security/keytabs/hdfs.headless.keytab $hdfs_keytab
hadoop fs -mkdir $hdfs_user_home_dir
hadoop fs -chown $username_var:$username_var $hdfs_user_home_dir

#Verify Home Directory
hdfs dfs -test -d $hdfs_user_home_dir
valid $? "Failed creating $hdfs_user_home_dir"
result=$(hdfs dfs -ls /user |grep $username_var | wc -l)
if [ $result -ne 1 ]; then
  valid 2 "Failed setting permissions on $hdfs_user_home_dir"
fi

# Destory Kerberos Ticket

kdestroy

echo -e "\nFINISHED CREATING HDFS HOME DIRECTORY FOR $username_var\n"

echo -e ""
read -p 'Would You Like To Sync AMBARI and RANGER Now ?(yes/no): ' sync_users

if [ $sync_users == "yes" ] || [ $sync_users == "y" ] || [ $sync_users == "Y" ]; then
  ./04_sync_users.sh
  valid $? "Syncing Users Failed"
else
  echo -e ""
  echo "run ./04_sync_users.sh when you are ready to sync the users"
  echo -e ""
fi

