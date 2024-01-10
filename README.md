# Use your GoPro as a webcam on Linux (without additional hardware)
> Currently there is no official support for using your GoPro 8, 9, or 10 (the only versions that offer this feature natively) as a webcam on Linux. The web is full of incomplete tutorials for this topic. This script tries to simplify this effort.

## Installation

```sh
git clone https://github.com/jschmid1/gopro_as_webcam_on_linux
sudo ./install.sh
```

The `gopro` script is installed at `/usr/local/sbin/gopro`.

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

  -r,  --resolution        select the resolution you would like the GoPro to output. "1080", "720", or "480."
  
  -f,  --fov               select the FOV you would like to use. "wide", "linear", or "narrow."

  -i,  --ip                provide a IPv4 address to the GoPro i.e. (172.27.187.52)
                           CAUTION! This may change over time.
  
  -a,  --auto-start        automatically start ffmpeg to serve the GoPro as a video device to your operating system.
                           If this flag is omitted, print the corresponding command to run it yourself.

  -v,  --preview           Just launch a preview in VLC. This will not expose the device to the OS.

  -u,  --user              VLC can't be started as root, please provide a username you want to run it with. (Typically your 'default/home' user)

  -V,  --verbose           echo every command that gets executed

  -h,  --help              display this help
Commands:
  webcam                   start the GoPro in webcam mode

```

## Formats supported

After launched in webcam mode, the device only supports one format:

```
	[0]: 'YU12' (Planar YUV 4:2:0)
		Size: Discrete 1920x1080
			Interval: Discrete 0.033s (30.000 fps)
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
ExecStart=/usr/local/sbin/gopro webcam -a -n
Restart=on-failure
RestartSec=15s

[Install]
WantedBy=multi-user.target
```

Feel free to adapt it to your needs and copy it to `/etc/systemd/system/`

`sudo cp gopro_webcam.service /etc/systemd/system/`

`sudo systemctl start gopro_webcam.service`
`sudo systemctl status gopro_webcam.service`

Logs can be followed with `sudo journalctl -u gopro_webcam -f`

If all looks fine.

`sudo systemctl enable gopro_webcam.service`

## Start on plug in

You can also start the script when plugging in the usb cable or powering on the camera using udev rules. The script is also stopped without error when unplugging or powering off the camera. You can find an example file `60-gopro.rules` in the repo.

To set this up, first follow the service installation in *Start on boot* above. You can skip the last step `sudo systemctl enable gopro_webcam.service` if you don't want to script to start and fail on every startup.

Then copy the rule file `sudo cp 60-gopro.rules /lib/udev/rules.d/`. Now the setup is complete.

You can check the status using `systemctl` and `journalctl` as described above.

A known issue is that the first service start fails. The second service start then succeeds about 10s later. This is because even the service is only started after the ethernet interface, the network is not fully initialized. The service fails then because no ip is yet available. In the second try, the network is then usually initialized.

Also the udev rule currently only works for HERO8 BLACK. The rules in the file can be duplicated and adapted for every new model supporting webcam mode released by GoPro in the future.

## Dependencies

```sh
sudo apt install ffmpeg v4l2loopback-dkms curl vlc
```
Traffic on port `8554/udp` of the webcam network interface must be enabled
e.g. with `firewalld`:
```
sudo firewall-cmd --add-port 8554/udp
sudo firewall-cmd --add-port 8554/udp --permanent
```

If your distribution doesn't provide `v4l2loopback-dkms` you may get it from https://github.com/umlaeute/v4l2loopback

## Troubleshooting

### I can't find the network device for my GoPro
Double check that the USB connection mode is GoPro Connect and not MTP under Preferences -> Connections -> USB Connection. If that options doesn't exist, you likely need a firmware upgrade. Instructions can be found at https://gopro.com/en/us/update.

## Release History

* 0.0.1
    * Work in progress
* 0.0.2
    * Added args and arg parsing which
    * Allows to run at OS startup for easily

## Credits

Credits go to https://github.com/KonradIT for a comprehensive documentation and tooling around inofficial GoPro things.

## Buy the developer a cup of coffee!

If you found the utility helpful you can buy me a cup of coffee using

[![Donate](https://www.paypalobjects.com/webstatic/en_US/i/btn/png/silver-pill-paypal-44px.png)](https://www.paypal.com/donate?hosted_button_id=MKPX7GG6MMER8)


## Contributing

1. Fork it (<https://github.com/jschmid1/gopro_as_webcam_on_linux/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
