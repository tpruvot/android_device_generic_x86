#
# Copyright (C) 2013 The Android-x86 Open Source Project
#
# License: GNU Public License v2 or later
#

function set_property()
{
	# this must be run before post-fs stage
	echo $1=$2 >> /x86.prop
}

function init_misc()
{
	# a hack for USB modem
	lsusb | grep 1a8d:1000 && eject

	# in case no cpu governor driver autoloads
	[ -d /sys/devices/system/cpu/cpu0/cpufreq ] || modprobe acpi-cpufreq
}

function init_hal_audio()
{
	case "$PRODUCT" in
		VirtualBox*|Bochs*)
			[ -d /proc/asound/card0 ] || modprobe snd-sb16 isapnp=0 irq=5
			;;
		*)
			;;
	esac
	[ -d /proc/asound/card0 ] || modprobe snd-dummy

	for c in $(grep '\[.*\]' /proc/asound/cards | awk '{print $1}'); do
		alsa_ctl init $c
		alsa_amixer -c $c set Master on
		alsa_amixer -c $c set Master 100
		alsa_amixer -c $c set Headphone on
		alsa_amixer -c $c set Headphone 100
		alsa_amixer -c $c set Speaker 100
		alsa_amixer -c $c set Capture 100
		alsa_amixer -c $c set Capture cap
		alsa_amixer -c $c set PCM 100 unmute
		alsa_amixer -c $c set 'Mic Boost' 3
		alsa_amixer -c $c set 'Internal Mic Boost' 3
	done
}

function init_hal_bluetooth()
{
	for r in /sys/class/rfkill/*; do
		type=$(cat $r/type)
		[ "$type" = "wlan" -o "$type" = "bluetooth" ] && echo 1 > $r/state
	done

	# these modules are incompatible with bluedroid
	rmmod ath3k
	rmmod btusb
	rmmod bluetooth
}

function init_hal_camera()
{
	[ -c /dev/video0 ] || modprobe vivi
}

function init_hal_gps()
{
	# TODO
	return
}

function set_drm_mode()
{
	case "$PRODUCT" in
		ET1602*)
			drm_mode=1366x768
			;;
		*)
			;;
	esac

	[ -n "$drm_mode" ] && set_property debug.drm.mode.force $drm_mode
}

function init_uvesafb()
{
	case "$PRODUCT" in
		*Q550)
			UVESA_MODE=${UVESA_MODE:-1280x800}
			;;
		ET2002*)
			UVESA_MODE=${UVESA_MODE:-1600x900}
			;;
		T91*)
			UVESA_MODE=${UVESA_MODE:-1024x600}
			;;
		VirtualBox*|Bochs*)
			UVESA_MODE=${UVESA_MODE:-1024x768}
			;;
		*)
			;;
	esac

	modprobe uvesafb mode_option=${UVESA_MODE:-800x600}-16 ${UVESA_OPTION:-mtrr=3 scroll=redraw}
}

function init_hal_gralloc()
{
	case "$(cat /proc/fb | head -1)" in
		0*inteldrmfb|0*radeondrmfb)
			set_property hal.gralloc drm
			set_drm_mode
			;;
		0*svgadrmfb)
			;;
		"")
			init_uvesafb
			;&
		0*)
			[ "$HWACCEL" = "1" ] || set_property debug.egl.hw 0
			;;
	esac
}

function init_hal_hwcomposer()
{
	# TODO
	return
}

function init_hal_lights()
{
	chown 1000.1000 /sys/class/backlight/*/brightness
}

function init_hal_power()
{
	# TODO
	case "$PRODUCT" in
		*)
			;;
	esac
}

