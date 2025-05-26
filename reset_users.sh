#!/bin/bash

read -s -p "Enter your LDAP server password: " ldap_password
echo

# Delete users OU
expect <<EOF
set timeout 10

spawn ldapdelete -x -D "$BIND_DN" -W -r "ou=users,dc=$DC_DOMAIN,dc=$DC_TLD"
expect "Enter LDAP Password:"
send "$ldap_password\r"
expect eof
EOF

# Add users base
expect <<EOF
set timeout 10

spawn ldapadd -x -D "$BIND_DN" -W -f "./setup/users.ldif"
expect "Enter LDAP Password:"
send "$ldap_password\r"
expect eof
EOF

# Add each group LDIF
for LDIF_FILE in ./users/*.ldif; do
    sed -i "s|^\(dn: uid=.*ou=users,\).*|\\1dc=$DC_DOMAIN,dc=$DC_TLD|" $LDIF_FILE
    DN=$(grep -m 1 '^dn:' "$LDIF_FILE" | cut -d ' ' -f 2-)

    echo "Adding: $DN"

    expect <<EOF
set timeout 10

spawn ldapadd -x -D "$BIND_DN" -W -f "$LDIF_FILE"
expect "Enter LDAP Password:"
send "$ldap_password\r"
expect eof
EOF

done

# Final search
expect <<EOF
set timeout 10

spawn ldapsearch -x -D "$BIND_DN" -W -b "dc=$DC_DOMAIN,dc=$DC_TLD"
expect "Enter LDAP Password:"
send "$ldap_password\r"
expect eof
EOF
