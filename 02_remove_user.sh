###
# This scripts will:
# 1. Remove a user from LDAP
# 2. Remove a user from MIT KDC
# 3. Delete the user home directory in HDFS
###


## User Defined Variables ##

#ldap bind credentials
LDAP_HOST="<host>:<port>"
LDAP_ROOT_USER="cn=<cn>,dc=<domian>,dc=<domian>,dc=<domian>"

#ldap domain
ldap_domain="dc=<domian>,dc=<domian>,dc=<domain>"

#hdfs_keytab
hdfs_keytab="hdfs-<hdp_cluster_name>@<DOMAIN>"

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
read -p 'Enter the Username to delete: ' username_var

# Capture LDAP Password
echo -e ""
echo -e ""
read -sp 'Enter Root LDAP Password: ' root_password_var

echo -e ""
read -sp 'Re-Enter the Root LDAP Password: ' root_password_retry_var
if [ "$root_password_var" != "$root_password_retry_var" ]; then
  echo "Passwords do not match"
  echo "Exiting..."
  exit 1
fi

## Remove User Group From LDAP ##

ldapdelete  -H ldap://$LDAP_HOST -D "cn=ldapadmin,$ldap_domain" -w $root_password_var  "cn=$username_var,ou=Group,$ldap_domain"
valid $? "Failed deleteing $username_var group from LDAP"

## Remove User From LDAP ##

ldapdelete  -H ldap://$LDAP_HOST -D "cn=ldapadmin,$ldap_domain" -w $root_password_var "uid=$username_var,ou=People,$ldap_domain"
valid $? "Failed deleteing $username_var user from LDAP"

## Remove User From Groups ##
tmp_remove_groups_file=/tmp/remove_groups_tmp.ldif
rm -f $tmp_remove_groups_file
cat <<EOT >> $tmp_remove_groups_file

dn: cn=sshusers,ou=Group,$ldap_domain
changetype: modify
delete: memberUid
memberUid: $username_var


dn: cn=wheel,ou=Group,$ldap_domain
changetype: modify
delete: memberUid
memberUid: $username_var

EOT

ldapmodify -w $root_password_var -H ldap://$LDAP_HOST -D $LDAP_ROOT_USER -f $tmp_remove_groups_file
valid $? "Failed removing $username_var from groups in LDAP"

rm -f $tmp_policy_file


# Verify User Deleted in LDAP
result=$(ldapsearch -v -w $root_password_var -H ldap://$LDAP_HOST -D $LDAP_ROOT_USER -b $ldap_domain | grep -w $username_var | wc -l)

if [ $result -ne 0 ]; then
  echo "Error: $username_var still exists in LDAP"
  echo "Exiting..."
  exit 3
fi

echo -e "\nFINISHED REMOVING $username_var from LDAP\n"

## Remove User From KDC ##

expect supporting_scripts/kerberos-remove-user-expect.exp $username_var $root_password_var
valid $? "Failed Removing Kerberos Principal for $username_var"
echo -e "\nFINISHED REMOVING KERBEROS PRINCIPLE FOR $username_var\n"

## Remove User HDFS Home Directory ##

# Create Directory
hdfs_user_home_dir="/user/$username_var"
kinit -kt /etc/security/keytabs/hdfs.headless.keytab $hdfs_keytab
hadoop fs -rm -R $hdfs_user_home_dir

#Verify Home Directory Deleted
hdfs dfs -test -d $hdfs_user_home_dir
result=${$?}
if [ $result -eq 0 ]; then
  valid 2 "Failed deleting  $hdfs_user_home_dir"
fi

echo -e "\nFINISHED REMOVING HDFS HOME DIRECTORY FOR $username_var\n"

## Verify No Kerberos Tickets ##

kdestroy
