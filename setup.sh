#!/usr/bin/env bash

# Initialise Git
echo -e "Initialising Git"
#rm -Rf .git
#git init


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
while read -r -u9 line; do
  (
    DESC=$(echo ${line} | awk -F\# '{sub(/^[ \t]+/, ""); print $2}')
    KEY=$(echo ${line} | awk -F: '{sub(/^[ \t]+/, ""); print $1}')
    echo "set ${KEY} (${DESC}):"
    read -p ">" VAL
    sed -i -e "s|  ${KEY}: SETUP_ENV.*|  ${KEY}: ${VAL} #${DESC}|" vars/main.yml
    # set ansible roles_path
    [[ ${KEY} == "project_name" ]] \
        && echo "appending local directory to roles_path" \
        && sed -i -e "s|roles_path = /etc/ansible/roles/CONCIERGE_PROJECT|roles_path = ${ANSIBLE_HOME}/roles/${VAL}|" ./ansible.cfg
   )
done 9< <(grep SETUP_ENV vars/main.yml)



# verify success


