#
# Copyright (C) 2013 The Android-x86 Open Source Project
#
# License: GNU Public License v2 or later
#

function set_hal_prop()
{
	[ -z $(getprop hal.$1) ] && setprop hal.$1 $2
}

function init_misc()
{
	# a hack for USB modem
	lsusb | grep 1a8d:1000 && eject
}

function init_hal_audio()
{
	alsa_ctl init
	alsa_amixer set Master on
	alsa_amixer set Master 100
	alsa_amixer set Headphone on
	alsa_amixer set Headphone 100
	alsa_amixer set Speaker 100
	alsa_amixer set Capture 100
	alsa_amixer set Capture cap
	alsa_amixer set PCM 100 unmute
	alsa_amixer set 'Mic Boost' 2
}

function init_hal_bluetooth()
{
	# TODO
	return
}

function init_hal_gps()
{
	# TODO
	return
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
		*)
			;;
	esac

	modprobe uvesafb mode_option=${UVESA_MODE:-800x600}-16 ${UVESA_OPTION:-mtrr=3 scroll=redraw}
}

function init_hal_gralloc()
{
	# disable cursor blinking
	[ "$(getprop system_init.startsurfaceflinger)" = "0" ] && echo -e '\033[?17;0;0c' > /dev/tty0

	case "$(cat /proc/fb)" in
		0*inteldrmfb|0*radeondrmfb)
			set_hal_prop gralloc drm
			;;
		"")
			init_uvesafb
			;&
		0*)
			setprop debug.egl.hw 0
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
	# change brightness file permission for liblights
	brfile=$(getprop backlight.brightness_file)
	chown 1000.1000 ${brfile:-/sys/class/backlight/acpi_video0/brightness}
}

function init_hal_power()
{
	# TODO
	return
}

function init_hal_sensors()
{
	case "$PRODUCT" in
		*)
			;;
	esac
}

function init_touch()
{
	case "$PRODUCT" in
		ET2002*)
			BOARD_USES_TSLIB=true
			TOUCH=
			;;
		ET1602*)
			TOUCH=
			;;
		*Q550|Latitude*ST)
			TOUCH=hid-ntrig
			;;
		T91|T101)
			BOARD_USES_TSLIB=true
			TOUCH=
			;;
		*)
			# use hid-multitouch by default
			TOUCH=hid-multitouch
			;;
	esac

	[ -n "$TOUCH" ] && modprobe $TOUCH
}

function do_init()
{
	init_misc
	init_hal_audio
	init_hal_bluetooth
	init_hal_gps
	init_hal_gralloc
	init_hal_hwcomposer
	init_hal_lights
	init_hal_power
	init_hal_sensors
	init_touch
	post_init
}

function do_netconsole()
{
	modprobe netconsole netconsole="@/,@$(getprop dhcp.eth0.gateway)/"
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
		echo bootcomplete # for debugging
		;;
	init|"")
		do_init
		return 0
		;;
esac
