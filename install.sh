#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function red {
    printf "${RED}$@${NC}\n"
}

function green {
    printf "${GREEN}$@${NC}\n"
}

function yellow {
    printf "${YELLOW}$@${NC}\n"
}

curl -s https://raw.githubusercontent.com/jschmid1/gopro_as_webcam_on_linux/master/gopro -o /usr/local/sbin/gopro

chmod +x /usr/local/sbin/gopro

yellow "**********************"
printf "\n\n"
green "The GoPro install script succeeded"
green "Run with with: "
green "sudo gopro"
printf "\n\n"
yellow "**********************"
