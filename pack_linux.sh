#!/bin/bash

mkdir -p dist

CWD=$(pwd)

cd ${2} && autoninja -C ${1} "chrome/installer/linux:unstable_deb"

cp ${1}/chromium-browser*.deb ${CWD}/dist
