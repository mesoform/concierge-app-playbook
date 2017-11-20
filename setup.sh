#!/usr/bin/env bash

PARAM=$1
CONFIG_FILE=./ansible.cfg
DEFAULTS_FILE=defaults/main.yml

if [ "${PARAM}" == "--initialise-git" ]; then
    GIT_INITIALISATION=TRUE
    # Initialise Git
    echo -e "Initialising Git\n"
    rm -Rf .git
    git init
    echo -e "\n\n"
    echo -e "Adding submodules"
    for dir in $(ls -d create-concierge-* ); do
        if [ "$(ls -A ${dir} )" ]; then
            echo "${dir} submodule already setup"
        else
            echo "Empty submodule directory exists. Resetting"
            rmdir ${dir}
        fi
    done
    echo -e "\n\n"
    echo "Syncing submodules"
    git submodule add https://github.com/mesoform/create-concierge-app.git
    git submodule add https://github.com/mesoform/create-concierge-image.git
    git submodule add https://github.com/mesoform/create-concierge-tests.git

    echo -e "\n\n"
    echo "set remote repository location"
    read -e -p "Enter project repository URL: " PROJECT_REPO
    echo "setting project repo"
    git remote add origin ${PROJECT_REPO}
    echo -e "\n\n"
    echo "set project repo:"
    git remote -v
fi


# after initialising git, set any necessary basic variables
echo -e "Let's set up some defaults\n\n"
echo -e "checking existence of \${ANSIBLE_HOME}"
if [ -z ${ANSIBLE_HOME} ]; then
    DEFAULT_ANSIBLE_HOME=/etc/ansible
    echo -e "No \${ANSIBLE_HOME} found."
    read -e -p "Enter \${ANSIBLE_HOME} (${DEFAULT_ANSIBLE_HOME}): " ANSIBLE_HOME
    ANSIBLE_HOME="${ANSIBLE_HOME:-${DEFAULT_ANSIBLE_HOME}}"
else
    echo -e "\${ANSIBLE_HOME} set to ${ANSIBLE_HOME}\n\n"
fi

while read -r -u9 line; do
    (
        DEFAULT_PROJECT_NAME=$(basename $(echo ${PWD}))
        DEFAULT_CONSUL_AS_AGENT=true
        DESC=$(echo ${line} | awk -F\# '{sub(/\#[ \t]+/, "#"); print $2}')
        KEY=$(echo ${line} | awk -F: '{sub(/^[ \t]+/, ""); print $1}')
        if [[ ${KEY} == "project_name" ]]; then
            read -e -p "Enter value for ${KEY} (${DESC} DEFAULT=${DEFAULT_PROJECT_NAME}): " VAL
            VAL="${VAL:-${DEFAULT_PROJECT_NAME}}"
            # set Ansible roles_path
            echo -e "appending local directory to roles_path\n\n"
            sed -i .swp -e "s|roles_path = CONCIERGE_PROJECT|roles_path = ${ANSIBLE_HOME}/roles/${VAL}|" ${CONFIG_FILE}
        elif [[ ${KEY} == "consul_as_agent" ]]; then
            read -e -p "Enter value for ${KEY} (${DESC} DEFAULT=${DEFAULT_CONSUL_AS_AGENT}): " VAL
            VAL="${VAL:-${DEFAULT_CONSUL_AS_AGENT}}"
            echo -e "\n\n"
        else
            read -p "Enter value for ${KEY} (${DESC}): " VAL
            while [[ -z ${VAL} ]]; do
                echo -e "value can't be empty"
                read -p "Enter value for ${KEY} (${DESC}): " VAL
                echo -e "\n\n"
            done
        fi
        echo "set ${KEY} = ${VAL}"
        sed -i .swp -e "s|.*${KEY}: SETUP_ENV.*|${KEY}: ${VAL} # ${DESC}|" ${DEFAULTS_FILE}
   )
done 9< <(grep SETUP_ENV ${DEFAULTS_FILE})

if [[ ! -e README-Concierge.md ]]; then
    echo -e "blanking README\n\n"
    mv README.md README-Concierge.md
    echo "# New Concierge Project Playbook" > README.md
fi

# remove tmp files
echo -e "tidying up...\n\n"
[[ -e ${CONFIG_FILE}.swp ]] && rm ${CONFIG_FILE}.swp
[[ -e ${DEFAULTS_FILE}.swp ]] && rm ${DEFAULTS_FILE}.swp

# if this we're initialising git, do an initial commit
if [[ -n ${GIT_INITIALISATION} ]]; then
    DO_COMMIT=y
    read -e -p "Do an initial commit (Y/n): " COMMIT
    COMMIT="${COMMIT:-${DO_COMMIT}}"
    COMMIT=$(echo ${COMMIT}| tr '[:upper:]' '[:lower:]')
    while [ ${COMMIT} != y ] && [ ${COMMIT} != n ]; do
        echo "Enter y or n"
        read -e -p "Do an initial commit (Y/n): " COMMIT
        COMMIT="${COMMIT:-${DO_COMMIT}}"
        COMMIT=$(echo ${COMMIT} | tr '[:upper:]' '[:lower:]')
        echo -e "\n\n"
    done
    if [[ ${COMMIT} == y ]]; then
       echo "adding files"
       git add .
       echo "committing"
       git commit -am "Initial Commit"
       echo -e "\n\n"
       echo "pushing"
       git push --set-upstream origin master
       [[ $? -eq 0 ]] && echo -e "Done!\n" || echo -e "Something went wrong! :(\n"
    elif [[ ${COMMIT} == n ]]; then
        exit 0
        echo -e "Done!\n"
    fi
else
    echo -e "Done!\n"
fi

# verify success

