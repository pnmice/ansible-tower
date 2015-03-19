#!/bin/bash
# This script runs setup for Ansible Tower.
# It determines how Tower is to be installed, gives the proper command,
# and then executes the command if asked.


# -------------
# Initial Setup
# -------------

cd "$( dirname "${BASH_SOURCE[0]}" )"

# Cause exit codes to trickle through piping.
set -o pipefail

# When using an interactive shell, force colorized output from Ansible.
if [ -t "0" ]; then
    ANSIBLE_FORCE_COLOR=True
fi

# Set variables.
TIMESTAMP=$(date +"%F-%T")
LOG_DIR="/var/log/tower"
LOG_FILE="${LOG_DIR}/setup-${TIMESTAMP}.log"

# Set a sensible default for TOWER_CONF_FILE, for the case that a configuration
# file is not explicitly set.
TOWER_CONF_FILE="tower_setup_conf.yml"
INVENTORY_FILE="inventory"
OPTIONS=""


# --------------
# Usage
# --------------

function usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -c TOWER_CONF_FILE    Path to tower configure file (default: ${TOWER_CONF_FILE})
  -i INVENTORY_FILE     Path to ansible inventory file (default: ${INVENTORY_FILE})
  -e EXTRA_VARS         Set additional ansible variables as key=value or YAML/JSON
  -p                    Instruct ansible to prompt for a SSH password
  -s                    Instruct ansible to prompt for a sudo password
  -u                    Instruct ansible to prompt for a su password
  -h                    Show this help message and exit

EOF
    exit 1
}


# --------------
# Option Parsing
# --------------

while getopts 'c:e:i:psuh' OPTION; do
    case $OPTION in
        c)
            TOWER_CONF_FILE=$OPTARG
            ;;
        i)
            INVENTORY_FILE=$OPTARG
            ;;
        e)
            OPTIONS="$OPTIONS -e $OPTARG"
            ;;
        p)
            OPTIONS="$OPTIONS --ask-pass"
            ;;
        s)
            OPTIONS="$OPTIONS --ask-sudo-pass"
            ;;
        u)
            OPTIONS="$OPTIONS --ask-su-pass"
            ;;
        *)
            usage
            ;;
    esac
done

# Sanity check: Test to ensure that Ansible exists.
type -p ansible-playbook > /dev/null
if [ $? -ne 0 ]; then
    echo "Ansible is not installed on this machine."
    echo "You must install Ansible before you can install Tower."
    echo ""
    echo "For guidance on installing Ansible, consult "
    echo "http://docs.ansible.com/intro_installation.html."
    exit 32
fi

# Sanity check: Test to ensure that a setup configuration file exists.
if [ ! -f "${TOWER_CONF_FILE}" ]; then
    echo "ERROR: No configuration file could be found at ${TOWER_CONF_FILE}."
    echo "Run ./configure to create one, or specify one manually with -c."
    exit 64
fi

# Sanity check: Test to ensure that an inventory file exists.
if [ ! -f "${INVENTORY_FILE}" ]; then
    echo "ERROR: No inventory file could be found at ${INVENTORY_FILE}."
    echo "Run ./configure to create one, or specify one manually with -i."
    exit 64
fi

# Run the playbook.
PYTHONUNBUFFERED=x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR \
ANSIBLE_ERROR_ON_UNDEFINED_VARS=True \
ansible-playbook -i "${INVENTORY_FILE}" -v --sudo \
                 -e @"${TOWER_CONF_FILE}" \
                 $OPTIONS \
                 site.yml | tee setup.log

# Save the exit code and output accordingly.
RC=$?
if [ ${RC} -ne 0 ]; then
    echo "Oops!  An error occured while running setup."
else
    echo "The setup process completed successfully."
fi

# Save log file.
if [ -d "${LOG_DIR}" ]; then
    sudo cp setup.log "${LOG_FILE}"
    echo "Setup log saved to ${LOG_FILE}"
fi

exit ${RC}
