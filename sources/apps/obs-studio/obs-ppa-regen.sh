#!/bin/bash

set -e

PPA_URL="https://launchpad.net/~obsproject/+archive/ubuntu/obs-studio"
SUFFIX="0obsproject1"
VERSION="29.1.2"
DISTS=("focal" "jammy" "kinetic" "lunar")
RVER=5

wget -c "${PPA_URL}/+files/obs-studio_29.1.2.orig.tar.gz"

for d in ${DISTS[@]}; do
  wget -c "${PPA_URL}/+sourcefiles/obs-studio/${VERSION}-${SUFFIX}~${d}/obs-studio_${VERSION}-${SUFFIX}~${d}.debian.tar.xz"
  rm -rf obs-studio
  tar xf obs-studio_${VERSION}.orig.tar.gz
  tar xf obs-studio_${VERSION}-${SUFFIX}~${d}.debian.tar.xz -C obs-studio
  sed -i "s/Build-Depends:/Build-Depends: carla, carla-dev,/" obs-studio/debian/control
  mkdir -p obs-studio/debian/patches
  cp 1000_carla-plugin.patch obs-studio/debian/patches
  echo 1000_carla-plugin.patch >> obs-studio/debian/patches/series
  pushd obs-studio
  env DEBEMAIL="falktx@falktx.com" dch -v "${VERSION}-${SUFFIX}+carla${RVER}~${d}" -D "${d}" --force-distribution "Add carla plugin host module"
  debuild --no-lintian -S -sa -d
  popd
done
