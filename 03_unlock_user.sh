###
# This scripts will:
# 1. Unlock a user from LDAP
# 2. Unlock a user from MIT KDC
#
# Author: Nasheb Ismaily
#
# All rights reserved - Do Not Redistribute
###



## User Defined Variables ##

#ldap bind credentials
LDAP_HOST="<host>:<port>"
LDAP_ROOT_USER="cn=<cn>,dc=<domian>,dc=<domian>,dc=<domian>"

#ldap domain
ldap_domain="dc=<domian>,dc=<domian>,dc=<domain>"

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


# Unlock User From LDAP

# Verify No Kerberos Tickets ##

kdestroy

echo -e ""
read -p 'Enter the Username to unlock: ' username_var

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

#Unlock User From LDAP
tmp_unlock_file=/tmp/unlock_tmp.ldif
rm -f $tmp_unlock_file
cat <<EOT >> $tmp_unlock_file
dn: uid=$username_var,ou=People,$ldap_domain
changetype: modify
delete: pwdAccountLockedTime
EOT

ldapmodify -w $root_password_var -H ldap://$LDAP_HOST -D $LDAP_ROOT_USER -f $tmp_unlock_file

echo -e "\nFINISHED UNLOCKING $username_var FROM LDAP\n"

# Unlock User From MIT KDC

expect supporting_scripts/kerberos-unlock-user-expect.exp $username_var $root_password_var
valid $? "Failed unlocking user from KDC"

## Verify No Kerberos Tickets ##

kdestroy

echo -e "\nFINISHED UNLOCKING $username_var FROM KDC\n"

echo -e ""
echo "In order to unlock a user from ssh-ing into a server..."
echo "Login to the server which the user cannot log into and"
echo "Run the command:  faillock --user <USER_NAME> --reset"
echo -e ""
