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

# Check for root privileges
if [ $EUID -ne 0 ]; then
    red 'Installer must be run as root!'
    red "Try running: sudo $0"
    exit 1
fi

green "Installing the gopro tool"
install -D ./gopro /usr/local/sbin/gopro

if [ "$1" == "--auto" ]; then
    green "Installing systemd service"
    install -o root -g root -m 0644 ./gopro-webcam.service /etc/systemd/system
    systemctl daemon-reload
    green "Installing udev rules"
    install -o root -g root -m 0644 ./60-gopro.rules /etc/udev/rules.d
    udevadm control --reload
fi

yellow "**********************"
printf "\n\n"
green "The GoPro install script succeeded"
green "Run with with: "
green "sudo gopro"
printf "\n\n"
yellow "**********************"

gopro
