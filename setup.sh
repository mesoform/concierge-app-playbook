#!/usr/bin/env bash

# Initialise Git
echo -e "Initialising Git"
rm -Rf .git
git init


# after initialising git, set any necessary basic variables
echo -e "checking existence of \${ANSIBLE_HOME}"
if [ -z ${ANSIBLE_HOME} ]; then
  DEFAULT_ANSIBLE_HOME=/etc/ansible
  echo -e "No \${ANSIBLE_HOME} found.\nSet \${ANSIBLE_HOME} (${DEFAULT_ANSIBLE_HOME}):"
  read -p ">" ANSIBLE_HOME
else
  echo -e "\${ANSIBLE_HOME} set to ${ANSIBLE_HOME}"
fi

# ask for project name
# echo "what is the name of your application?"
# read APP_NAME
# set project name var, set roles_path in ansible.cfg and check/set basedir
#sed -i "s/  project_name: SETUP_ENV/  project_name: ${APP_NAME}/" vars/main.yml

# set basic vars
#for var in $(awk '/SETUP_ENV/' vars/main.yml); do
while read -r line; do
  var=$(echo ${line} | grep SETUP_ENV vars/main.yml)
  DESC=$(echo ${var} | awk -F\# '{sub(/^[ \t]+/, ""); print $2}')
  KEY=$(echo ${var} | awk -F: '{sub(/^[ \t]+/, ""); print $1}')
  echo "set ${KEY} (${DESC}):"
  read -p ">" VAL
  [ ${KEY} == "project_name" ] && CONCIERGE_PROJECT=${VAL}
  sed "s|  ${KEY}: SETUP_ENV.*|  ${KEY}: ${VAL} #${DESC}|" vars/main.yml
done


# set ansible roles_path
sed "s|roles_path = /etc/ansible/roles/CONCIERGE_PROJECT|roles_path = /etc/ansible/roles/${CONCIERGE_PROJECT}|" ansible.cfg

# verify success


