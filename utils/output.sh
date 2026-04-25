#!/bin/bash

#Colors

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

print_ok(){
    printf "${GREEN}[OK]${RESET} %s\n" "$1"
}
print_warn(){
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
    [ -n "$2" ] && printf "       ${YELLOW}->${RESET} %s\n" "$2"
}
print_fail(){
    printf "${RED}[FAIL]${RESET} %s\n" "$1"
    [ -n "$2" ] && printf "       ${RED}->${RESET} %s\n" "$2"
}
