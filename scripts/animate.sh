#!/bin/sh

#**************************************************************************
# Animate a blender file from the command line
# Version 1
# 2012-04-16
# Xotic750
# This release may be used under the terms of the license: GPLv2
# http://www.gnu.org/licenses/gpl-2.0.html
#**************************************************************************

DIRECTORY="./sprite_source/blender/"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <model-name>"
    exit 1
fi

blender -b $DIRECTORY$1.blend -a
