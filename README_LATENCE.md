# GoPro + OBS low-latency notes

This document records a practical low-latency setup for using a GoPro as a webcam on Linux with OBS Studio and an external microphone.

## Tested setup

- Fedora 42
- GoPro HERO9
- OBS Studio
- Rode NT USB+
- USB connection to the GoPro

In this setup, an audio sync offset of **133 ms** on the Rode NT USB+ produced good A/V sync in OBS.

## What helped

- Running the GoPro over USB rather than Wi-Fi.
- Keeping the video pipeline simple and low-buffer.
- Adjusting the microphone sync in OBS instead of trying to force perfect sync in the capture chain.

## OBS adjustment

In OBS:

1. Open **Edit** -> **Advanced Audio Properties**
2. Find the Rode NT USB+ source
3. Set **Sync Offset** to **133 ms**
4. Fine-tune in small steps if needed

## Notes on latency

The exact value is hardware- and setup-dependent.

Cable quality, USB port choice, camera firmware, OBS settings, and host load can all affect the final offset.

## Video examples

### Running the GoPro with the default settings produces a noticeable delay:
```sh
sudo gopro webcam -a -n
```

[Example video: Default settings with noticeable delay](examples/1.mp4)

### Running the GoPro with a low-latency FFmpeg tuning pass and adjusting the OBS sync gives much better results:

```sh
sudo ./start_gopro_lowlatency.sh
```

[Example video: Low-latency setup with better sync](examples/2.mp4)

### The second setup is much more responsive and the audio is in sync, making it suitable for live streaming or video conferencing.

```sh
sudo ./start_gopro_lowlatency.sh
```

[Example video: Optimized setup for live streaming](examples/3.mp4)