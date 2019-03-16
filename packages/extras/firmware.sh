# Copyright (c) 2015 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

# This file is a part of the Armbian build script
# https://github.com/armbian/build/

build_firmware()
{
	display_alert "Merging and packaging linux firmware" "@host" "info"

	local plugin_repo="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
	local plugin_dir="firmware-armbian${FULL}"
	[[ -d $SRC/cache/sources/$plugin_dir ]] && rm -rf $SRC/cache/sources/$plugin_dir

	fetch_from_repo "https://github.com/armbian/firmware" "firmware-armbian-git" "branch:master"
	if [[ -n $FULL ]]; then
		fetch_from_repo "$plugin_repo" "$plugin_dir/lib/firmware" "branch:master"
	fi
	mkdir -p $SRC/cache/sources/$plugin_dir/lib/firmware
	# overlay our firmware
	cp -R $SRC/cache/sources/firmware-armbian-git/* $SRC/cache/sources/$plugin_dir/lib/firmware

	# cleanup what's not needed for sure
	rm -rf $SRC/cache/sources/$plugin_dir/lib/firmware/{amdgpu,amd-ucode,radeon,nvidia,matrox,.git}
	cd $SRC/cache/sources/$plugin_dir

	# set up control file
	mkdir -p DEBIAN
	cat <<-END > DEBIAN/control
	Package: firmware-armbian${FULL}
	Version: $REVISION
	Architecture: all
	Maintainer: $MAINTAINER <$MAINTAINERMAIL>
	Installed-Size: 1
	Replaces: linux-firmware, firmware-brcm80211, firmware-samsung, firmware-realtek, firmware-armbian${REPLACE}
	Section: kernel
	Priority: optional
	Description: Linux firmware${FULL}
	END

	cd $SRC/cache/sources
	# pack
	mv firmware-armbian${FULL} firmware-armbian${FULL}_${REVISION}_all
	fakeroot dpkg -b firmware-armbian${FULL}_${REVISION}_all >> $DEST/debug/install.log 2>&1
	mv firmware-armbian${FULL}_${REVISION}_all firmware-armbian${FULL}
	mv firmware-armbian${FULL}_${REVISION}_all.deb $DEST/debs/ || display_alert "Failed moving firmware package" "" "wrn"
}

FULL=""
REPLACE="-full"
[[ ! -f $DEST/debs/firmware-armbian_${REVISION}_all.deb ]] && build_firmware
FULL="-full"
REPLACE=""
[[ ! -f $DEST/debs/firmware-armbian${FULL}_${REVISION}_all.deb ]] && build_firmware

# install basic firmware by default
install_deb_chroot "$DEST/debs/firmware-armbian-full_${REVISION}_all.deb"
