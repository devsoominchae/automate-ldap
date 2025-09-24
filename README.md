# Automating LDAP configuration on a Linux machine
All three scripts must be ran to setup LDAP on the Linux machine.

## Setup LDAP
This runs the initial steps to setup LDAP
- Download LDAP
- Start LDAP server
- Add DN domain, TLD
- Add groups and users OU

The script must be run with "source" as it exports some environment variables.

######
    ./source setup.sh

## Reset Groups
This will delete all groups under the domain entry entered by the user when running setup.sh. Then it adds all groups defined under groups folder.
######
    ./reset_groups.sh

## Reset Users
This does the same to users at it did on groups.
######
    ./reset_users.sh
