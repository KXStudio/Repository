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

VALRIND_BIN="valgrind --error-exitcode=255 --leak-check=full --track-origins=yes --suppressions=$(dirname ${0})/kxstudio-audio-plugin.supp"
VALRIND_BRIDGE_BIN="${VALRIND_BIN} ${CARLA_BRIDGE_NATIVE_BIN}"
VALRIND_DISCOVERY_BIN="${VALRIND_BIN} ${CARLA_DISCOVERY_NATIVE_BIN}"

export CARLA_BRIDGE_DUMMY=1
export CARLA_BRIDGE_TESTING=native
export LV2_PATH=$(pwd)/debian/${PKG_NAME}/usr/lib/lv2:/tmp/lv2-spec

rm -rf /tmp/lv2-spec
mkdir /tmp/lv2-spec
cp -r /usr/lib/lv2/{atom,buf-size,core,data-access,kx-control-input-port-change-request,kx-programs,instance-access,midi,parameters,port-groups,port-props,options,patch,presets,resize-port,state,time,ui,units,urid,worker}.lv2 /tmp/lv2-spec/

if [ -d debian/${PKG_NAME}/usr/lib/lv2 ]; then
    pushd debian/${PKG_NAME}/usr/lib/lv2
    lv2_validate */*.ttl
    lv2lint $(lv2ls)
    # -s lv2_generate_ttl -l ld-linux-x86-64.so.2 -M nopack $(lv2ls)
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
    for p in $(ls .so */*.so 2>/dev/null | grep -e '.*\.so' -e '.*\.vst/.*\.so' | grep -v 'lib.*\.so' | grep -v 'carla-bridge-lv2.so'); do
        ${VALRIND_DISCOVERY_BIN} vst2 ./${p}
        ${VALRIND_BRIDGE_BIN} vst2 ./${p} "" 1>/dev/null;
    done
    popd
fi

if [ -d debian/${PKG_NAME}/usr/lib/vst3 ]; then
    pushd debian/${PKG_NAME}/usr/lib/vst3
    for p in $(ls); do
        ${VALRIND_DISCOVERY_BIN} vst3 ./${p}
        ${VALRIND_BRIDGE_BIN} vst3 ./${p} "" 1>/dev/null;
    done
    popd
fi
