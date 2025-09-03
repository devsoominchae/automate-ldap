#!/bin/bash

# Function to detect and use the correct package manager
install_package() {
    PACKAGE_NAME="$1"

    if command -v dnf >/dev/null 2>&1; then
        echo "Using dnf to install $PACKAGE_NAME"
        sudo dnf install -y "$PACKAGE_NAME"
    elif command -v yum >/dev/null 2>&1; then
        echo "Using yum to install $PACKAGE_NAME"
        sudo yum install -y "$PACKAGE_NAME"
    elif command -v apt >/dev/null 2>&1; then
        echo "Using apt to install $PACKAGE_NAME"
        sudo apt update
        sudo apt install -y "$PACKAGE_NAME"
    else
        echo "No supported package manager found (dnf, yum, apt)."
        exit 1
    fi
}

remove_package() {
    PACKAGE_NAME="$1"

    if command -v dnf >/dev/null 2>&1; then
        echo "Using dnf to remove $PACKAGE_NAME"
        sudo dnf remove -y "$PACKAGE_NAME"
    elif command -v yum >/dev/null 2>&1; then
        echo "Using yum to remove $PACKAGE_NAME"
        sudo yum remove -y "$PACKAGE_NAME"
    elif command -v apt >/dev/null 2>&1; then
        echo "Using apt to remove $PACKAGE_NAME"
        sudo apt remove -y "$PACKAGE_NAME"
    else
        echo "No supported package manager found (dnf, yum, apt)."
        exit 1
    fi
}

echo "Adding repo for OpenLDAP..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  
sudo curl -sSL https://repo.symas.com/configs/SOFL/rhel8/sofl.repo -o /etc/yum.repos.d/sofl.repo

echo "Installing expect..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  
install_package "expect"

echo "Removing LDAP package..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

remove_package "openldap-servers"
remove_package "openldap-clients"

echo "Removing previous LDAP configurations..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' = 
sudo rm -rf /etc/*ldap*

echo "Installing LDAP..."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' = 

install_package "openldap-servers"
install_package "openldap-clients"

sudo systemctl start slapd
sudo systemctl enable slapd

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
echo "BIND DN: $BIND_DN"

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

