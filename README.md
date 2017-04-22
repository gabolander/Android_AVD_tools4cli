# Android_AVD_tools4cli
Tools for running Android AVD and installing GooglePlay in ANDROID AVD x86

## how to install
To download this project, just go to https://github.com/gabolander/Android_AVD_tools4cli and click on "*Clone or download*" -> *Download ZIP*

or just clone with command

`git clone https://github.com/gabolander/Android_AVD_tools4cli.git`

then

cd Android_AVD_tools4cli

and run the scripts **run_avd** or **install_googleplay_avd.sh** with

`./run_avd`

or

`./install_googleplay_avd.sh`

Very simple. :-)


### run_avd
**run_avd** script, can run with or without parameters.
If run *without parameters* it shows a list of your currently installed avds and let you choose which one to start.

If run with a parameter:
- if it's a number, it runs the Nth avd of the showed list.
- if it's a words, it will be used as pattern to list all the machines whose name matches this pattern. If it's only one, that AVD will be launched, otherwise a new list of matching pattern will be shown and it will let you choose which one to run.

### install_googleplay_avd.sh
####  (Still Work in progress ...)
**install_googleplay_avd.sh** script, can run with or without parameters. (Nowadays, only without params)

It uses console UI dialog or whiptail if you have one of them installed in your system.
This script will drive you to install Google Play in your running AVD Android emulator.

### NOTE
Please, _remember to change **SDK_HOME** variable_ into both script according to your system's Android SDK installation.

