#!/bin/bash

mkdir -p dist

CWD=$(pwd)

cd $1

tar cvjf Chrome.app.bz2 Chrome.app

mv Chrome.app.bz2 ${CWD}/dist/
