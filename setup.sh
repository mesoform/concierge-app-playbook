#!/usr/bin/env bash

PARAM=$1

if [ "${PARAM}" == "--initialise-git" ]; then
    # Initialise Git
    echo -e "Initialising Git"
    rm -Rf .git
    git init
    echo "Adding submodules"
    for dir in $(ls -d create-concierge-* ); do
        if [ "$(ls -A ${dir} )" ]; then
            echo "${dir} submodule already setup"
        else
            echo "Empty submodule directory exists. Resetting"
            rmdir ${dir}
        fi
    done
    echo "Syncing submodules"
    git submodule add https://github.com/mesoform/create-concierge-app.git
    git submodule add https://github.com/mesoform/create-concierge-image.git
    git submodule add https://github.com/mesoform/create-concierge-tests.git
fi


# after initialising git, set any necessary basic variables
echo -e "checking existence of \${ANSIBLE_HOME}"
if [ -z ${ANSIBLE_HOME} ]; then
    DEFAULT_ANSIBLE_HOME=/etc/ansible
    echo -e "No \${ANSIBLE_HOME} found.\nSet \${ANSIBLE_HOME} (${DEFAULT_ANSIBLE_HOME}):"
    read -e -p ">" ANSIBLE_HOME
    ANSIBLE_HOME="${ANSIBLE_HOME:-${DEFAULT_ANSIBLE_HOME}}"
else
    echo -e "\${ANSIBLE_HOME} set to ${ANSIBLE_HOME}"
fi

while read -r -u9 line; do
    (
        DESC=$(echo ${line} | awk -F\# '{sub(/\#[ \t]+/, "#"); print $2}')
        KEY=$(echo ${line} | awk -F: '{sub(/^[ \t]+/, ""); print $1}')
        echo "set ${KEY} (${DESC}):"
        read -p ">" VAL
        while [[ -z ${VAL} ]]; do
            echo -e "value can't be empty"
            echo "set ${KEY} (${DESC}):"
            read -p ">" VAL
        done
        if [[ ${KEY} == "project_name" ]]; then
            # set ansible roles_path
            echo "appending local directory to roles_path"
            sed -i .swp -e "s|roles_path = CONCIERGE_PROJECT|roles_path = ${ANSIBLE_HOME}/roles/${VAL}|" ./ansible.cfg
        fi
        echo "set ${KEY} = ${VAL}"
        sed -i .swp -e "s|  ${KEY}: SETUP_ENV.*|  ${KEY}: ${VAL} #${DESC}|" vars/main.yml
   )
done 9< <(grep SETUP_ENV vars/main.yml)

if [[ ! -e README-Concierge.md ]]; then
    echo "blanking README"
    mv README.md README-Concierge.md
    touch README.md
fi

# remove tmp files
echo -e "tidying up..."
[[ -e ansible.cfg.swp ]] && rm ansible.cfg.swp
[[ -e vars/main.yml.swp ]] && rm vars/main.yml.swp

# verify success


