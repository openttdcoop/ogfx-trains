#!/bin/bash

#**************************************************************************
# Animate all blender file into raw images
# Version 2
# 2012-04-19
# Xotic750
# This release may be used under the terms of the license: GPLv2
# http://www.gnu.org/licenses/gpl-2.0.html
#**************************************************************************

#**************************************************************************
# If a parameter is supplied to the script then use that parameter
# as the list source
#**************************************************************************

if [ $# -ge 1 ]; then
    LIST=$1
else
    LIST="./scripts/model.lst"
fi

#**************************************************************************
# The animate script to be run for each model in the list
#**************************************************************************

SCRIPT="./scripts/animate.sh"

#**************************************************************************
# Animate each model in the list
#**************************************************************************

let COUNT=0

while read LINE; do
    case $LINE in
        # Execute only lines that begin with alpha-numeric character
        [a-zA-Z0-9]*)
            # Remove extra white-spaces from the line then execute the script
            NAME="$(echo $LINE)"
            $SCRIPT $NAME
            # Exit on failure
            EXIT_CODE=$?
            if [ ! $EXIT_CODE -eq 0 ]; then
                echo "Failed to animate: $NAME"
                exit $EXIT_CODE
            fi
            ;;
        # Ignore all others
        *)
            ;;
    esac

    let COUNT++
done<$LIST
