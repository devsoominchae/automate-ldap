#!/bin/bash

# LDAP admin credentials
BIND_DN="cn=ldap,dc=test,dc=com"

count=0

ldapsearch -LLL -x -D "$BIND_DN" -W -b "ou=groups,dc=test,dc=com" dn | \
grep "^dn:" | sed "s/^dn: //" | \
while read dn; do
  count=$((count + 1))
  if [ "$count" -eq 2 ]; then
    echo "Deleting $dn (second match)"
    ldapdelete -x -D "$BIND_DN" -W "$dn"
    break
  fi
done

if [ "$count" -lt 2 ]; then
  echo "Only one match found. Nothing deleted."
fi

for LDIF_FILE in ~/ldap/groups/*.ldif; do
    # Extract the DN from the LDIF file
    DN=$(grep -m 1 '^dn:' "$LDIF_FILE" | cut -d ' ' -f 2-)
    
    # Print which user we are deleting
    echo "Adding group: $DN from $LDIF_FILE"
    
    # Run ldapdelete command to delete the entry
    ldapadd -x -D "$BIND_DN" -W -f $LDIF_FILE
    
    if [ $? -eq 0 ]; then
        echo "Successfully Added $DN"
    else
        echo "Failed to add $DN"
    fi
done

ldapsearch -x -D "cn=ldap,dc=test,dc=com" -W -b "dc=test,dc=com"
