#!/bin/bash

#**************************************************************************
# Post-process all blender images into NewGRF sprites
# Version 1
# 2012-04-16
# Xotic750
# This release may be used under the terms of the license: GPLv2
# http://www.gnu.org/licenses/gpl-2.0.html
#**************************************************************************

LIST="./scripts/model.lst"
SCRIPT="./scripts/postprocess.sh"
let COUNT=0

while read LINE; do
    case $LINE in
        [a-zA-Z0-9]*)
            NAME="$(echo $LINE)"
            $SCRIPT $NAME
            EXIT_CODE=$?
            if [ ! $EXIT_CODE -eq 0 ]; then
                echo "Failed to post-process: $NAME"
                exit $EXIT_CODE
            fi
            ;;
        *)
            ;;
    esac

    let COUNT++
done<$LIST
