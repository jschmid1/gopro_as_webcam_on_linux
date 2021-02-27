# Use your GoPro as a webcam on Linux (without additional hardware)
> Currently there is no official support for using your GoPro 8&9 (the only versions that offer this feature natively) as a webcam on Linux. The web is full of incomplete tutorials for this topic. This script tries to simplify this effort.

* Please note that this was only tested with the GoPro 8 on Ubuntu 20.04. 
## Installation

```sh
sudo su -c "bash <(wget -qO- https://cutt.ly/PjNkrzq)" root
```

This runs an install script. Follow the instructions on the screen.

_The script install the `gopro` script to `/usr/local/sbin/gopro` and set an executable flag._

See **Usage** fom here on.


#### DEPRECATED

This was the first version of the script which I'll keep around for backwards-compatibility.
It will however not be maintained for too long.

```sh
sudo su -c "bash <(wget -qO- https://bit.ly/35wtnTl)" root
```

## Usage

``` sh
sudo gopro webcam
```

Starts the tool in the interactive mode and tries to identify the GoPro's device, find the interface and ultimately start the webcam mode.

There are a couple of parameters you can set if this isn't enough. See **Synopsis** or the `--help` text


## Synopsis

```
Usage:  action [options...]
Options:
  -n,  --non-interactive   do not wait for user input. Use this when used in a startup-script/fstab

  -p,  --device-pattern    provide a device pattern i.e. (enx, lsr) in case the script failed
                           to detect one by itself.

  -d,  --device            provide a full device name i.e. (enxenx9245589250e7)
                           USE WITH CAUTION. THIS CHANGES EVERY TIME YOU REBOOT/RECONNECT THE CAMERA
                           THIS OPTION IS NOT SUITABLE FOR AUTOMATION!

  -i,  --ip                provide a IPv4 address to the GoPro i.e. (172.27.187.52)
                           CAUTION! This may change as well over time.
  
  -a,  --auto-start        automatically start ffmpeg to serve the GoPro as a video device to your operating system.
                           If this flag is omitted, print the corresponding command to run it yourself. 

  -r,  --preview           Just launch a preview in VLC. This will not expose the device to the OS.
  -u,  --user              VLC can't be started as root, please provide a username you want to run it with. (Typically your 'default/home' user)

  -V,  --verbose           echo every command that gets executed
  -h,  --help              display this help
Commands:
  webcam                   start the GoPro in webcam mode

```

## Examples

`gopro webcam -p enx -n -a`

Find a device that matches the pattern 'enx' (which is the gopro device for me) and starts the webcam mode without asking for user input. It also starts `ffmpeg` and exposes the device to the OS.

`gopro webcam -d enxenx9245589250e7 -n -r`

Use the provided device 'enxenx9245589250e7' and do not ask for user input. Just start VLC to preview the output you'll get from the Camera.


`gopro webcam -i 172.27.187.52 -a -n`

Use the provided ip '172.27.187.52' and automatically start an ffmpeg to expose the device to the OS. Also don't ask for user input.


## Start on boot

It's rather annoying to start this script every time you start up your PC. This is why I provided an example `service` file in this repository.

**Note that the GoPro needs to be plugged in and be in 'standby' mode (Charger symbol) when the computer boots**


```
[Unit]
Description=GoPro Webcam start script
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
ExecStart=/usr/local/sbin/gopro webcam -p enx -a -n
Restart=on-failure
RestartSec=15s

[Install]
WantedBy=multi-user.target
```

Feel free to adapt it to your needs and copy it to `/etc/systemd/system/`

`sudo cp gopro_webcam.service /etc/systemd/system/`

`sudo systemctl start gopro_webcam.service`
`sudo systemctl status gopro_webcam.service`

If all looks fine.

`sudo systemctl enable gopro_webcam.service`

## Dependencies

```sh
sudo apt install ffmpeg v4l2loopback-dkms
```

If your distribution doesn't provide `v4l2loopback-dkms` you may get it from https://github.com/umlaeute/v4l2loopback


## Release History

* 0.0.1
    * Work in progress
* 0.0.2
    * Added args and arg parsing which
    * Allows to run at OS startup for easily

## Credits

Credits go to https://github.com/KonradIT for a comprehensive documentation and tooling around inofficial GoPro things.

## Contributing

1. Fork it (<https://github.com/jschmid1/gopro_as_webcam_on_linux/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
