## OPENLDAP - MIT KDC INTEGRATION + HDP - AMBARI, RANGER, NIFI INTEGRATION

The following scripts integrate Openldap and MITKDC user management.
The scripts also update Ambari, Ranger, and Nifi (Hortonworks Stack)  with the updated users/groups via ldap sync.

View the MANUAL_INTEGRATION document to get a better understanding of how the scripts work.
This document will walk you though all the automated commands in the scripts.

SCRIPTS TO AUTOMATE USER COMMANDS (ADD USER, REMOVE USER, UNLOCK USER,
CHANGE USER PASSWORD, SYNC USER)
• Login to LDAP Server
• sudo su
• cd /root/ldap
⁃ you will find the following scripts:
⁃ 01_add_new_user.sh
⁃ 02_remove_user.sh
⁃ 03_unlock_user.sh
⁃ 04_sync_users.sh
⁃ 05_change_user_password

## Add New User
./01_add_new_user.sh
Enter the New Username:
Enter the New Password:
Re-Enter the Password:
Enter Root LDAP Password: <PASSWORD>
Re-Enter the Root LDAP Password: <PASSWORD>
sync users (yes/no): yes

## Remove User
./02_remove_user.sh
Enter the Username to delete:
Enter Root LDAP Password: <PASSWORD>
Re-Enter the Root LDAP Password: <PASSWORD>

## Unlock User
./03_unlock_user.sh
Enter the Username to unlock:
Enter Root LDAP Password: <PASSWORD>
Re-Enter the Root LDAP Password: <PASSWORD>

## Sync Users
./04_sync_users.sh

## Change User Password
./05_change_user_password
Enter the Username for password change: <USER>
Enter the New Password:
Re-Enter the Password:
Enter Root LDAP Password: <PASSWORD>
Re-Enter the Root LDAP Password: <PASSWORD>

Once users have been created, you must give them access permissions
(See Below):

RANGER CREATE USER ACCESS POLICIES
login to ranger as admin
Change New User Role to: admin
https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_security/
content/edit_permissions.html
Crate Policies for user
https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_security/
content/ranger_resource_based_policy_manager.html

AMBARI MANAGE USERS AND GROUPS
login to ambari as admin
Give New User Permissions
https://docs.hortonworks.com/HDPDocuments/Ambari-2.4.1.0/bk_ambariadministration/
content/managing_users_and_groups.html

NIFI CREATE USER ACCESS POLICIES
login to nifi as admin
Give New User Permissions
https://docs.hortonworks.com/HDPDocuments/HDF2/HDF-2.0.0/
bk_administration/content/config-users-access-policies.html
