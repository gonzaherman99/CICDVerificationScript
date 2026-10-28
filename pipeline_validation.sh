#!/bin/bash
set -u -o pipefail

banner() {
cat << "EOF"
   ____  ___   ____  ____       ____  _   _  _____   ____  _  __
  / ___||_ _| / ___||  _ \     / ___|| | | || ____| / ___|| |/ /
 | |     | | | |    | | | |   | |    | |_| ||  _|  | |    | ' /
 | |___  | | | |___ | |_| |   | |___ |  _  || |___ | |___ | . \
  \____||___| \____||____/     \____||_| |_||_____| \____||_|\_\
 
EOF
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


menu() {
cat << "EOF"
    1) Check NPM test
    2) Input Handling
    3) ......
    4) ........
    5) ........
    6) .........
    7) ........
    8) ........
EOF

read -rp "Enter your option " OPTION
read -rp "Enter the path for the repo " REPO_PATH

case $OPTION in
    1)  check_npm_test ;;
  
    *)  echo "Invalid option: $OPTION" >&2 ;;
esac

}

menu
