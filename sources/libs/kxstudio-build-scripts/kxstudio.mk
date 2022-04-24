#!/usr/bin/make -f

include /usr/share/dpkg/architecture.mk

FLAGS  = -O3 -fPIC -DPIC -fvisibility=hidden -fdata-sections -ffunction-sections -DNDEBUG
ifeq ($(DEB_HOST_ARCH),armhf)
FLAGS += -march=armv7ve -mcpu=cortex-a7 -mfloat-abi=hard -mfpu=neon-vfpv4
else ifeq ($(DEB_HOST_ARCH),arm64)
FLAGS += -march=armv8-a -mcpu=cortex-a53
else
FLAGS += -mtune=generic -msse -msse2 -mfpmath=sse
endif

ifeq ($(KXSTUDIO_NO_FASTMATH),)
FLAGS += -ffast-math
endif

export CFLAGS=$(FLAGS)
export CXXFLAGS=$(FLAGS) -fvisibility-inlines-hidden
export CPPFLAGS=
export LDFLAGS=-Wl,-O1,--as-needed,--no-undefined,--gc-sections,--strip-all
export PATH:=/opt/kxstudio/bin:$(PATH)
export PKG_CONFIG_PATH=/opt/kxstudio/lib/pkgconfig

ifeq ($(KXSTUDIO_EXPLICIT_PATH_INCLUDE),y)
export CFLAGS += -I/opt/kxstudio/include
export CXXFLAGS += -I/opt/kxstudio/include
export LDFLAGS += -L/opt/kxstudio/lib
endif
