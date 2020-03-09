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

function print_box_char() {
    last=$(($2 - 1))

    if [[ $2 == 1 ]]; then
        cecho "${BOLD}["
        return 0
    fi

    if [[ $1 == 0 ]]; then
        cecho "┏"
    elif [[ $1 == "${last}" ]]; then
        cecho "┗"
    else
        cecho "┃"
    fi
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

CECHO_NUMBER_OR_END_OUT=""
function cecho_number_or_end() {
    cecho "$@"
    answer=""
    read -r answer
    if [[ ${answer} =~ ^[0-9]+$ || "${answer}" != "exit" ]]; then
        CECHO_NUMBER_OR_END_OUT="${answer}"
        return 0
    fi
    return 1
}

function new_module_info() {
    TEXT_TO_PRINT="<<{{ $2 }}>>"
    local TOTAL_PRINTING_CHARACTERS=$(($(tput cols) * 2 / 5))
    local TOTAL_SEPARATORS=$((TOTAL_PRINTING_CHARACTERS - ${#TEXT_TO_PRINT}))
    local SEPARATOR_AMOUNT=$((TOTAL_SEPARATORS / 2))
    local SEPARATOR_AMOUNT_HALFED=$((SEPARATOR_AMOUNT / 2))

    printf "%s" "${BOLD}"
    for ((i = 0; i < SEPARATOR_AMOUNT; ++i)); do
        if [[ "$i" -ge "$SEPARATOR_AMOUNT_HALFED" ]]; then
            printf "─"
        else
            printf " "
        fi
    done
    cecho "$1$TEXT_TO_PRINT"
    printf "%s" "${BOLD}"
    for ((i = 0; i < SEPARATOR_AMOUNT; ++i)); do
        if [[ "$i" -le "$SEPARATOR_AMOUNT_HALFED" ]]; then
            printf "─"
        else
            printf " "
        fi
    done
    if [[ ! $((TOTAL_SEPARATORS % 2)) -eq 0 ]]; then
        printf     " "
    fi
    echo -e "${RESET}"
}

function requireGitConfig() {
    if ! git config "$1" &>/dev/null; then
        NEW_VALUE=""
        cecho "You do not have your git ${LIGHT_RED}$1" " configured. Please enter it right now: "
        read -r NEW_VALUE
        git config "$1" "${NEW_VALUE}"
    fi
}

function commitChanges() {
    git add .

    echo -en "Install module $1\n\nThis commit installs the $1 module onto the latex project.\n\n$2" >_commit.txt
    git commit --file _commit.txt
    rm -f _commit.txt
}

function _readModuleVars() {
    setup_module_vars

    # shellcheck source=/dev/null
    source "$1/init.sh"
    return 0
}

function _splitBy() {
    IFS=$'§' read -r -a output <<<"$2"
    echo "${output[$1]}"
}

function _installModule() {
    _readModuleVars "$1"

    MODULE_DESCRIPTION=$(fmt -w 72 < <(printf "%s\n" "$MODULE_DESCRIPTION"))
    IFS=$'\n' read -rd '' -a MODULE_DESCRIPTION_ARRAY <<< "${MODULE_DESCRIPTION}"

    new_module_info "${GREEN}" "${MODULE_NAME}"

    cecho "${GREEN}Description: \n"
    MODULE_DESCRIPTION_LENGTH=${#MODULE_DESCRIPTION_ARRAY[@]}
    for ((i = 0; i < MODULE_DESCRIPTION_LENGTH; ++i)); do
        print_box_char ${i} "${MODULE_DESCRIPTION_LENGTH}"
        cecho " ${MODULE_DESCRIPTION_ARRAY[$i]}\n"
    done

    if [[ -n "${MODULE_DEPENDENCIES}" ]]; then
        cecho "${GREEN}Dependencies: ${MODULE_DEPENDENCIES}\n"
    fi

    if [[ ! $2 == "force" ]]; then
        if ! cecho_yes_no "Do you want to ${BOLD}install" " ${GREEN}${MODULE_NAME} module" " ${DARK_GREEN}[y/n]" "? "; then
            return 0
        fi
    fi

    cecho "${GREEN}Installing...\n"

    install "$(pwd)" "$1" || return 1
    commitChanges "${MODULE_NAME}" "${MODULE_DESCRIPTION}"

    cecho "${GREEN}Done!\n"
}

requireGitConfig "user.name"
requireGitConfig "user.email"

if ! git diff-index --quiet HEAD --; then
    cecho "${LIGHT_RED}You have non-committed changes in your project.\n"
    cecho "${LIGHT_RED}Modules cannot be installed until everything is committed.\n"
    exit 1
fi

# Move the current process to the latex template root this script is called in
cd "$(
    cd "$(dirname "$0")"
    pwd -P
)/../.." || exit

MODULE_ROOT=.internal/modules

declare -a MODULES && i=0
for CURRENT_MODULE in "${MODULE_ROOT}"/*; do
    if [[ ! -d ${CURRENT_MODULE} ]]; then
        continue
    fi
    _readModuleVars "${CURRENT_MODULE}"
    MODULES[i]="${MODULE_NAME}§${CURRENT_MODULE}"
    ((i = i + 1))
done

COMPLETE_MODULE_LENGTH=${#MODULES[@]}

while true; do
    cecho "${GREEN}What" " ${DARK_GREEN}modules" " ${GREEN}do you want to install" "?\n"

    for ((i = 0; i < COMPLETE_MODULE_LENGTH; ++i)); do
        if [[ -z "${MODULES[i]}" ]]; then continue; fi

        start_char="┣"
        if [[ ${i} -eq "0" ]]; then start_char="┏";    fi
        if [[ ${i} -eq "$((${#MODULES[@]} - 1))" ]]; then start_char="┗";  fi
        if [[ ${#MODULES[@]} == 1 ]]; then start_char="━";   fi

        cecho " ${GRAY}${start_char}" "${DARK_GREEN}$(_splitBy 0 "${MODULES[i]}")" " (${i})\n"
    done

    # If 1 is returned, break. This means "end" was entered.
    if ! cecho_number_or_end "${GRAY}Enter the number of the module to install, or 'exit' to exit: "; then
        break
    fi

    # if empty string or not a number, restart this while loop and ask again
    if [[ -z "${CECHO_NUMBER_OR_END_OUT}" || ! "${CECHO_NUMBER_OR_END_OUT}" =~ ^[0-9]+$ ]]; then
        cecho "${LIGHT_RED}Please provide a valid module id!\n"
        continue
    fi

    TARGET_MODULE=${MODULES[CECHO_NUMBER_OR_END_OUT]}
    if [[ -z "${TARGET_MODULE}" ]]; then
        cecho "${LIGHT_RED}Please provide a valid module id!\n"
        continue
    fi

    _installModule "$(_splitBy 1 "${TARGET_MODULE}")"
    unset -v 'MODULES[CECHO_NUMBER_OR_END_OUT]'
    if [[ ${#MODULES[@]} == 0 ]]; then
        break
    fi
done
