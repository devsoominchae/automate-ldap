#!/bin/bash

sudo yum install expect -y

echo "Enter your LDAP server password: "
read ldap_password

expect <<EOF
set timeout 10
set exp_ldap_password "$ldap_password"

spawn ldapadd -x -D "cn=ldap,dc=test,dc=com" -W -f $HOME/automate-ldap/setup/base.ldif
expect "Enter LDAP Password: "
send "\$exp_ldap_password\r"
expect eof
EOF

