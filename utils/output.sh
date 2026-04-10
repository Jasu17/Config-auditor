#!/bin/bash

#Colors

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

print_ok(){
    echo -e "${GREEN}[OK]${RESET} $1"
}
print_warn(){
    echo e- "${YELLOW}[WARN]${RESET} $1"
}
print_fail(){
    echo -e "${RED}[FAIL]${RESET} $1"
}
