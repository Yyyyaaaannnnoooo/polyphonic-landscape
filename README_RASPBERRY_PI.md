Building SuperCollider on Raspberry Pi
======================================

> The original version of this manual can be found [here](https://github.com/supercollider/supercollider/blob/develop/README_RASPBERRY_PI.md)

SuperCollider can be built with the IDE and Qt GUI components on Raspbian Desktop, or without them on Raspbian
Desktop or Raspbian Lite. However, the project cannot be compiled with the QtWebEngine library, which means that the
help browser in the IDE, and the HelpBrowser and WebView classes in sclang, are unavailable.

Build requirements
------------------

* Raspberry Pi 2, 3 or 4 (Raspberry Pi 0 and 1 will also work, but note that compiling will take a _long_ time)
* SD card with [Raspbian Desktop](https://www.raspberrypi.org/downloads/raspbian) Stretch or Buster
* Router with Ethernet internet connection for the RPi
* For a GUI build: screen, mouse and keyboard
* Optional: USB soundcard with headphones or speakers connected

Building
--------

### Step 1: Hardware setup

> This step assumes you have already a working Rpi with Raspbian Desktop. If not follow the instructions [here](https://www.raspberrypi.com/software/) to install it

1. Connect an ethernet cable from the network router to the RPi

    * If Ethernet is not available connect over WiFi

2. Insert the SD card and USB soundcard. For a GUI build, connect screen, mouse and keyboard

3. Connect USB power from a power supply

   

### Step 2: Update the system, install required libraries

In a terminal, type (or copy-and-paste):

    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get dist-upgrade

Install required libraries:

```bash
# For GUI builds:
sudo apt-get install git
sudo apt-get install libjack-jackd2-dev
sudo apt-get install qjackctl
sudo apt-get install libsndfile1-dev
sudo apt-get install libasound2-dev
sudo apt-get install libavahi-client-dev
sudo apt-get install libreadline6-dev
sudo apt-get install libfftw3-dev
sudo apt-get install libxt-dev
sudo apt-get install libudev-dev
sudo apt-get install libcwiid-dev
sudo apt-get install cmake
sudo apt-get install qttools5-dev-tools
sudo apt-get install libqt5webkit5-dev
sudo apt-get install qtpositioning5-dev
sudo apt-get install libqt5sensors5-dev
sudo apt-get install qttools5-dev
sudo apt-get install libqt5svg5-dev
# it is also possible to execute the install in a single line 
# I put them separated so that is clear which libraries are needed
```

### Step 3: Compile and install SuperCollider

```bash
# we install supercollider in the HOME folder
cd ~
git clone --recurse-submodules https://github.com/supercollider/supercollider.git
cd supercollider
mkdir build && cd build

# For a GUI build:
cmake -DCMAKE_BUILD_TYPE=Release -DSUPERNOVA=OFF -DSC_ED=OFF -DSC_EL=OFF -DSC_VIM=ON -DNATIVE=ON -DSC_USE_QTWEBENGINE:BOOL=OFF ..
# use -j3 flag only on RPi3 or newer
cmake --build . --config Release --target all -- -j3 
sudo cmake --build . --config Release --target install
sudo ldconfig
```

### Step 4: Set up JACK

```bash
# `-dhw:0` is the internal soundcard.
# Use `-dhw:1` for USB soundcards. 
# `aplay -l` will list available devices.
# Use `nano ~/.jackdrc` to edit jack settings.

# For GUI builds:
echo /usr/bin/jackd -P75 -p16 -dalsa -dhw:0 -r44100 -p1024 -n3 > ~/.jackdrc
```

For GUI builds, another way to set up and start jack is to open a terminal and type `qjackctl`. Click 'setup' to
select soundcard and set periods to 3 (recommended). Then start jack before the SC IDE by clicking the play icon.

### Step 5: Download Polyphonic Landscape

```bash
# first change directory to HOME
cd ~
git clone https://github.com/Yyyyaaaannnnoooo/polyphonic-landscape.git
# start the SuperCollider Patch
bash polyphonic-landscape/scripts/autostart.sh
```



### Step 6: Nothing Will Work Out of the Box

The code above might work but not properly, as there is still the need to solve the issue on how SuperCollider can recognize the correct port to connect to ARDUINO. At the moment it connects to `/dev/ttyACM0`, but there is the need to find a proper way to get the arduino port and pass this to SuperCollider. SuperCollider can invoke terminal commands, and we could use [this](https://unix.stackexchange.com/questions/144029/command-to-determine-ports-of-a-device-like-dev-ttyusb0) to get the correct port.
For now it is possible to manually change the port directly in SuperCollider.

```bash
# assuming you followed all the steps as described and
# you have the polyphonic-landscape in your home directory
cd polyphonic-landscape/sc
# open the Supercollider editor
scide sample-player/polyphonic-landscapes.scd
```

```supercollider
// in line 2 shift+enter to list usb devices in the console
SerialPort.devices;
// usually there are 2 to 3 one will be the arduino
// the other probably keyboard and eventually audio interface

// in line 177 you can change the usb port name
~port = SerialPort.new("/dev/ttyACM0", baudrate: 9600);
```

Once this changes are made, and assuming there are no errors added to the code simply `ctrl-a`&`shift+enter` if returns an error check in the code the `// SELECT FROM HERE`and `// UNTIL HERE`comments and manually select everything in between and afterwards do a `shift+enter`. Hopefully it should work 😸

### Step 7: Changing / Adding Audio Files

The audio files are stored inside `polyphonic-landscape/sc/sample-player/audio/audiofiles`. All the files in the folder are automatically loaded in SuperCollider. Add and replace as many audio files you want, but never **MOVE** or **RENAME** the folder ⚠️

# %%~%%~%%~%%~%%~%%~%%~%%~%%~%%~%%

> below here comes from the original documentation, use it as reference but is not intended for this doc

Usage
-----

To use SuperCollider, just open a terminal and execute `scide` (GUI) or `sclang` (GUI-less).

When you boot the server jack should start automatically with the settings in `~/.jackdrc`.

**Done!** See below for other usage notes and tips.

Running a GUI build headless
----------------------------

If you want to ssh in and start SuperCollider headless, run:

    export DISPLAY=:0.0
    sclang

sc3-plugins
-----------

To compile and install sc3-plugins, follow the instructions in the [sc3-plugins README](https://github.com/supercollider/sc3-plugins).

Autostart
---------

To automatically run SuperCollider code at system boot:

    cat >~/autostart.sh <<EOF
    #!/bin/bash
    export PATH=/usr/local/bin:$PATH
    export DISPLAY=:0.0
    sleep 10 # can be lower (5) for rpi3
    sclang ~/mycode.scd
    EOF
    
    chmod +x ~/autostart.sh
    crontab -e # and add the following line to the end:
        @reboot cd /home/pi && ./autostart.sh
    
    nano ~/mycode.scd # And add your code inside a waitForBoot. For example:
        s.waitForBoot{ {SinOsc.ar([400, 404])}.play }
    
    sudo reboot # the sound should start after a few seconds

Login with ssh and run `killall jackd sclang scsynth` to stop the sound.

Benchmarks
----------

These are rough benchmark tests. The server should be booted and jackd running with settings: `-P75 -p1024 -n3 -r44100`

Also for comparison it is important to set CPU scaling to 'performance', by running:

    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

Start sclang or scide and run:

    s.boot
    {1000000.do{2.5.sqrt}}.bench // ~0.56 for rpi3 headless, ~0.7 for rpi3 scide, ~1.7 for rpi0 headless, ~3.8 for rpi0 scide
    a= {Mix(50.collect{RLPF.ar(SinOsc.ar)});DC.ar(0)}.play
    s.avgCPU // run a few times. ~12% for rpi3, ~18% for rpi2, ~79% for rpi1, ~50% for rpi0
    a.free

With the default cpu scaling (ondemand) these benchmarks perform much worse, but 'ondemand' also saves battery life so
depending on your application, this might be the preferred mode.

To set 'performance' scaling mode permanently see the "Gotcha..." section of [this StackExchange
post](https://raspberrypi.stackexchange.com/questions/9034/how-to-change-the-default-governor#9048).

Notes and Troubleshooting
-------------------------

This applies to both GUI and GUI-less builds above:

* An easy way to burn the zip file (no need to unpack) to an SD card is to use [etcher](http://etcher.io).
* The internal soundcard volume is by default set low (40). Type `alsamixer` in terminal and adjust the pcm volume to
  85 with the arrow keys. Press escape to exit.
* The audio quality of rpi's built-in sound is terrible. Dithering helps a bit so add `-zs` to the jackd command if
  you are using the built-in sound.
* If building with `-j 3` stops or returns an error the compiler might just have run out of memory. Try to reboot and
  run the make command again without `-j 3` or decrease the gpu memory in raspi-config under advanced (set it to 16).
* If you get `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` when trying to ssh in, type `ssh-keygen -R
  raspberrypi` to reset.
* For lower latency, set a lower blocksize for jackd. Try, for example `-p512` or `-p128`. Tune downwards until you
  get dropouts and xruns (also watch cpu%).
* To avoid SD card corruption one should always shut down the system properly and not just pull out the power. When
  running headless you can either ssh in and type `sudo halt -p`, use a GPIO pin with a button and Python script, or
  set up an OSC command from within SC that turns off the RPi. See
  [here](https://github.com/blacksound/VTM/wiki/Raspberry-Pi-Instructions#shutdown-for-raspberry-pi).
* For the older Raspbian Jessie system use a [previous](https://github.com/supercollider/supercollider.github.io/blob/1f578b5fa71e1acae0ce40d14bc0ef116062093d/development/building-raspberrypi.md)
  version of these instructions.
* To quit sclang after starting via the commandline use `0.exit`.