function init_hal_sensors()
{
	case "$(cat $DMIPATH/uevent)" in
		*T*00LA*)
			modprobe kfifo-buf
			modprobe industrialio-triggered-buffer
			modprobe hid-sensor-hub
			modprobe hid-sensor-iio-common
			modprobe hid-sensor-trigger
			modprobe hid-sensor-accel-3d
			modprobe hid-sensor-gyro-3d
			modprobe hid-sensor-als
			modprobe hid-sensor-magn-3d
			sleep 1; busybox chown -R 1000.1000 /sys/bus/iio/devices/iio:device?/
			set_property hal.sensors hsb
			;;
		*Lucid-MWE*)
			set_property ro.ignore_atkbd 1
			set_property hal.sensors hdaps
			;;
		*ICONIA*W5*)
			set_property hal.sensors w500
			;;
		*S10-3t*)
			set_property hal.sensors s103t
			;;
		*Inagua*)
			#setkeycodes 0x62 29
			#setkeycodes 0x74 56
			set_property ro.ignore_atkbd 1
			set_property hal.sensors kbd
			set_property hal.sensors.kbd.type 2
			;;
		*TEGA*|*2010:svnIntel:*)
			set_property ro.ignore_atkbd 1
			set_property hal.sensors kbd
			set_property hal.sensors.kbd.type 1
			io_switch 0x0 0x1
			setkeycodes 0x6d 125
			;;
		*tx2*)
			setkeycodes 0xb1 138
			setkeycodes 0x8a 152
			set_property hal.sensors kbd
			set_property hal.sensors.kbd.type 6
			set_property poweroff.doubleclick 0
			set_property qemu.hw.mainkeys 1
			;;
		*MS-N0E1*)
			set_property ro.ignore_atkbd 1
			set_property poweroff.doubleclick 0
			;;
		*Aspire1*25*)
			modprobe lis3lv02d_i2c
			set_property hal.sensors hdaps
			setkeycodes 0xe062 152 # on-screen P button -> sleep
			setkeycodes 0xe070 29  # on-keyboard big button
			setkeycodes 0xe001 125 # Laptop mode switch
			setkeycodes 0xe039 56  # Tablet mode switch
			echo -n "enabled" > /sys/class/thermal/thermal_zone0/mode
			;;
		*ThinkPad*Tablet*)
			set_property hal.sensors hdaps
			start wacom-input
			;;
		*)
			set_property hal.sensors kbd
			;;
	esac
}

function init_tscal()
{
	case "$PRODUCT" in
		T91|T101|ET2002|74499FU|945GSE-ITE8712)
			if [ ! -e /data/misc/tscal/pointercal ]; then
				mkdir -p /data/misc/tscal
				touch /data/misc/tscal/pointercal
				chown 1000.1000 /data/misc/tscal /data/misc/tscal/*
				chmod 775 /data/misc/tscal
				chmod 664 /data/misc/tscal/pointercal
			fi
			;;
		*)
			;;
	esac
}

function init_ril()
{
	case "$PRODUCT" in
		TEGA*|Intel*)
			set_property rild.libpath /system/lib/libreference-ril.so
			set_property rild.libargs "-d /dev/ttyUSB2"
			;;
		*)
			;;
	esac
}

function init_cpu_governor()
{
	governor=$(getprop cpu.governor)

	[ $governor ] && {
		for cpu in $(ls -d /sys/devices/system/cpu/cpu?); do
			echo $governor > $cpu/cpufreq/scaling_governor || return 1
		done
	}
}

function do_init()
{
	init_misc
	init_hal_audio
	init_hal_bluetooth
	init_hal_camera
	init_hal_gps
	init_hal_gralloc
	init_hal_hwcomposer
	init_hal_lights
	init_hal_power
	init_hal_sensors
	init_tscal
	init_ril
	chmod 640 /x86.prop
	post_init
}

function do_netconsole()
{
	modprobe netconsole netconsole="@/,@$(getprop dhcp.eth0.gateway)/"
}

function do_bootcomplete()
{
	init_cpu_governor

	[ -z "$(getprop persist.sys.root_access)" ] && setprop persist.sys.root_access 3

	# FIXME: autosleep works better on i965?
	[ "$(getprop debug.mesa.driver)" = "i965" ] && setprop debug.autosleep 1

	for bt in $(lsusb -v | awk ' /Class:.E0/ { print $9 } '); do
		chown 1002.1002 $bt && chmod 660 $bt
	done
}

PATH=/system/bin:/system/xbin

DMIPATH=/sys/class/dmi/id
BOARD=$(cat $DMIPATH/board_name)
PRODUCT=$(cat $DMIPATH/product_name)

# import cmdline variables
for c in `cat /proc/cmdline`; do
	case $c in
		androidboot.hardware=*)
			;;
		*=*)
			eval $c
			;;
	esac
done

[ -n "$DEBUG" ] && set -x || exec &> /dev/null

# import the vendor specific script
hw_sh=/vendor/etc/init.sh
[ -e $hw_sh ] && source $hw_sh

case "$1" in
	netconsole)
		[ -n "$DEBUG" ] && do_netconsole
		;;
	bootcomplete)
		do_bootcomplete
		;;
	init|"")
		do_init
		;;
esac

return 0
