#!/bin/bash

set -e

if [ "$(cat debian/control | grep 'Package: ' | wc -l)" -eq 1 ]; then
    PKG_NAME=$(cat debian/control | awk 'sub("Package: ","")')
else
    PKG_NAME=${PKG_NAME:=tmp}
fi

if [ ! -d debian/${PKG_NAME} ]; then
    echo "package is not installed, abort!"
    exit 1
fi

if [ -d debian/${PKG_NAME}/usr/local/lib ]; then
    echo "error: files are installed in /usr/local"
    exit 1
fi

if [ -d debian/${PKG_NAME}/usr/lib/x86_64-linux-gnu ]; then
    echo "error: files are installed in multi-arch lib dir"
    exit 1
fi

CARLA_BRIDGE_NATIVE_BIN=/opt/kxstudio/lib/carla/carla-bridge-native
CARLA_DISCOVERY_NATIVE_BIN=/opt/kxstudio/lib/carla/carla-discovery-native

VALRIND_BIN="valgrind --error-exitcode=255 --leak-check=full --track-origins=yes --suppressions=$(dirname ${0})/kxstudio-audio-plugin.supp ${VALGRIND_EXTRA_ARGS}"
VALRIND_DISCOVERY_BIN="${VALRIND_BIN} ${CARLA_DISCOVERY_NATIVE_BIN}"

# skip main valgrind test on armhf, incomplete syscall support
if [ "${DEB_HOST_ARCH}" != "armhf" ]; then
    VALRIND_BRIDGE_BIN="${VALRIND_BIN} ${CARLA_BRIDGE_NATIVE_BIN}"
else
    VALRIND_BRIDGE_BIN="${CARLA_BRIDGE_NATIVE_BIN}"
fi

export CARLA_BRIDGE_DUMMY=1
export CARLA_BRIDGE_TESTING=native
export LV2_PATH=$(pwd)/debian/${PKG_NAME}/usr/lib/lv2:/tmp/lv2-spec

rm -rf /tmp/lv2-spec
mkdir /tmp/lv2-spec
cp -r /usr/lib/lv2/{atom,buf-size,core,data-access,instance-access,midi,parameters,port-groups,port-props,options,patch,presets,resize-port,state,time,ui,units,urid,worker}.lv2 /tmp/lv2-spec/
cp -r /usr/lib/lv2/dg-* /usr/lib/lv2/kx-* /usr/lib/lv2/mod.lv2 /usr/lib/lv2/modgui.lv2 /usr/lib/lv2/mod-hmi.lv2 /usr/lib/lv2/mod-license.lv2 /tmp/lv2-spec/

if [ -d debian/${PKG_NAME}/usr/lib/lv2 ]; then
    pushd debian/${PKG_NAME}/usr/lib/lv2
    lv2_validate \
        /usr/lib/lv2/dg-*/*.ttl \
        /usr/lib/lv2/kx-*/*.ttl \
        /usr/lib/lv2/mod.lv2/*.ttl \
        /usr/lib/lv2/modgui.lv2/*.ttl \
        /usr/lib/lv2/mod-hmi.lv2/*.ttl \
        /usr/lib/lv2/mod-license.lv2/*.ttl \
        */*.ttl
    if [ -z "${LV2LINT_SKIP}" ]; then
        lv2lint ${LV2LINT_EXTRA_FLAGS} -s lv2_generate_ttl $(lv2ls)
    fi
    for p in $(ls); do
        ${VALRIND_DISCOVERY_BIN} lv2 ./${p}
    done
    for p in $(lv2ls); do
        ${VALRIND_BRIDGE_BIN} lv2 "" ${p} 1>/dev/null;
    done
    popd
fi

if [ -d debian/${PKG_NAME}/usr/lib/ladspa ]; then
    pushd debian/${PKG_NAME}/usr/lib/ladspa
    for p in $(ls); do
        ${VALRIND_DISCOVERY_BIN} ladspa ./${p}
        ${VALRIND_BRIDGE_BIN} ladspa ./${p} "" 1>/dev/null;
    done
    popd
fi

if [ -d debian/${PKG_NAME}/usr/lib/dssi ]; then
    pushd debian/${PKG_NAME}/usr/lib/dssi
    for p in $(ls); do
        ${VALRIND_DISCOVERY_BIN} dssi ./${p}
        ${VALRIND_BRIDGE_BIN} dssi ./${p} "" 1>/dev/null;
    done
    popd
fi

if [ -d debian/${PKG_NAME}/usr/lib/vst ]; then
    pushd debian/${PKG_NAME}/usr/lib/vst
    for p in $(ls .so */*.so 2>/dev/null | grep -e '.*\.so' -e '.*\.vst/.*\.so' | grep -v 'lib.*\.so' | grep -v 'carla-bridge-lv2.so' | grep -v 'lsp-plugins-vst2.*\.so'); do
        ${VALRIND_DISCOVERY_BIN} vst2 ./${p}
        ${VALRIND_BRIDGE_BIN} vst2 ./${p} "" 1>/dev/null;
    done
    popd
fi

# TODO wait until carla supports vst3 natively
# if [ -d debian/${PKG_NAME}/usr/lib/vst3 ]; then
#     pushd debian/${PKG_NAME}/usr/lib/vst3
#     for p in $(ls); do
#         ${VALRIND_DISCOVERY_BIN} vst3 ./${p}
#         ${VALRIND_BRIDGE_BIN} vst3 ./${p} "" 1>/dev/null;
#     done
#     popd
# fi
