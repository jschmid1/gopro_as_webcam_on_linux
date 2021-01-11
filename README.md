# Use your GoPro as a webcam on Linux (without additional hardware)
> Currently there is no official support for using your GoPro 8&9 (the only versions that offer this feature natively) as a webcam on Linux. The web is full of incomplete tutorials for this topic. This script tries to simplify this effort.

* Please not that this was only tested with the GoPro 8 on Ubuntu 20.04. 

## Dependencies

```sh
sudo apt install ffmpeg v4l2loopback-dkms
```

If your distribution doesn't provide `v4l2loopback-dkms` you may get it from https://github.com/umlaeute/v4l2loopback

## Usage

The script performs checks to ensure that the dependencies are installed and guides you through the process.

The next command invokes the `prepare_webcam.sh` script in this repository. Feel free to inspect it before executing it. Alternatively, clone this repo or download the file yourself.

For the sake of comfort, you can run this command.

```sh
sudo su -c "bash <(wget -qO- https://bit.ly/2MHC6LF)" root
```


## Todo:

* non-interactive mode to run this at system startup
* ENV var overwriting if IP or device detection doesn't work.
* stopping the webcam mode (feel broken on the GoPro side atm)
* allow resolution, narrow/wide viewmodes see -> https://github.com/KonradIT/goprowifihack/blob/f455675f4f8334d0fd5e6da976d857aa434a9fb0/HERO9/GoPro-Connect.md

## Release History

* 0.0.1
    * Work in progress

## Credits

Credits go to https://github.com/KonradIT for a comprehensive documentation and tooling around inofficial GoPro things.

## Contributing

1. Fork it (<https://github.com/jschmid1/gopro_as_webcam_on_linux/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

