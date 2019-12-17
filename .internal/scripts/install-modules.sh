#!/usr/bin/env bash
# Colors
RESET=$(tput sgr0)
BU=$(tput smul)
AQUA=$(tput setaf 14)
DARK_AQUA=$(tput setaf 6)
LIGHT_RED=$(tput setaf 9)
GREEN=$(tput setaf 82)
DARK_GREEN=$(tput setaf 2)
GRAY=$(tput setaf 247)
BOLD=$(tput bold)
GOLD=$(tput setaf 11)

#Module local variables
function setup_module_vars() {
    MODULE_NAME="error"
    MODULE_DESCRIPTION="none"
    MODULE_DEPENDENCIES=""
}

# This function will be overwritten by the module
function install() {
    local PROJECT_ROOT=$1
    local MODULE_ROOT=$2
}

# Utility methods
function cecho() {
    output_string=""
    for var in "$@"; do
        output_string+=${var}${RESET}
    done
    echo -en "$output_string"
}

function cecho_yes_no() {
    cecho "$@"
    answer=""
    read -r answer
    if [[ ${answer} =~ ^[Yy]$ || -z ${answer} ]]; then
        return 0
    fi
    return 1
}

function new_module_info() {
    TEXT_TO_PRINT="<<{{ $2 }}>>"
    local TOTAL_PRINTING_CHARACTERS=$(($(tput cols) * 2 / 5))
    local TOTAL_SEPARATORS=$((TOTAL_PRINTING_CHARACTERS - ${#TEXT_TO_PRINT}))
    local SEPARATOR_AMOUNT=$((TOTAL_SEPARATORS / 2))

    printf "%s" "${BOLD}"
    for ((i = 0; i < SEPARATOR_AMOUNT; ++i)); do
        printf "─"
    done
    cecho "$1$TEXT_TO_PRINT"
    printf "%s" "${BOLD}"
    for ((i = 0; i < SEPARATOR_AMOUNT; ++i)); do
        printf "─"
    done
    if [[ ! $((TOTAL_SEPARATORS % 2)) -eq 0 ]]; then
        printf "─"
    fi
    echo -e "${RESET}"
}

function requireGitConfig() {
    if ! git config $1 &> /dev/null; then
        NEW_VALUE=""
        cecho "You do not have your git ${LIGHT_RED}$1" " configured. Please enter it right now: "
        read -r NEW_VALUE
        git config "$1" "${NEW_VALUE}"
    fi
}
function commitChanges() {
    git add .

    echo "\
    Install module $1

    This commit installs the $1 module onto the latex project." > _commit.txt
    git commit --file _commit.txt
    rm -f _commit.txt
}

function _installModule() {
    setup_module_vars
    source "$1/init.sh"
    IFS=',' read -r -a array <<< "${MODULE_DEPENDENCIES}"

    new_module_info "${GREEN}" "${MODULE_NAME}"
    cecho "${GREEN}Description: \n" "${MODULE_DESCRIPTION}"
    if [[ ! -z "${MODULE_DEPENDENCIES}" ]]; then
        cecho "${GREEN}Dependencies: ${MODULE_DEPENDENCIES}\n"
    fi

    if [[ ! $2 == "force" ]]; then
        if ! cecho_yes_no "Do you want to ${BOLD}install"  " ${GREEN}${MODULE_NAME} module" " ${DARK_GREEN}[y/n]" "? "; then
            return 0
        fi
    fi

    cecho "${GREEN}Installing...\n"

    install "$(pwd)" "$1" || return 1
    commitChanges "${MODULE_NAME}"

    cecho "${GREEN}Done!\n"
}

requireGitConfig "user.name"
requireGitConfig "user.email"

if ! $(git diff-index --quiet HEAD --); then
    cecho "${LIGHT_RED}You have non-committed changes in your project.\n"
    cecho "${LIGHT_RED}Modules cannot be installed until everything is committed.\n"
    exit 1
fi

# Move the current process to the latex template root this script is called in
cd "$( cd "$(dirname "$0")" ; pwd -P )/../.."

MODULE_ROOT=.internal/modules
for CURRENT_MODULE in "${MODULE_ROOT}"/*; do
    if [[ ! -d ${CURRENT_MODULE} ]]; then
        continue
    fi
    _installModule "${CURRENT_MODULE}"
done
