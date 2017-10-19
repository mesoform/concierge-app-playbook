#!/usr/bin/env bash

# after cloning the repository, set any necessary basic variables
ANSIBLE_HOME=$(echo ${ANSIBLE_HOME})
if [ -z ${ANSIBLE_HOME} ]; then
  ANSIBLE_HOME=/etc/ansible
  echo -e "No \${ANSIBLE_HOME} found. Set \${ANSIBLE_HOME} ($ANSIBLE_HOME):"
  read -p ">" ANSIBLE_HOME
fi

# ask for project name
echo "what is the name of your application?"
read APP_NAME
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
  [ ${KEY} == "project_name" ] && PROJECT=${VAL}
  sed "s/  ${KEY}: SETUP_ENV.*/  ${KEY}: ${VAL} #${DESC}/" vars/main.yml
done

# pull common role submodules

# create any necessary directory structure

# set ansible roles_path
# sed -i

# verify success


