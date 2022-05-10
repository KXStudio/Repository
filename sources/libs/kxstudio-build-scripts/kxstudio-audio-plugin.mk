#!/usr/bin/make -f

include /usr/share/dpkg/kxstudio.mk

export DEB_HOST_ARCH

define kxstudio_audio_plugin_test
	/usr/share/dpkg/kxstudio-audio-plugin.sh
endef
