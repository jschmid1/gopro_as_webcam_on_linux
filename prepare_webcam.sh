#!/bin/bash


###################################################################
#Author       	:Joshua Schmid
#Email         	:jxs@posteo.de
###################################################################

# If run with -vv
# set -x



cat << EOF
Leaving this here to maintain backwards compatibility to any users who may just do a backwards search in their history to re-run this script.

Just FYI, there is a new version of the script with more functionality, including:

* Provide a device pattern for which look for
* Provide a device directly
* Provide an IP
* Auto-start and Preview mode.
* and more..

All of these features will hopefully simplify using a GoPro as a camera in the day-to-day life by allowing it to run automated in a start-up script.

If you wish to use the new version just check the Github repository. The README should be updated.
EOF




deps=( "ffmpeg" )
module="v4l2loopback"
module_cmd="modprobe v4l2loopback exclusive_caps=1 card_label='GoproLinux' video_nr=42"
module_cmd_unload="modprobe -rf v4l2loopback"

start_path="/gp/gpWebcam/START"
stop_path="/gp/gpWebcam/STOP"

if [ "$EUID" -ne 0 ]
    # the script needs root/sudo
    then echo "Please run as root or with sudo"
    exit 1
fi

function test_deps {
    # bail out if dependencies are not installed.
    for p in ${deps[@]}; do
        if ! command -v ${p} &> /dev/null
        then
            echo "${p} could not be found"
            echo "Please use you system's packagemanager to install this dependency and re-run this script"
            exit 1
        fi
    done
}


function user_confirmation {

    read -p "Please plug in your GoPro and switch it on. If it booted successfully (Charger icon on screen), hit Return"
}


function test_module_probe {
    # load module
    if ${module_cmd} &> /dev/null ; then
        echo ${module} was successfully loaded.
        return 0
    else
        echo ${module} does not exist. Please either install ${module} or get it from source via https://github.com/umlaeute/v4l2loopback
        exit 1
    fi
}

function test_module_unload {
    # unload module
    if ${module_cmd_unload} &> /dev/null ; then
        echo ${module} was unloaded successfully.
        return 0
    else
        echo ${module} could not be unloaded.
        exit 1
    fi

}

function test_module_loaded { 
    # test if module is already loaded
    if lsmod | grep ${module} &> /dev/null ; then
        echo ${module} is loaded!
        test_module_unload
        return 0
    else
        echo ${module} is not loaded!
        return 1
    fi
}



function find_gopro_interface {

    printf "\n\n"
    echo "I can only make an uneducated guess wrt the name of the interface that the GoPro exposes."
    echo "For me the name of the interface is 'enxf64854ee7472'. This script will try to discover the device"
    echo "that was added *last*, as you just plugged in the camera, hence the interface added last should be the one we're looking for."

    dev=$(ip -4 token | tail -1 | sed -e s"/token :: dev//" |  sed -e 's/^[[:space:]]*//')

    if [ -z ${dev} ]; then
        echo "Could not discover a interface. Please restart the script by providing the device that the GoPro exposes (use 'ip addr' for that)"
        exit 1
    fi
    echo -e "\nDiscovered: ${dev}."

    echo "Using this to discover the IP."
    ip=$(ip -4 addr show dev ${dev} | grep -Po '(?<=inet )[\d.]+')
    echo "Found ${ip}"

    if [ -z ${ip} ]; then
        echo "Could not discover a valid IP. # TODO a meaningful error message of what to do or how to proceed"
        exit 1
    fi

    echo "To control the GoPro, we need to contact another interface (IP ending with .51).. Adapting internally.."
    # For whatever reason the gopro server ends on .51
    mangled_ip=$(echo ${ip} | awk -F"." '{print $1"."$2"."$3".51"}')
    echo "Now using this IP internally: ${mangled_ip}"

    # Switching to the GoPro Webcam mode
    response=$(curl -s ${mangled_ip}${start_path})
    if [ $? -ne 0 ]; then
        echo "Error while starting the Webcam mode. # TODO Useful message."
        exit 1
    fi 
    echo $response
    if [ -z "${response}" ]; then
        echo "Did not receive a valid response from your GoPro. Please try again to run this script, timing is somethimes crucial."
        exit 1
    fi

    echo "Sucessfully started the GoPro Webcam mode. (The icon on the Camera should have changed)"
}


function end_msg {

    echo -e "\n\nYou should be ready to use your GoPro on your prefered videostreaming tool. Have Fun!"

    echo -e "To test this try this command(vlc needs to be installed): \n"
    echo "vlc -vvv --network-caching=300 --sout-x264-preset=ultrafast --sout-x264-tune=zerolatency --sout-x264-vbv-bufsize 0 --sout-transcode-threads 4 --no-audio udp://@:8554"

    echo -e "\n\nIf you want to use the GoPro in your prefered Video conferencing software (browser and apps works alike) pipe the UDP stream to a video device (that was created already) with this command: \n"
    echo "ffmpeg -nostdin -threads 1 -i 'udp://@0.0.0.0:8554?overrun_nonfatal=1&fifo_size=50000000' -f:v mpegts -fflags nobuffer -vf format=yuv420p -f v4l2 /dev/video42"
    
    exit 0

}

# If module is loaded already, unload it, to maintain idempotency.
test_module_loaded

# modprobe the needed kernel module
test_module_probe

# prompt to plug in the cable and turn on the device
user_confirmation

# Try to detect the correct interface and start the webcam mode
find_gopro_interface

# lastly, print the optional next steps to the user
end_msg