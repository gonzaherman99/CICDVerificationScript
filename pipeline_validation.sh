#!/bin/bash


if [[ -t 1 ]]; then
    RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; ENDING=$'\e[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; ENDING=''
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PATH="${2:-$(pwd)}"

declare -A TESTS
declare -A OUTPUTS

LAST_OUTPUT=""

check_for_errors() {
    LAST_OUTPUT=$("$@" 2>&1) 
}


banner() {
cat << "EOF"
   ____  ___   ____  ____       ____  _   _  _____   ____  _  __
  / ___||_ _| / ___||  _ \     / ___|| | | || ____| / ___|| |/ /
 | |     | | | |    | | | |   | |    | |_| ||  _|  | |    | ' /
 | |___  | | | |___ | |_| |   | |___ |  _  || |___ | |___ | . \
  \____||___| \____||____/     \____||_| |_||_____| \____||_|\_\
 
EOF
}



check_if_tools_exist() {
    COUNTER=0
    ERRORS=()

    for i in "git" "node" "npm" "docker"; do
        which $i > /dev/null 2>&1
        return_code="$?"
        if [[ "$return_code" -eq "0" ]]; then   
            COUNTER=$((COUNTER+1))
        else
            COUNTER=$((COUNTER+0))
            ERRORS+=("$i")
        fi
    done

    if [[ "$COUNTER" == 4 ]]; then
        TESTS["Tools exist?"]=0
        OUTPUTS["Tools exist?"]="No errors to show"

    else
        TESTS["Tools exist?"]=1
        OUTPUTS["Tools exist?"]="Missing tools: ${ERRORS[*]}"
    fi

    return 0 
}

check_working_tree() {
    cd "$REPO_PATH" || return 1

    check_for_errors git status --porcelain

    if [[ -z "$LAST_OUTPUT" ]]; then 
        TESTS["Working directory clean?"]=0
        OUTPUTS["Working directory clean?"]="No errors to show"
    else 
        TESTS["Working directory clean?"]=1
        OUTPUTS["Working directory clean?"]=$LAST_OUTPUT
    fi

    return 0 
}

check_current_branch() {
    cd "$REPO_PATH" || return 1
    BRANCH=$(git branch --show-current 2>/dev/null)

    if [[ "$BRANCH" == "master" || "$BRANCH" == "release" || "$BRANCH" == "main" ]]; then 
        TESTS["Are you in the main branch?"]=0
        OUTPUTS["Are you in the main branch?"]="No errors to show"
    else 
        TESTS["Are you in the main branch?"]=1
        OUTPUTS["Are you in the main branch?"]="Current branch is ${BRANCH:-unknown}"
    fi

    return 0 
}

check_npm_ci() {
    if [[ -e "$REPO_PATH/package-lock.json" || -e "$REPO_PATH/npm-shrinkwrap.json" ]]; then

        cd "$REPO_PATH" || return 1

        check_for_errors npm ci

        if grep -q "found 0 vulnerabilities" <<< "$LAST_OUTPUT"; then
            TESTS["Zero vulnerabilites found (CI)?"]=0
            OUTPUTS["Zero vulnerabilites found (CI)?"]="No errors to show"
        else    
            TESTS["Zero vulnerabilites found (CI)?"]=1
            OUTPUTS["Zero vulnerabilites found (CI)?"]=$LAST_OUTPUT
        fi

    fi

    return 0 
}

check_npm_audit() {
        if [[ -e "$REPO_PATH/package-lock.json" || -e "$REPO_PATH/npm-shrinkwrap.json" ]]; then

            cd "$REPO_PATH" || return 1

            check_for_errors npm audit

            if grep -q "found 0 vulnerabilities" <<< "$LAST_OUTPUT"; then
                TESTS["Zero vulnerabilites found (Audit)?"]=0
                 OUTPUTS["Zero vulnerabilites found (Audit)?"]="No errors to show"
            else    
                TESTS["Zero vulnerabilites found (Audit)?"]=1
                OUTPUTS["Zero vulnerabilites found (Audit)?"]=$LAST_OUTPUT
            fi

        fi
}

check_versions() {
    cd "$REPO_PATH" || return 1
    ACTIVE_NODE=$( node -v | sed 's/v//' 2>/dev/null)
    NVMRC_NODE=$( cat .nvmrc | sed 's/v//' 2>/dev/null)
    PACKAGE_NODE=$(node -p "require('./package.json').engines?.node || ''" 2>/dev/null | sed 's/[^0-9.]//g')

    if [[ "$ACTIVE_NODE" = "$NVMRC_NODE" && "$ACTIVE_NODE" = "$PACKAGE_NODE" ]]; then
        TESTS["All versions match?"]=0
        OUTPUTS["All versions match?"]="No errors to show"
    else
        TESTS["All versions match?"]=1
       OUTPUTS["All versions match?"]="node: $ACTIVE_NODE, .nvmrc: ${NVMRC_NODE:-not found}, package: ${PACKAGE_NODE:-not found}"
    fi

    return 0 
}

check_npm_test() {
    cd "$REPO_PATH" || return 1
    if check_for_errors npm test
    then
        TESTS["Does npm test work?"]=0
        OUTPUTS["Does npm test work?"]="No errors to show"
    else
        TESTS["Does npm test work?"]=1
        OUTPUTS["Does npm test work?"]=$LAST_OUTPUT
    fi
}

check_docker_build() {
    cd "$REPO_PATH" || return 1
    check_for_errors docker build --check --quiet . 2>&1
    return_code=$?
     if [ "$return_code" -ne 0 ]; then
        TESTS["Does Docker build works?"]=1
        OUTPUTS["Does Docker build works?"]=$LAST_OUTPUT
    else 
        TESTS["Does Docker build works?"]=0
        OUTPUTS["Does Docker build works?"]="No errors to show"
    fi

    return 0 
}

all_functions() {
    banner
    check_if_tools_exist
    check_working_tree
    check_current_branch
    check_npm_audit
    check_npm_ci
    check_npm_test
    check_versions
    check_docker_build
    

    postivecounter=0
    nagativecounter=0
    for key in "${!TESTS[@]}"; do
        if [[ "${TESTS[$key]}" == "0" ]]; then
            echo "${GREEN}${key//,/} test passed ${ENDING}"
            echo "${GREEN}${OUTPUTS[$key]}${ENDING}"
            postivecounter=$((postivecounter+1))
        else 
            echo "${RED}${key//,/} test failed ${ENDING}"
            echo "${RED}${OUTPUTS[$key]}${ENDING}"
            nagativecounter=$((nagativecounter+1))
        fi
    done

    echo "${GREEN}${postivecounter} tests passed ${ENDING}"
    echo "${RED}${nagativecounter} tests failed ${ENDING}"
}

case $1 in 
    help|-h|--help) cat "$SCRIPT_DIR/README" ;;
    version|-v|--version) echo "Version 1.0.0" ;;
    all) all_functions;;
    *) echo "Not know option: $1 (try: $0 for help)" >&2; exit 1 ;;
esac
