#!/bin/bash

###################################################################
# GoPro Webcam - Low-latency optimized version
# Based on gopro-webcam by Joshua Schmid
# Tuned to reduce audio/video latency with OBS
###################################################################

set -e

# Configuration
MODULE="v4l2loopback"
VIDEO_DEVICE="/dev/video42"
UDP_PORT="8554"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== GoPro Webcam - Low-Latency Mode ===${NC}\n"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    exit 1
fi

# Check dependencies
for cmd in ffmpeg curl; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        exit 1
    fi
done

# Cleanup handler
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    pkill -f "ffmpeg.*$UDP_PORT" 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}Stopped cleanly${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Load the v4l2loopback module if needed
if ! lsmod | grep -q ${MODULE}; then
    echo -e "${YELLOW}Loading ${MODULE} module...${NC}"
    modprobe ${MODULE} exclusive_caps=1 card_label='GoproLinux' video_nr=42
    echo -e "${GREEN}✓ Module loaded${NC}"
else
    echo -e "${GREEN}✓ Module ${MODULE} already loaded${NC}"
fi

# Ensure the video device exists
if [ ! -e "$VIDEO_DEVICE" ]; then
    echo -e "${RED}Error: $VIDEO_DEVICE does not exist${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Video device $VIDEO_DEVICE ready${NC}\n"

# Discover the GoPro interface
echo -e "${YELLOW}Looking for the GoPro...${NC}"
echo "Make sure the GoPro is plugged in over USB and powered on."
read -p "Press Enter to continue..."

# Find the interface that was added last
DEV=$(ip -4 token | tail -1 | sed -e 's/token :: dev//' | sed -e 's/^[[:space:]]*//')

if [ -z "$DEV" ]; then
    echo -e "${RED}Error: Unable to find the GoPro interface${NC}"
    echo "Use 'ip addr' to locate the interface manually"
    exit 1
fi

echo -e "${GREEN}✓ Interface found: $DEV${NC}"

# Get the IP address
IP=$(ip -4 addr show dev ${DEV} | grep -Po '(?<=inet )[\d.]+' | head -1)

if [ -z "$IP" ]; then
    echo -e "${RED}Error: Unable to find the GoPro IP address${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Local IP: $IP${NC}"

# GoPro control IP (ends in .51)
GOPRO_IP=$(echo ${IP} | awk -F"." '{print $1"."$2"."$3".51"}')
echo -e "${GREEN}✓ GoPro control IP: $GOPRO_IP${NC}\n"

# Start webcam mode
echo -e "${YELLOW}Starting webcam mode on the GoPro...${NC}"
RESPONSE=$(curl -s ${GOPRO_IP}/gp/gpWebcam/START)

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo -e "${RED}Error: Unable to start webcam mode${NC}"
    echo "Make sure the GoPro is in USB mode and not charge-only mode"
    exit 1
fi

echo -e "${GREEN}✓ Webcam mode enabled on the GoPro${NC}\n"

# Wait for the stream to initialize
echo -e "${YELLOW}Waiting for the video stream (3 seconds)...${NC}"
sleep 3

# Start FFmpeg with low-latency settings
echo -e "${GREEN}Starting low-latency streaming...${NC}"
echo -e "${YELLOW}Settings:${NC}"
echo "  - No buffering"
echo "  - Minimal delay"
echo "  - Reduced probing"
echo "  - Single thread to minimize latency"
echo ""

ffmpeg -nostdin \
    -threads 1 \
    -fflags nobuffer+fastseek+flush_packets \
    -flags low_delay \
    -probesize 5000000 \
    -analyzeduration 1000000 \
    -i "udp://@0.0.0.0:${UDP_PORT}?overrun_nonfatal=1&fifo_size=50000000" \
    -map 0:v:0 \
    -vf format=yuv420p \
    -fps_mode passthrough \
    -max_delay 0 \
    -f v4l2 ${VIDEO_DEVICE}

# The script exits here when FFmpeg is interrupted
cleanup
