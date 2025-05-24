#!/bin/bash

# LDAP admin credentials
BIND_DN="cn=ldap,dc=test,dc=com"

ldapsearch -LLL -x -D "$BIND_DN" -W -b "ou=users,dc=test,dc=com" dn | \
grep "^dn: uid" | sed "s/^dn: //" | \
while read dn; do
  echo "Deleting $dn"
  ldapdelete -x -D "$BIND_DN" -W "$dn"
done

for LDIF_FILE in ~/ldap/users/*.ldif; do
    # Extract the DN from the LDIF file
    DN=$(grep -m 1 '^dn:' "$LDIF_FILE" | cut -d ' ' -f 2-)
    
    # Print which user we are deleting
    echo "Adding user: $DN from $LDIF_FILE"
    
    # Run ldapdelete command to delete the entry
    ldapadd -x -D "$BIND_DN" -W -f $LDIF_FILE
    
    if [ $? -eq 0 ]; then
        echo "Successfully Added $DN"
    else
        echo "Failed to add $DN"
    fi
done

ldapsearch -x -D "cn=ldap,dc=test,dc=com" -W -b "dc=test,dc=com"