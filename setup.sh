#!/bin/bash

echo "Installing expect..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  
sudo yum install expect -y

echo "Removing LDAP package..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  
sudo yum remove openldap-servers openldap-clients -y 

echo "Removing previous LDAP configurations..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' = 
sudo rm -rf /etc/*ldap*

echo "Installing LDAP..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' = 
sudo yum install openldap-servers openldap-clients -y 
sudo systemctl start slapd.service 
sudo systemctl enable slapd.service 

echo "Performing initial setup..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' = 

read -s -p "Enter your LDAP server password: " ldap_password
echo

read -p "Enter your LDAP DC Domain: " DC_DOMAIN
export DC_DOMAIN

read -p "Enter your LDAP DC TLD: " DC_TLD
export DC_TLD

read -p "Enter your LDAP CN Name: " CN_NAME
export CN_NAME
echo

export BIND_DN="cn=$CN_NAME,dc=$DC_DOMAIN,dc=$DC_TLD"

envsubst < ./templates/base_template.ldif > ./setup/base.ldif
envsubst < ./templates/domain_template.ldif > ./setup/domain.ldif
envsubst < ./templates/groups_template.ldif > ./setup/groups.ldif
envsubst < ./templates/users_template.ldif > ./setup/users.ldif

hashed_pw=$(slappasswd -s $ldap_password)

sed -i "s|^olcRootPW: .*|olcRootPW: $hashed_pw|" ./setup/db.ldif
sed -i "s|^olcRootPW: .*|olcRootPW: $hashed_pw|" ./setup/domain.ldif

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ./setup/db.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif  
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ./setup/domain.ldif


expect <<EOF
set timeout 10

spawn ldapadd -x -D "$BIND_DN" -W -f $HOME/automate-ldap/setup/base.ldif
expect "Enter LDAP Password: "
send "$ldap_password\r"
puts ""

spawn ldapadd -x -D "$BIND_DN" -W -f "$HOME/automate-ldap/setup/users.ldif"
expect "Enter LDAP Password:"
send "$ldap_password\r"
puts ""

spawn ldapadd -x -D "$BIND_DN" -W -f $HOME/automate-ldap/setup/users.ldif
expect "Enter LDAP Password: "
send "$ldap_password\r"
puts ""

spawn ldapdelete -x -D "$BIND_DN" -W -r "ou=groups,dc=$DC_DOMAIN,dc=$DC_TLD"
expect "Enter LDAP Password:"
send "$ldap_password\r"
puts ""

spawn ldapadd -x -D "$BIND_DN" -W -f $HOME/automate-ldap/setup/groups.ldif
expect "Enter LDAP Password: "
send "$ldap_password\r"
puts ""

spawn ldapsearch -x -D "$BIND_DN" -W -b "dc=$DC_DOMAIN,dc=$DC_TLD" 
expect "Enter LDAP Password: "
send "$ldap_password\r"
puts ""
expect eof
EOF

