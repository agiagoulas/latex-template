#!/usr/bin/env bash
RESET=$(tput sgr0)
BU=$(tput smul)
AQUA=$(tput setaf 14)
DARK_AQUA=$(tput setaf 6)
LIGHT_RED=$(tput setaf 9)
GREEN=$(tput setaf 82)
DARK_GREEN=$(tput setaf 2)
BOLD=$(tput bold)

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
  read answer
  if [[ ${answer} =~ ^[Yy]$ ]]; then
    return 0
  fi
  return 1
}
function new_topic() {
    TOTAL_PRINTING_CHARACTERS=$(($(tput cols) * 2 / 5 ))
    TOTAL_SEPARATORS=$((TOTAL_PRINTING_CHARACTERS - ${#2}))
    SEPARATOR_AMOUNT=$((TOTAL_SEPARATORS / 2))

    printf ${BOLD}
    for (( i = 0; i < ${SEPARATOR_AMOUNT}; ++i )); do
        printf "-"
    done
    cecho "$1$2"
    printf ${BOLD}
    for (( i = 0; i < ${SEPARATOR_AMOUNT}; ++i )); do
        printf "-"
    done
    if [[ ! $((TOTAL_SEPARATORS%2)) -eq 0 ]]; then
        printf "-"
    fi
    echo -e "${RESET}"
}

new_topic "${AQUA}" "[DHBW LaTeX Template Generator]"
# Checking for the required tools on the machine, mostly git
if ! hash git 2>/dev/null; then
  cecho "Could not find ${LIGHT_RED}git" " on your machine\n"
  exit 1
fi

REMOTE_GIT_REPOSITORY=$1
if [[ -z ${REMOTE_GIT_REPOSITORY} ]]; then
  cecho "Please provide the projects remote ${AQUA}${BU}git repository url" ": "
  read -r REMOTE_GIT_REPOSITORY
fi
cecho "The project will be hosted at: " "${AQUA}${BU}${REMOTE_GIT_REPOSITORY}\n"

new_topic "${GREEN}" "[Project Name]"
PROJECT_NAME=$(echo "$REMOTE_GIT_REPOSITORY" | rev | cut -d '/' -f 1 | cut -c 5- | rev)
while ! (cecho_yes_no "Do you want to use ${GREEN}${BU}${PROJECT_NAME}" " as your project name" " ${DARK_GREEN}[y/n]" "?"); do
  cecho "Please provide the ${GREEN}${BU}project name" ": ${DARK_AQUA}"
  read -r PROJECT_NAME
done

echo "Cloning dhbw latex template" "to ${GREEN}${BU}${PROJECT_NAME}"

