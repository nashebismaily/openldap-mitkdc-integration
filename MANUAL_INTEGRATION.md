# Manually Adding Users to OpenLdap, MIT KDC, and HDP
 
Note: In this example, we will be adding the user: test_user  

## Add User to LDAP & MIT KDC. Create User Keytab

Create and Add the Users:  

useradd -d /home/<DOMAIN>/test_user test_user  
grep test_user /etc/group > /tmp/groups  
grep test_user /etc/passwd > /tmp/users  
cd /usr/share/migrationtools/  
./migrate_group.pl /tmp/groups /tmp/groups.ldif  
./migrate_passwd.pl /tmp/users /tmp/users.ldif  
ldapadd -H ldaps://<ldap_host>:<ldap_port> -D cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain> -W -f /tmp/groups.ldif  
password: `<PASSWORD>`  
ldapadd -H ldaps://<ldap_host>:<ldap_port> -D cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain> -W -f /tmp/users.ldif  
password: `<PASSWORD>`  

Add User to Password Policy:  

cd /root/ldap/policy  
Edit add_user_passwd_policy.ldif  
uid=test_user  
ldapmodify -W -H ldaps://<ldap_host>:<ldap_port> -D cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain> -f add_user_passwd_policy.ldif  
password: `<PASSWORD>`  

Create User Password (must be at least 15 characters): 

ldappasswd -H ldaps://<ldap_host>:<ldap_port> -D cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain> -W -S "uid=test_user,ou=People,dc=<domain>,dc=<domain>,dc=<domain>"  
Enter new password twice  
Enter ldapadmin password: `<PASSWORD>`  

Modify Group Membership:  

cd /root/ldap/groups  
change user in add_user_to_group.ldif  
ldapmodify -H ldaps://<ldap_host>:<ldap_port> -W -D "cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain>" -f add_user_to_group.ldif  
password: `<PASSWORD>`  

Add Kerberos Principal:  

kadmin  
password: `<PASSWORD>`  
addprinc -policy `<POLICY>` test_user  
`<ldap_password>`  
`<ldap_password>`  
q  

Create User Keytab:

cd /etc/security/keytabs  
ktutil  
add_entry -password -p test_user@<DOMAIN> -k 1 -e aes256-ctshmac-sha1-96  
password: `<ldap_password>`    
add_entry -password -p test_user@<DOMAIN> -k 1 -e aes128-ctshmac-sha1-96  
password: `<ldap_password>`  
add_entry -password -p test_user@<DOMAIN> -k 1 -e des3-cbc-sha1  
password: `<ldap_password>`  
add_entry -password -p test_user@<DOMAIN> -k 1 -e arcfour-hmacmd5  
password: `<ldap_password>` 
add_entry -password -p test_user@<DOMAIN> -k 1 -e arcfour-hmacmd5- 
exp  
password: `<ldap_password>`  
add_entry -password -p test_user@<DOMAIN> -k 1 -e des-cbc-md5  
password: `<ldap_password>`  
add_entry -password -p test_user@<DOMAIN> -k 1 -e des-cbc-crc  
password: `<ldap_password>`  
write_kt test_user.keytab  
q  

chown test_user: test_user test_user.keytab  

Delete Local User:  

userdel -r test_use  r  

Sync Ambari:
  
ambari-server sync-ldap --all  
username: admin  
password: admin  

Sync Ranger:   

Stop Ranger:  
curl -k -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d'{"RequestInfo": {"contxt" :"Stop RANGER_USERSYNC via REST"},"Body": {"ServiceInfo": {"state": "INSTALLED"}}}' https://<ambari_host>:<ambari_port>/api/v1/clusters/<CLUSTER_NAME>/services/RANGER  

Start Ranger:
curl -k -u admin:admin -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo":{"context" :"Start RANGER_USERSYNC via REST"}, "Body": {"ServiceInfo": {"state":"STARTED"}}}' https://<ambari_host>:<ambari_port>/api/v1/clusters/<CLUSTER_NAME>/services/RANGER  

## Delete User From OpenLDAP, MIT KDC, and HDP
Note: In this example, we will be removing the user: test_user  

Delete User: 

ldapdelete -H ldaps://<ldap_host>:<ldap_port> -D "cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain>" -W "uid=test_user,ou=People,dc=<domain>,dc=<domain>,dc=<domain>"  
password: `<PASSWORD>`  

Delete Group:

ldapdelete -H ldaps://<ldap_host>:<ldap_port> -D "cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain>" -W "cn=test_user,ou=Group,dc=<domain>,dc=<domain>,dc=<domain>"  
password: `<PASSWORD>`  

Remove Group Memberships:  

cd /root/ldap/groups  
Edit remove_user_from_group.ldif, change members to test_user  
Modify memberUid  
ldapmodify -x -W -D "cn=Manager,dc=<domain>,dc=<domain>,dc=<domain>" -f remove_user_from_group.ldif  
password: `<PASSWORD>`  

Remove User From Kerberos:  
kadmin  
password: `<PASSWORD>`  
delprinc test_user  
yes  
q  

Remove User Keytab:  
rm -f /etc/security/keytabs/test_user.keytab  

## Unlock Account From OpenLDAP and MIT KDC

Note: In this example, we will be unlocking the user: test_user  

Unlock LDAP Account:  
cd /root/ldap/users  
Edit unlock_user.ldif, change uid=<username> to uid=test_user  
ldapmodify -W -H ldaps://<ldap_host>:<ldap_port> -D cn=ldapadmin,dc=<domain>,dc=<domain>,dc=<domain> -f unlock_user.ldif  
password: `<PASSWORD>`  

Unlocal MIT KDC Account:  
faillock --user admin --reset  

## Author
Nasheb Ismaily
