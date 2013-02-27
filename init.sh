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
	case "$PRODUCT" in
		VirtualBox*|QEMU*)
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
		alsa_amixer -c $c set 'Mic Boost' 2
	done
}

function init_hal_bluetooth()
{
	# TODO
	return
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
		*ICONIA*W*)
			set_hal_prop sensors w500
			;;
		*S10-3t*)
			set_hal_prop sensors s103t
			;;
		*Inagua*)
			#setkeycodes 0x62 29
			#setkeycodes 0x74 56
			set_hal_prop sensors kbd
			set_hal_prop sensors.kbd.type 2
			;;
		*TEGA*|*Intel*)
			set_hal_prop sensors kbd
			set_hal_prop sensors.kbd.type 1
			io_switch 0x0 0x1
			setkeycodes 0x6d 125
			;;
		*MS-N0E1*)
			;;
		*)
			set_hal_prop sensors kbd
			;;
	esac
}

function init_ril()
{
	case "$PRODUCT" in
		TEGA*|Intel*)
			setprop rild.libpath /system/lib/libreference-ril.so
			setprop rild.libargs "-d /dev/ttyUSB2"
			;;
		*)
			;;
	esac
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
	init_ril
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
