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

install -D ./gopro /usr/local/sbin/gopro
install -D ./gopro-tray /usr/local/bin/gopro-tray
install -D -m 644 ./gopro-webcam.desktop /usr/share/applications/gopro-webcam.desktop

yellow "**********************"
printf "\n\n"
green "The GoPro install script succeeded"
green "Run with with: "
green "sudo gopro"
printf "\n"
green "For the system tray GUI, install optional dependencies:"
green "  sudo apt install gir1.2-ayatanaappindicator3-0.1 zenity"
green "Then run: gopro-tray"
printf "\n\n"
yellow "**********************"

gopro
