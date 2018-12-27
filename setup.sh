#!/bin/bash
# Ugeek Raspi Media Player Setup
FILE_CONFIG="/boot/config.txt"
FILE_RCLOCAL="/etc/rc.local"
FONT_URL="https://github.com/adobe-fonts/source-han-sans/raw/release/OTC/SourceHanSans-Bold.ttc"
FONT_FILE="/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc"
FONT_SIZE="0.055"

function check_requiments(){
	echo "]Update System["
	SOFT=$(dpkg -l python-dev python-pip python-smbus | grep "<none>")
	if [ -n "$SOFT" ]; then
		apt update
		apt -y install python-dev python-pip python-smbus
		echo "python-dev python-pip python-smbus install complete."
	else
		echo "python-dev python-pip python-smbus already exists."
	fi
	SOFT=$(dpkg -l python-evdev | grep "matching")
	if [ -n "$SOFT" ]; then
		dpkg -i resources/python-evdev_0.6.4-1_armhf.deb 
		echo "python-evdev install complete."
	else
		echo "python-evdev already exists."
	fi
	SOFT=$( pip search evdev | grep "INSTALLED")
	if [ -z "$SOFT" ]; then
		pip install evdev
		echo "python-evdev install complete!"
	else
		echo "python-evdev already exists."
	fi
	SOFT=$( pip search RPi.GPIO | grep "INSTALLED")
	if [ -z "$SOFT" ]; then
		pip install RPi.GPIO
		echo "python-RPi.GPIO install complete!"
	else
		echo "python-RPi.GPIO already exists."
	fi
}
function disable_screen(){
	echo "Disable screen!"
	sed -i '/^dtparam=ugeekrmp/d' $FILE_CONFIG
	sed -i '/^overscan_left=0/d' $FILE_CONFIG
	sed -i '/^overscan_right=0/d' $FILE_CONFIG
	sed -i '/^overscan_top=0/d' $FILE_CONFIG
	sed -i '/^overscan_bottom=0/d' $FILE_CONFIG
	sed -i '/^framebuffer_width=800/d' $FILE_CONFIG
	sed -i '/^framebuffer_height=480/d' $FILE_CONFIG
	sed -i '/^enable_dpi_lcd=1/d' $FILE_CONFIG
	sed -i '/^display_default_lcd=1/d' $FILE_CONFIG
	sed -i '/^dpi_group=2/d' $FILE_CONFIG
	sed -i '/^dpi_mode=87/d' $FILE_CONFIG
	sed -i '/^dpi_output_format=0x6f016/d' $FILE_CONFIG
	sed -i '/^display_rotate=0/d' $FILE_CONFIG
	sed -i '/^hdmi_timings=800 0 50 20 50 480 1 3 2 3 0 0 0 60 0 32000000 6/d' $FILE_CONFIG
	sed -i '/^dtoverlay=ugeekrmp-gpio-backlight/d' $FILE_CONFIG
	systemctl stop ugeekrmp-init
	systemctl stop ugeekrmp-touch
	systemctl disable ugeekrmp-init
	systemctl disable ugeekrmp-touch
	if [ -e "/usr/lib/systemd/system/ugeekrmp-init.service" ]; then
		rm /usr/lib/systemd/system/ugeekrmp-init.service
	fi
	if [ -e "/usr/lib/systemd/system/ugeekrmp-touch.service" ]; then
		rm /usr/lib/systemd/system/ugeekrmp-touch.service
	fi
	if [ -e "/usr/bin/ugeekrmp-init" ]; then
		rm /usr/bin/ugeekrmp-init
	fi
	if [ -e "/usr/bin/ugeekrmp-touch" ]; then
		/usr/bin/ugeekrmp-touch
	fi
}
function enable_screen(){
	echo "enable screen!"
	cat << EOF >> $FILE_CONFIG
dtoverlay=ugeekrmp
overscan_left=0
overscan_right=0
overscan_top=0
overscan_bottom=0
framebuffer_width=800
framebuffer_height=480
enable_dpi_lcd=1
display_default_lcd=1
dpi_group=2
dpi_mode=87
dpi_output_format=0x6f016
display_rotate=0
hdmi_timings=800 0 50 20 50 480 1 3 2 3 0 0 0 60 0 32000000 6
dtoverlay=ugeekrmp-gpio-backlight
EOF
	cp resources/ugeekrmp-init /usr/bin/
	cp resources/ugeekrmp-touch /usr/bin/
	cp configs/ugeekrmp-init.service /usr/lib/systemd/system
	cp configs/ugeekrmp-touch.service /usr/lib/systemd/system
	systemctl enable ugeekrmp-init
	systemctl enable ugeekrmp-touch
	systemctl start ugeekrmp-init
	systemctl start ugeekrmp-touch
}
function disable_keyboard(){
	echo "disale keys!"
	sed -i '/ugeekrmp/d' $FILE_RCLOCAL
	if [ -e "/usr/local/bin/ugeekrmp" ]; then
		rm /usr/local/bin/ugeekrmp
	fi
	if [ -e "/etc/udev/rules.d/10-ugeekrmp.rules" ]; then
		rm /etc/udev/rules.d/10-ugeekrmp.rules
	fi
}
function enable_keyboard(){
	echo "enable keys!"
	cp resources/ugeekrmp /usr/local/bin/
	sed -i '/^exit 0/i\/user\/local\/bin\/ugeekrmp &' $FILE_RCLOCAL
}
function disable_ui(){
	echo "disable ui!"
	if [ -e "/home/pi/touchboot" ]; then
		rm -rf /home/pi/touchboot
	fi
	sed -i '/touchboot/d' $FILE_RCLOCAL
}
function enable_ui(){
	echo "enable ui!"
	if [ ! -e "/home/pi/touchboot" ]; then
		cp -a touchboot /home/pi/
	fi
	sed -i '/^exit 0/icd \/home\/pi\/touchboot;.\/starter.sh &' $FILE_RCLOCAL
}
function disable_CJK_font(){
	if [ -e "/etc/emulationstation/themes/carbon/carbon.xml" ]; then
		sed -i -e 's/SourceHanSans-Bold.ttc/Cabin-Bold.ttf/g' /etc/emulationstation/themes/carbon/carbon.xml
	fi
	if [ -e "/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc" ]; then
		rm $FONT_FILE
	fi

}
function enable_CJK_font(){
	if [ ! -e "resources/SourceHanSans-Bold.ttc" ]; then
		curl -LJ0 -o resources/SourceHanSans-Bold.ttc $FONT_URL
	fi
	if [ ! -e "/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc" ]; then
		cp resources/SourceHanSans-Bold.ttc $FONT_FILE
	fi
	
	echo ">Change font of emulationstatoin"
	sed -i -e 's/Cabin-Bold.ttf/SourceHanSans-Bold.ttc/g' /etc/emulationstation/themes/carbon/carbon.xml
}
main(){
	disable_screen
	enable_screen
	disable_keyboard
	enable_keyboard
	disable_ui
	enable_ui
	disable_CJK_font
	enable_CJK_font
}
main