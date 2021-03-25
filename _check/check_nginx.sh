#! /bin/bash

# nginx can be built if package list is defined
[ ! -f nginx-packages.lst ] &&  FEATURES=("${FEATURES[@]/nginx}")

