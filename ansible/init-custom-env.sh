#!/bin/bash

# Creates service account for each operator-pipeline env; updates secret-vars.yml with token
#
# As arguments, it expects environments for which the sa should be created
#
# ./init.sh dev stage prod
#       creates the sa for dev, stage and prod environments
# ./init.sh
#       creates the sa for every environment (prod, stage, qa, dev)

set -euo pipefail
umask 077

NAMESPACE=$1
ENV=$2
SECRET=$(dirname "$0")/vaults/user-custom-env/ocp-token.yml
PASSWD_FILE=./vault-password

# Initialize the environment by creating the service account and giving for it admin permissions
initialize_environment() {
    if [ ! -f $SECRET ]; then
        touch $SECRET
        echo "File $SECRET was not found, empty one was created"
    fi

    ansible-playbook -i inventory/operator-pipeline playbooks/deploy.yml \
        --vault-password-file=$PASSWD_FILE \
        -e "namespace=$NAMESPACE" \
        -e "env=$ENV" \
        -e "custom_name=user-custom-env" \
        -e "ocp_host=`oc whoami --show-server`" \
        -e "ocp_token=`oc whoami -t`" \
        --tags init \
        -vvvv
}

# Get the token of created service account and make it available for further steps
update_token() {
    local token=$(oc --namespace $NAMESPACE serviceaccounts get-token operator-pipeline-admin)

    echo "ocp_token: $token" > $SECRET
    ansible-vault encrypt $SECRET --vault-password-file $PASSWD_FILE > /dev/null
    echo "Secret file $SECRET was updated and encrypted"
}

# Install all the other resources (pipelines, tasks, secrets etc..)
execute_playbook() {
  ansible-playbook -i inventory/operator-pipeline playbooks/deploy.yml \
    --vault-password-file vault-password \
    -e "namespace=$NAMESPACE" \
    -e "env=$ENV" \
    -e "custom_name=user-custom-env"
}

main() {
  initialize_environment
  update_token
  execute_playbook
}

main
