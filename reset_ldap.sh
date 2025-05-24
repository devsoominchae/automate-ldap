echo "sudo yum remove openldap-servers openldap-clients -y" 
sudo yum remove openldap-servers openldap-clients -y 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "sudo yum install openldap-servers openldap-clients -y" 
sudo yum install openldap-servers openldap-clients -y 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "sudo systemctl start slapd.service" 
sudo systemctl start slapd.service 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "systemctl enable slapd.service" 
sudo systemctl enable slapd.service 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/db.ldif" 
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/db.ldif 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif  

echo "sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/domain.ldif" 
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/domain.ldif 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/base.ldif" 
ldapadd -x -D "cn=ldap,dc=test,dc=com" -W -f ~/automate-ldap/setup/base.ldif 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/users.ldif" 
ldapadd -x -D "cn=ldap,dc=test,dc=com" -W -f ~/automate-ldap/setup/users.ldif 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ~/automate-ldap/setup/groups.ldif" 
ldapadd -x -D "cn=ldap,dc=test,dc=com" -W -f ~/automate-ldap/setup/groups.ldif 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =  

echo "ldapsearch -x -D \"cn=ldap,dc=test,dc=com\" -W -b \"dc=test,dc=com\"" 
ldapsearch -x -D "cn=ldap,dc=test,dc=com" -W -b "dc=test,dc=com" 
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' = 