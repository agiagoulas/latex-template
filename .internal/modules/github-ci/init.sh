#!/usr/bin/env bash
MODULE_NAME="GitHub CI"
MODULE_DESCRIPTION="Installs a simple github actions workflow for projects hosted on github.
This workflow will automatically compile the latex project and provide the pdf as an artifact."

function install() {
    mkdir -p ".github/workflows/" && cp "$2/compile.yml" ".github/workflows/"
    return 0
}
