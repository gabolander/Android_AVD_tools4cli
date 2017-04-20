#!/bin/bash


# /opt/Android/Sdk/platform-tools $ ./adb shell "cat /system/build.prop" | grep ro.build.version.release
# ro.build.version.release=7.1.1
# /opt/Android/Sdk/platform-tools $ ./adb shell "cat /system/build.prop" | grep ro.build.version.sdk
# ro.build.version.sdk=25

# BASE (CUSTOM) VARIABLES - They may vary depending on system environment
LIBSTDC_PATH=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
SDK_HOME=/opt/Android/Sdk
EMULATOR_PATH=${SDK_HOME}/emulator/emulator
ADB_PATH=${SDK_HOME}/platform-tools/adb
WRITABLE="-writable-system"


$ADB_PATH devices
ret=$?
echo "Result: $ret"
exit $ret

