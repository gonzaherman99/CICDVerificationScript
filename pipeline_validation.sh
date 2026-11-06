#!/bin/bash


if [[ -t 1 ]]; then
    RED=$'\e[31m'; GREEN=$'\e[32m', YELLOW=$'\e[33m', BLUE=$'\e[34m', ENDING=$'\e[0m'
else
    RED=''; GREEN='', YELLOW='', BLUE='', ENDING=''
fi

SCRIPT_DIR=$(dirname $(pwd))

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
    TOOLS=("git" "node" "npm" "docker")

    for i in ${!TOOLS[@]}; do
        which ${TOOLS[$i]} > /dev/null 2>&1
        if [[ $? -eq "0" ]]; then   
            echo "${GREEN}${TOOLS[$i]} does exist ${ENDING}"
        else
            echo "${GREEN} ${TOOLS[$i]} does exist in the system ${ENDING}"
        fi
    done
}

check_working_tree() {
    cd $REPO_PATH

    if [[-z "$(git status --porcelain)" ]]; then 
        echo "Working dir clean"
    else 
        echo "Working dir not clean"
    fi
}

check_current_branch() {
    cd $REPO_PATH

    if [[ "$(git status --porcelain)" == "master" || "release" || "main" ]]; then 
        echo "You are in the main branch"
    else 
        echo "You are not in the main branch"
    fi
}

check_npm_ci() {
    if [[ -e "$REPO_PATH/package-lock.json" || -e "$REPO_PATH/npm-shrinkwrap.json" ]]; then

        cd "$REPO_PATH"
        OUTCOME=$(npm ci | tail -1 | cut -d " " -f 2 )

        if [[ "$OUTCOME" -eq "0" ]]; then
            echo "Zero vulnerabilities found"
        else    
            echo "{$OUTCOME} vulnerabilities found"
        fi

    fi
}

check_npm_audit() {
        if [[ -e "$REPO_PATH/package-lock.json" || -e "$REPO_PATH/npm-shrinkwrap.json" ]]; then

        cd "$REPO_PATH"
        OUTCOME=$(npm audit | tail -1 | cut -d " " -f 2 )

        if [[ "$OUTCOME" -eq "0" ]]; then
            echo "Zero vulnerabilities found"
        else    
            echo "${OUTCOME} vulnerabilities found"
        fi

    fi
}

check_versions() {
    ACTIVE_NODE=$(node -v | sed 's/v//')
    NVMRC_NODE=$(cat .nvmrc | sed 's/v//')
    PACKAGE_NODE=$(grep -i "node" package-lock.json | cut -d: -f2 | sed 's/[,!"]/ /g' | sed 's/ //g')

    if [[ "$ACTIVE_NODE" == "$NVMRC_NODE" && "$ACTIVE_NODE" == "$PACKAGE_NODE" ]]; then

    else

    fi
}

check_npm_test() {
    cd $REPO_PATH

    npm test
    return_code=$?
    if [ "$return_code" -ne 0 ]; then
        echo "Tests failed. Fix issues before deployment."
        exit 1
    fi
    echo "All tests passed."

}



#case $1 in 
#    help|-h|--help) cat "$SCRIPT_DIR/README" ;;
#    version|-v|--version) echo "Version 1.0.0" ;;
#    check) check_if_tools_exist;;
#    *) echo "Not know option: $1 (try: $0 for help)" >&2; exit 1 ;;
#esac

check_npm_ci