#!/bin/bash


if [[ -t 1 ]]; then
    RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; ENDING=$'\e[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; ENDING=''
fi

REPO_PATH="$(pwd)"

declare -A TESTS

check_for_errors() {
    
     local output
    output=$("$@" 2>&1) 
    status=$?


    if [[ "$status" -ne 0 ]]; then
        echo "$output"
    else 
       printf '%s\n' "$output"
    fi

    return "$status"
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
    TOOLS=("git" "node" "npm" "docker")

    for i in ${!TOOLS[@]}; do
        which ${TOOLS[$i]} > /dev/null 2>&1
        if [[ $? -eq "0" ]]; then   
           # echo "${GREEN}${TOOLS[$i]} does exist ${ENDING}"
            TESTS["Tools exist?"]=0
        else
            #echo "${RED} ${TOOLS[$i]} does exist in the system ${ENDING}"
            TESTS["Tools exist?"]=1
        fi
    done

    return 0 
}

check_working_tree() {
    cd $REPO_PATH

    GIT_STATUS=$(check_for_errors git status --porcelain)

    if [[ -z "$GIT_STATUS" ]]; then 
        #3echo "${GREEN}Working directory clean ${ENDING}"
        TESTS["Working directory clean?"]=0
    else 
        #echo "${RED}Working directory not clean ${ENDING}"
        TESTS["Working directory clean?"]=1
    fi

    return 0 
}

check_current_branch() {
    cd $REPO_PATH

    if [[ "$(check_for_errors git branch)" == "master" || "release" || "main" ]]; then 
        #echo "${GREEN}You are in the main branch ${ENDING}"
        TESTS["Are you in the main branch?"]=0
    else 
        #echo "${RED}You are not in the main branch ${ENDING}"
        TESTS["Are you in the main branch?"]=1
    fi

    return 0 
}

check_npm_ci() {
    if [[ -e "$REPO_PATH/package-lock.json" || -e "$REPO_PATH/npm-shrinkwrap.json" ]]; then

        cd "$REPO_PATH"
        OUTCOME=$(check_for_errors npm ci | tail -1 | cut -d " " -f 2 )

        if [[ "$OUTCOME" -eq "0" ]]; then
            #echo "${GREEN}Zero vulnerabilities found ${ENDING}"
            TESTS["Zero vulnerabilites found (CI)?"]=0
        else    
            #echo "${RED} ${OUTCOME} vulnerabilities found ${ENDING}"
            TESTS["Zero vulnerabilites found?"]=1
        fi

    fi

    return 0 
}

check_npm_audit() {
        if [[ -e "$REPO_PATH/package-lock.json" || -e "$REPO_PATH/npm-shrinkwrap.json" ]]; then

            cd "$REPO_PATH"
            OUTCOME=$(check_for_errors npm audit | tail -1 | cut -d " " -f 2 )

            if [[ "$OUTCOME" -eq "0" ]]; then
              #  echo "${GREEN} Zero vulnerabilities found ${ENDING}"
                TESTS["Zero vulnerabilites found (Audit)?"]=0
            else    
               # echo "${RED} ${OUTCOME} vulnerabilities found ${ENDING}"
                TESTS["Zero vulnerabilites found (Audit)?"]=1
            fi

        fi
}

check_versions() {
    ACTIVE_NODE=$(node -v | sed 's/v//')
    NVMRC_NODE=$(cat .nvmrc | sed 's/v//')
    PACKAGE_NODE=$(grep -i "node" package-lock.json | cut -d: -f2 | sed 's/[,!"]/ /g' | sed 's/ //g')

    if [[ "$ACTIVE_NODE" = "$NVMRC_NODE" && "$ACTIVE_NODE" = "$PACKAGE_NODE" ]]; then
       # echo "${GREEN} All versions match ${ENDING}"
        TESTS["All versions match?"]=0
    else
       # echo "${RED} Versions do not match ${ENDING}"
        TESTS["All versions match?"]=1
    fi

    return 0 
}

check_npm_test() {
    cd $REPO_PATH

    check_for_errors npm test
    #r#eturn_code=$?
    #if [ "$return_code" -ne 0 ]; then
    #    # echo "${RED} Tests failed. Fix issues before deployment. ${ENDING}"
    #    TESTS["Does NPM test works?"]=1
    #else 
       # echo "${GREEN} All tests passed ${ENDING}"
    #    TESTS["Does NPM test works?"]=0
    #fi

    return 0 
}

check_docker_build() {
    cd $REPO_PATH
    DOCKER_BUILD=$(docker build --check --quiet . 2>&1)
    return_code=$?
     if [ "$return_code" -ne 0 ]; then
       # echo "${RED} ${DOCKER_BUILD} ${ENDING}"
        TESTS["Does Docker build works?"]=0
    else 
       # echo "${GREEN} All tests passed ${ENDING}"
        TESTS["Does Docker build works?"]=1
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
    

    postivecounter=0
    nagativecounter=0
    for key in "${!TESTS[@]}"; do
        if [[ "${TESTS[$key]}" == "0" ]]; then
            echo "${GREEN}${key//,/} test passed ${ENDING}"
            postivecounter=$((postivecounter+1))
        else 
            echo "${RED}${key//,/} test failed ${ENDING}"
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
