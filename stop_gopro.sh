#!/bin/bash

###################################################################
# Clean shutdown for GoPro Webcam
###################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping the GoPro webcam...${NC}\n"

# Stop FFmpeg
if pkill -f "ffmpeg.*8554"; then
    echo -e "${GREEN}✓ FFmpeg stopped${NC}"
else
    # Check if we need sudo (FFmpeg might be owned by root)
    if pgrep -f "ffmpeg.*8554" > /dev/null 2>&1; then
        echo -e "${RED}✗ FFmpeg process found but couldn't stop it${NC}"
        echo -e "${YELLOW}  Try running this script with sudo:${NC}"
        echo -e "${YELLOW}  sudo $0${NC}"
    else
        echo -e "${YELLOW}! No FFmpeg process found${NC}"
    fi
fi

# Send the STOP command to the GoPro if possible
# Look for the GoPro interface (skip loopback)
DEV=$(ip -4 token | grep -v "dev lo$" | tail -1 | sed -e 's/token :: dev//' | sed -e 's/^[[:space:]]*//')

if [ ! -z "$DEV" ]; then
    IP=$(ip -4 addr show dev ${DEV} 2>/dev/null | grep -Po '(?<=inet )[\d.]+' | head -1)

    if [ ! -z "$IP" ]; then
        GOPRO_IP=$(echo ${IP} | awk -F"." '{print $1"."$2"."$3".51"}')
        echo -e "${YELLOW}Sending the STOP command to the GoPro...${NC}"
        curl -s ${GOPRO_IP}/gp/gpWebcam/STOP > /dev/null 2>&1
        echo -e "${GREEN}✓ STOP command sent${NC}"
    fi
fi

# Unload the module (optional, commented out by default)
# if [ "$EUID" -eq 0 ]; then
#     modprobe -rf v4l2loopback 2>/dev/null
#     echo -e "${GREEN}✓ v4l2loopback module unloaded${NC}"
# fi

echo -e "\n${GREEN}GoPro webcam stopped${NC}"
