#!/usr/bin/make -f

include /usr/share/dpkg/kxstudio.mk

define kxstudio_audio_plugin_test
	/usr/share/dpkg/kxstudio-audio-plugin.sh
endef
