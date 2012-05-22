#!/bin/sh

#**************************************************************************
# Post-process rendered blender images into NewGRF sprites
# Version 2
# 2012-05-02
# Xotic750
# This release may be used under the terms of the license: GPLv2
# http://www.gnu.org/licenses/gpl-2.0.html
#**************************************************************************

#**************************************************************************
#
#                                VARIABLES
#
#**************************************************************************

# Define variables
RENDERED="$PWD/sprite_source/blender/rendered"
PCS="$PWD/sprite_source/blender/rendered/processing"
ENGINES="$PWD/src/gfx/engines"
SCMDIR="$PWD/scripts/gimp_scripts"
GPLDIR="$PWD/scripts/gimp_palettes"
# You should not need to change the following variables
I1X="in1x"
I2X="in2x"
I4X="in4x"
MASK="m"
# You should not need to change the following variables
TEMPORARY="/tmp"
SPRITES=8
INS="_"
INS8="_8"
INS32="_32"
GIMPRC="gimprc"
EXT="png"
# If you want more or less information then set VERBOSE to one of the following:
# 0 - quiet, 1 - moderate, 2 - noisy, 3 - max
# Do not change the values of V_XXXX, just set VERBOSE to the one you want
V_QUIET=0
V_MODERATE=1
V_NOISY=2
V_MAX=3
VERBOSE=$V_QUIET
# V_START and V_STOP are special values and do not need to be changed
V_START=-1
V_STOP=-2
# Models are rendered at 400% and you should not need to change these unless you
# re-render with a different scale.
# 4x=4, 2x=8, 1x=16
SCALE4X=4
SCALE2X=8
SCALE1X=16
# Interpolation method used by GIMP during scaling
# INTERPOLATION-NONE (0)
# INTERPOLATION-LINEAR (1)
# INTERPOLATION-CUBIC (2)
# INTERPOLATION-LANCZOS (3)
METHOD4X=3
METHOD2X=3
METHOD1X=3
# You should not need to change these values unless you re-render with a different scale
# and if you do then the nml offset will need recalculating.
# x1=720 y1=496 x2=592 y2=1316
#CROPX1=720
#CROPY1=496
#CROPX2=592
#CROPY2=1316

# Exit codes
# An exit status of zero indicates success, and a nonzero value indicates failure.
E_USAGE=1
E_SOURCE=2
E_DESTINATION=3
E_PARAMETERS=4
E_GIMP=5
E_RENDERED=6
E_ENGINES=7
E_SCMDIR=8
E_GPLDIR=9
E_SRC=10
E_PCS=11
E_RM_DST=12
E_RM_TMP=13
E_MK_DST=14
E_DST=15
E_MK_TMP=16
E_TMP=17
E_GIMPRC=18
E_MK_POSTCC1=19
E_MK_POSTCC2=20
E_MK_POSTMSK8=21
E_MK_POSTMSK32=22
E_MK_SRCMASK32=23
E_MK_DST8=24
E_MK_DST32=27
E_MK_DSTMSK32=28
E_MK_DSTPCHS=29
E_CP_REN_1=30
E_CP_REN_2=31
E_CP_REN_3=32
E_CP_REN_4=33
E_CP_REN_5=34
E_CROP_1=35
E_CROP_2=36
E_CROP_3=37
E_CROP_4=38
E_CROP_5=39
E_CC1=40
E_CC2=41
E_CP_MASK8=42
E_MG_MASK8=43
E_CP_MAGIC=44
E_MG_MASK32=45
E_MG_8BPP=46
E_INDEX_MASK32=47
E_CP_MASK32=48
E_CP_ZOOM_1=49
E_CP_ZOOM_2=50
E_CP_ZOOM_3=51
E_CP_ZOOM_4=52
E_CP_ZOOM_5=53
E_CP_ZOOM_6=54
E_CP_ZOOM_7=55
E_CP_ZOOM_8=56
E_SCALE_1=57-n
E_SCALE_2=58
E_SCALE_3=59
E_SCALE_4=60
E_SCALE_5=61
E_SCALE_6=62
E_SCALE_7=63
E_SCALE_8=64
E_SCALE_9=65
E_SCALE_10=66
E_SHARPEN_1=67
E_SHARPEN_2=68
E_SHARPEN_3=69
E_LEVELS_1=69
E_LEVELS_2=70
E_LEVELS_3=71

# Internal variable for holding the model name
T_MODEL=$1
# Enable verbose command switch depending on user setting
if [ $VERBOSE -ge $V_MAX ]; then
    SWITCH_V="-v"
else
    SWITCH_V=""
fi

#**************************************************************************
#
#                           FUNCTION DEFINITIONS
#
#**************************************************************************

# Function: func_param_check
# Parameters: <line number> <function name> <param count> <min params>
function func_param_check()
{
    if [ $# -lt 4 ]; then
        echo -e "$(date +%s):$0:$T_MODEL:func_param_check::Parameter count ($#) but must be (4)\n" 1>&2
        exit $E_PARAMETERS
    fi

    if [ $3 -lt $4 ]; then
        echo -e "$(date +%s):$0:$T_MODEL:$2:$1:Parameter count ($3) but must be ($4)\n" 1>&2
        exit $E_PARAMETERS
    fi
}

#**************************************************************************
# Function: func_echo_spin
# Parameters: <line number> <verbose number> <text>
#**************************************************************************
function func_echo_spin()
{
    func_param_check $1 $FUNCNAME $# 3
    local CHARACTER

    case $2 in
        $V_START)
            echo -n $3
            if [ $VERBOSE -ge $V_MODERATE ]; then
                echo
            else
                echo -n " [ ]"
            fi
            ;;
        $V_STOP)
            if [ $VERBOSE -eq $V_QUIET ]; then
                echo -ne "\b\b*] "
            fi

            echo $3
            ;;
        *)
            if [ $VERBOSE -ge $2 ]; then
                echo "$3"
            else
                if [ $VERBOSE -eq $V_QUIET ]; then
                    let Q_COUNT++
                    case $Q_COUNT in
                    1)
                        CHARACTER="-"
                        ;;
                    2)
                        CHARACTER="\\"
                        ;;
                    3)
                        CHARACTER="|"
                        ;;
                    *)
                        Q_COUNT=0
                        CHARACTER="/"
                        ;;
                    esac

                    echo -ne "\b\b$CHARACTER]"
                fi
            fi
            ;;
    esac
}

#**************************************************************************
# Function: func_strip_trailing_slashes
# Parameters: <line number> <var pointer> <path string>
#**************************************************************************
function func_strip_trailing_slashes()
{
    func_param_check $1 $FUNCNAME $# 3
    local PATTERN='^.*[^/]'
    local __RESULTVAR=$2
    local STRIPPED_SLASHES=$3
    [[ $STRIPPED_SLASHES =~ $PATTERN ]]
    STRIPPED_SLASHES=${BASH_REMATCH[0]}

    if [[ "$__RESULTVAR" ]]; then
        eval $__RESULTVAR="'$STRIPPED_SLASHES'"
    else
        echo "$STRIPPED_SLASHES"
    fi
}

#**************************************************************************
# Function: func_add_trailing_slash
# Parameters: <line number> <var pointer> <path string>
#**************************************************************************
function func_add_trailing_slash()
{
    func_param_check $1 $FUNCNAME $# 3
    local __RESULTVAR=$2
    local ADDED_SLASH="$3/"

    if [[ "$__RESULTVAR" ]]; then
        eval $__RESULTVAR="'$ADDED_SLASH'"
    else
        echo "$ADDED_SLASH"
    fi
}

#**************************************************************************
# Function: func_format_path
# Parameters: <line number> <var pointer> <path string>
#**************************************************************************
function func_format_path()
{
    func_param_check $1 $FUNCNAME $# 3
    local __RESULTVAR=$2
    local FORMATTED_PATH

    func_strip_trailing_slashes $LI-nNENO FORMATTED_PATH $3
    func_add_trailing_slash $LINENO FORMATTED_PATH $FORMATTED_PATH

    if [[ "$__RESULTVAR" ]]; then
        eval $__RESULTVAR="'$FORMATTED_PATH'"
    else
        echo "$FORMATTED_PATH"
    fi
}

#**************************************************************************
# Function: func_concat_path
# Parameters: <line number> <var pointer> <path string 1> <path string 2>
#**************************************************************************
function func_concat_path()
{
    func_param_check $1 $FUNCNAME $# 4
    local __RESULTVAR=$2
    local CONCATTED_PATH

    func_format_path $LINENO CONCATTED_PATH $3
    CONCATTED_PATH=$CONCATTED_PATH$4

    if [[ "$__RESULTVAR" ]]; then
        eval $__RESULTVAR="'$CONCATTED_PATH'"
    else
        echo "$CONCATTED_PATH"
    fi
}

#**************************************************************************
# Function: func_exit_on_error
# Parameters: <line number> <exit check number> <error text> [<user exit number>]
#**************************************************************************
function func_exit_on_error()
{
    func_param_check $1 $FUNCNAME $# 3

    if [ $2 -ne 0 ]; then
        echo -e "$(date +%s):$0:$T_MODEL:::$3\n" 1>&2
        if [ $# -gt 3 ]; then
            exit $4
        else
            exit $2
        fi
    fi
}

#**************************************************************************
# Function: func_remove
# Parameters: <line number> <src files> [<user exit number>]
#**************************************************************************
function func_remove()
{
    func_param_check $1 $FUNCNAME $# 2
    func_echo_spin $LINENO $V_NOISY "Removing: $2"
    rm --preserve-root -rf $SWITCH_V $2
    local EXIT_VAL=$?
    local ERR_TXT="Failed to remove:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_error $LINENO $EXIT_VAL "$ERR_TXT" $3
    else
        func_exit_on_error $LINENO $EXIT_VAL "$ERR_TXT"
    fi
}

#**************************************************************************
# Function: func_mkdir
# Parameters: <line number> <directory> [<user exit number>]
#**************************************************************************
function func_mkdir()
{
    func_param_check $1 $FUNCNAME $# 2
    if [ ! -d $2 ]; then
        func_echo_spin $LINENO $V_NOISY "Creating directory: $2"
        mkdir $SWITCH_V $2
        local EXIT_VAL=$?
        local ERR_TXT="Failed to create directory:$2"

        if [ $# -gt 2 ]; then
            func_exit_on_error $LINENO $EXIT_VAL "$ERR_TXT" $3
        else
            func_exit_on_error $LINENO $EXIT_VAL "$ERR_TXT"
        fi
    fi
}

#**************************************************************************
# Function: func_chkdir
# Parameters: <line number> <directory> <error text> [<user exit number>]
#**************************************************************************
function func_chkdir()
{
    func_param_check $1 $FUNCNAME $# 2
    if [ ! -d $2 ]; then
        if [ $# -gt 3 ]; then
            func_exit_on_error $LINENO 1 "$3" $4
        else
            func_exit_on_error $LINENO 1 "$3"
        fi
    fi
}

#**************************************************************************
# Function: func_copy
# Parameters: <line number> <src files> <dst files> [<user exit number>]
#**************************************************************************
function func_copy()
{
    func_param_check $1 $FUNCNAME $# 3
    func_echo_spin $LINENO $V_NOISY "Copying: $2 $3"
    cp -f $SWITCH_V $2 $3
    local EXIT_VAL=$?
    local ERR_TXT="Failed to copy:$2 $3"

    if [ $# -gt 3 ]; then
        func_exit_on_error $LINENO $EXIT_VAL "$ERR_TXT" $4
    else
        func_exit_on_error $LINENO $EXIT_VAL "$ERR_TXT"
    fi
}

#**************************************************************************
# Function: func_format_name
# Parameters: <line number> <var pointer> <file number>
#**************************************************************************
function func_format_name()
{
    func_param_check $1 $FUNCNAME $# 3
    local __RESULTVAR=$2
    local NUMBER=$3
    local PADDING="0000"
    local FORMATTED_NAME=${PADDING:${#NUMBER}}$NUMBER

    if [[ "$__RESULTVAR" ]]; then
        eval $__RESULTVAR="'$FORMATTED_NAME'"
    else
        echo "$FORMATTED_NAME"
    fi
}

#**************************************************************************
# Function: func_last_line
# Parameters: <line number> <var pointer> <output text>
#**************************************************************************
function func_last_line()
{
    func_param_check $1 $FUNCNAME $# 3
    local __RESULTVAR=$2
    local OLDIFS=$IFS
    IFS=$'\n'
    declare -a LINES=($3)
    IFS=$OLDIFS
    local LINE=${LINES[${#LINES[@]}-1]}

    if [[ "$__RESULTVAR" ]]; then
        eval $__RESULTVAR="'$LINE'"
    else
        echo "$LINE"
    fi
}

#**************************************************************************
# Function: func_exit_on_gimp_script_error
# Parameters: <line number> <exit check number> <error text> <output text> [<user exit number>]
#**************************************************************************
function func_exit_on_gimp_script_error()
{
    func_param_check $1 $FUNCNAME $# 4
    local LASTLINE
    func_last_line $LINENO LASTLINE "$4"

    if [ "$LASTLINE" != "batch command executed successfully" ]; then
        echo -e "$(date +%s):$0:$T_MODEL:::Gimp Error Log\n\n$4\n\n" 1>&2
        if [ $# -gt 4 ]; then
            func_exit_on_error $LINENO $5 "$3"
        else
            func_exit_on_error $LINENO $E_GIMP "$3"
        fi
    else
        func_echo_spin $LINENO $V_NOISY "$LASTLINE"

        if [ $# -gt 4 ]; then
            func_exit_on_error $LINENO $2 "$3" $5
        else
            func_exit_on_error $LINENO $2 "$3"
        fi
    fi
}

#**************************************************************************
# Function: func_gimp_crop
# Parameters: <line number> <files> <x1 number> <y1 number> <x2 number> <y2 number> [<user exit number>]
#**************************************************************************
function func_gimp_crop()
{
    func_param_check $1 $FUNCNAME $# 6
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-crop \"$2\" $3 $4 $5 $6)" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed crop:$2"

    if [ $# -gt 6 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $7
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_to_rgb
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_to_rgb()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-rgb \"$2\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed RGB:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_dos
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_dos()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-indexed \"$2\" \"ttd-newgrf-dos\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Index DOS:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_cc1
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_cc1()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-indexed \"$2\" \"ttd-newgrf-cc1only\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Index CC1:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_cc2
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_cc2()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-indexed \"$2\" \"ttd-newgrf-cc2only\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Index CC2:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_32bpp_cc1
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_32bpp_cc1()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-indexed \"$2\" \"ttd-newgrf-32cc1only\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Index CC1:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_32bpp_cc2
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_32bpp_cc2()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-indexed \"$2\" \"ttd-newgrf-32cc2only\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Index CC2:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_cc1
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_cc1()
{
    func_param_check $1 $FUNCNAME $# 2

    if [ $# -gt 2 ]; then
        func_gimp_indexed_cc1 $LINENO "$2" $3
        func_gimp_to_rgb $LINENO "$2" $3
        func_gimp_indexed_dos $LINENO "$2" $3
    else
        func_gimp_indexed_cc1 $LINENO "$2"
        func_gimp_to_rgb $LINENO "$2"
        func_gimp_indexed_dos $LINENO "$2"
    fi
}

#**************************************************************************
# Function: func_gimp_cc2
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_cc2()
{
    func_param_check $1 $FUNCNAME $# 2

    if [ $# -gt 2 ]; then
        func_gimp_indexed_cc2 $LINENO "$2" $3
        func_gimp_to_rgb $LINENO "$2" $3
        func_gimp_indexed_dos $LINENO "$2" $3
    else
        func_gimp_indexed_cc2 $LINENO "$2"
        func_gimp_to_rgb $LINENO "$2"
        func_gimp_indexed_dos $LINENO "$2"
    fi
}

#**************************************************************************
# Function: func_gimp_32bpp_cc1
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_32bpp_cc1()
{
    func_param_check $1 $FUNCNAME $# 2

    if [ $# -gt 2 ]; then
        func_gimp_indexed_32bpp_cc1 $LINENO "$2" $3
        func_gimp_to_rgb $LINENO "$2" $3
        func_gimp_indexed_dos $LINENO "$2" $3
    else
        func_gimp_indexed_32bpp_cc1 $LINENO "$2"
        func_gimp_to_rgb $LINENO "$2"
        func_gimp_indexed_dos $LINENO "$2"
    fi
}

#**************************************************************************
# Function: func_gimp_32bpp_cc2
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_32bpp_cc2()
{
    func_param_check $1 $FUNCNAME $# 2

    if [ $# -gt 2 ]; then
        func_gimp_indexed_32bpp_cc2 $LINENO "$2" $3
        func_gimp_to_rgb $LINENO "$2" $3
        func_gimp_indexed_dos $LINENO "$2" $3
    else
        func_gimp_indexed_32bpp_cc2 $LINENO "$2"
        func_gimp_to_rgb $LINENO "$2"
        func_gimp_indexed_dos $LINENO "$2"
    fi
}

#**************************************************************************
# Function: func_gimp_merge
# Parameters: <line number> <file 1> <file 2> [<user exit number>]
#**************************************************************************
function func_gimp_merge()
{
    func_param_check $1 $FUNCNAME $# 3
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-merge-alpha \"$2\" \"$3\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Merge:$2 $3"

    if [ $# -gt 3 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $4
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_flatten
# Parameters: <line number> <file 1> <file 2> [<user exit number>]
#**************************************************************************
function func_gimp_flatten()
{
    func_param_check $1 $FUNCNAME $# 3
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-merge-images \"$2\" \"$3\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Flatten:$2 $3"

    if [ $# -gt 3 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $4
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_noaction
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_noaction()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-convert-indexed \"$2\" \"ttd-noaction\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Index Noaction:$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_indexed_dos_noaction
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_indexed_dos_noaction()
{
    func_param_check $1 $FUNCNAME $# 2

    if [ $# -gt 2 ]; then
        func_gimp_indexed_dos $LINENO "$2" $3
        func_gimp_to_rgb $LINENO "$2" $3
        func_gimp_indexed_noaction $LINENO "$2" $3
        func_gimp_to_rgb $LINENO "$2" $3
        func_gimp_indexed_dos $LINENO "$2" $3
    else
        func_gimp_indexed_dos $LINENO "$2"
        func_gimp_to_rgb $LINENO "$2"
        func_gimp_indexed_noaction $LINENO "$2"
        func_gimp_to_rgb $LINENO "$2"
        func_gimp_indexed_dos $LINENO "$2"
    fi
}

#**************************************************************************
# Function: func_gimp_scale
# Parameters: <line number> <files> <x divisor> <y divisor> [<user exit number>]
#**************************************************************************
function func_gimp_scale()
{
    func_param_check $1 $FUNCNAME $# 5
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-image-scale-full \"$2\" $3 $4 $5)" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Scale:\$2 $3 $4"

    if [ $# -gt 5 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $6
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_sharpen
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_sharpen()
{
    func_param_check $1 $FUNCNAME $# 2
    local RADIUS=5
    local AMOUNT=0.5
    local THRESHOLD=0
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-sharpen \"$2\" $RADIUS $AMOUNT $THRESHOLD)" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Sharpen:\$2 $RADIUS $AMOUNT $THRESHOLD"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
# Function: func_gimp_levels_stretch
# Parameters: <line number> <files> [<user exit number>]
#**************************************************************************
function func_gimp_levels_stretch()
{
    func_param_check $1 $FUNCNAME $# 2
    local GIMP_OUTPUT="$(gimp -i -g $TMP/$GIMPRC -b "(batch-sharpen \"$2\")" -b "(gimp-quit 0)" 2>&1)"
    local EXIT_VAL=$?
    local ERR_TXT="Failed Levels Stretch:\$2"

    if [ $# -gt 2 ]; then
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT" $3
    else
        func_exit_on_gimp_script_error $LINENO $EXIT_VAL "$ERR_TXT" "$GIMP_OUTPUT"
    fi
}

#**************************************************************************
#
#                                 MAIN CODE
#
#**************************************************************************

# Check that a model name has been provided as a parameter to the script
if [ $# -eq 0 ]; then
    func_exit_on_error $LINENO 1 "Usage:$0 <model-name>" $E_USAGE
fi

func_echo_spin $LINENO $V_START "Post-Processing: $1"

# Check that the provided source path exists
func_echo_spin $LINENO $V_NOISY "RENDERED: $RENDERED"
func_chkdir $LINENO $RENDERED "RENDERED source path does not exist:$RENDERED" $E_RENDERED

# Check that the provided destination path exists
func_echo_spin $LINENO $V_NOISY "ENGINES: $ENGINES"
func_chkdir $LINENO $ENGINES "ENGINES directory does not exist:$ENGINES" $E_ENGINES

# Check that the provided gimp sript path exists
func_echo_spin $LINENO $V_NOISY "SCMDIR: $SCMDIR"
func_chkdir $LINENO $SCMDIR "SCMDIR directory does not exist:$SCMDIR" $E_SCMDIR

# Check that the provided gimp palette path exists
func_echo_spin $LINENO $V_NOISY "GPLDIR: $GPLDIR"
func_chkdir $LINENO $GPLDIR "GPLDIR directory does not exist:$GPLDIR" $E_GPLDIR

# Define, create and check the paths
func_concat_path $LINENO SRC $RENDERED $1 $E_SRC

func_echo_spin $LINENO $V_NOISY "SRC: $SRC"
func_chkdir $LINENO $SRC "SRC directory does not exist:$SRC" $E_SRC

func_echo_spin $LINENO $V_NOISY "PCS: $PCS"
func_chkdir $LINENO $PCS "PCS directory does not exist$PCS" $E_PCS

func_echo_spin $LINENO $V_MODERATE "Removing previous ..."

func_concat_path $LINENO DST $ENGINES $1 $E_DST
func_remove $LINENO $DST $E_RM_DST
func_concat_path $LINENO TMP $TEMPORARY $1 $E_TMP
func_remove $LINENO $TMP $E_RM_TMP

func_echo_spin $LINENO $V_MODERATE "Creating directories ..."

func_echo_spin $LINENO $V_NOISY "DST: $DST"
func_mkdir $LINENO $DST $E_MK_DST
func_chkdir $LINENO $DST "DST directory does not exist:$DST" $E_DST

func_echo_spin $LINENO $V_NOISY "TMP: $TMP"
func_mkdir $LINENO $TMP $E_MK_TMP
func_chkdir $LINENO $TMP "TMP directory does not exist:$TMP" $E_TMP

# Define variables and make sub-directories
func_concat_path $LINENO POSTCC1 $TMP "1cc_mask"
func_mkdir $LINENO $POSTCC1 $E_MK_POSTCC1
func_concat_path $LINENO POSTCC2 $TMP "2cc_mask"
func_mkdir $LINENO $POSTCC2 $E_MK_POSTCC2

func_concat_path $LINENO POST32CC1 $TMP "32bpp_1cc_mask"
func_mkdir $LINENO $POST32CC1 $E_MK_POSTCC1
func_concat_path $LINENO POST32CC2 $TMP "32bpp_2cc_mask"
func_mkdir $LINENO $POST32CC2 $E_MK_POSTCC2

func_concat_path $LINENO POSTMSK8 $TMP "8bpp_mask"
func_mkdir $LINENO $POSTMSK8 $E_MK_POSTMSK8
func_concat_path $LINENO POSTMSK32 $TMP "32bpp_mask"
func_mkdir $LINENO $POSTMSK32 $E_MK_POSTMSK32

func_concat_path $LINENO SRCIMG8 $SRC "8bpp_no_shadow"
func_concat_path $LINENO SRCMSK8CC1 $SRC "1cc_mask"
func_concat_path $LINENO SRCMSK8CC2 $SRC "2cc_mask"

func_concat_path $LINENO SRCIMG32 $SRC "32bpp_shadow"
func_concat_path $LINENO SRCMSK32 $TMP "32bpp_mask"
func_mkdir $LINENO $SRCMSK32 $E_MK_SRCMASK32
func_concat_path $LINENO SRCPCHS $SRC "32bpp_no_shadow"

func_concat_path $LINENO DST8 $DST "8bpp"
func_mkdir $LINENO $DST8 $E_MK_DST8

func_concat_path $LINENO DST32 $DST "32bpp"
func_mkdir $LINENO $DST32 $E_MK_DST32
func_concat_path $LINENO DSTMSK32 $DST "32bpp_mask"
func_mkdir $LINENO $DSTMSK32 $E_MK_DSTMSK32
func_concat_path $LINENO DSTPCHS $DST "gui"
func_mkdir $LINENO $DSTPCHS $E_MK_DSTPCHS

# Create temporary GIMPRC
func_echo_spin $LINENO $V_MODERATE "Creating gimprc ..."
func_echo_spin $LINENO $V_NOISY "GIMPRC: $TMP/$GIMPRC"

cat > $TMP/$GIMPRC << EOF
(script-fu-path "\${gimp_dir}/scripts:\${gimp_data_dir}/scripts:$SCMDIR")
(palette-path "\${gimp_dir}/palettes:\${gimp_data_dir}/palettes:$GPLDIR")
EOF
func_exit_on_error $LINENO $? "Failed creating gimprc:$TMP/$GIMPRC" $E_GIMPRC

func_echo_spin $LINENO $V_MODERATE "Copy rendered images..."

# Copy rendered files for post-processing
for ((COUNT=1; COUNT<=$SPRITES; COUNT++))
do
        func_format_name $LINENO NAME $COUNT
	# Copy to 8 bit files
	func_copy $LINENO "$SRCIMG8/$NAME.$EXT" "$DST8/$NAME$INS$I4X.$EXT" $E_CP_REN_1
	# Copy to 8 bit mask files
	func_copy $LINENO "$SRCMSK8CC1/$NAME.$EXT" "$POSTCC1/$NAME$INS$I4X$MASK.$EXT" $E_CP_REN_2
        func_copy $LINENO "$SRCMSK8CC1/$NAME.$EXT" "$POST32CC1/$NAME$INS$I4X$MASK.$EXT" $E_CP_REN_2
	func_copy $LINENO "$SRCMSK8CC2/$NAME.$EXT" "$POSTCC2/$NAME$INS$I4X$MASK.$EXT" $E_CP_REN_3
        func_copy $LINENO "$SRCMSK8CC2/$NAME.$EXT" "$POST32CC2/$NAME$INS$I4X$MASK.$EXT" $E_CP_REN_3
	# Copy to 32 bit files
	func_copy $LINENO "$SRCIMG32/$NAME.$EXT" "$DST32/$NAME$INS$I4X.$EXT" $E_CP_REN_4
	# Copy to purchase files
	if [ $COUNT -eq "3" ] || [ $COUNT -eq "7" ] ; then
		func_copy $LINENO "$SRCPCHS/$NAME.$EXT" "$DSTPCHS/$NAME$INS32$INS$I1X.$EXT" $E_CP_REN_5
	fi
done

func_copy $LINENO "$PCS/blank*.$EXT" "$DSTPCHS/"

#func_echo_spin $LINENO $V_MODERATE "Crop to normal dimensions..."

# Crop all
#func_gimp_crop $LINENO "$DST8/*$INS$I4X.$EXT" $CROPX1 $CROPY1 $CROPX2 $CROPY2 $E_CROP_1
#func_gimp_crop $LINENO "$POSTCC1/*$INS$I4X$MASK.$EXT" $CROPX1 $CROPY1 $CROPX2 $CROPY2 $E_CROP_2
#func_gimp_crop $LINENO "$POSTCC2/*$INS$I4X$MASK.$EXT" $CROPX1 $CROPY1 $CROPX2 $CROPY2 $E_CROP_3
#func_gimp_crop $LINENO "$DST32/*$INS$I4X.$EXT" $CROPX1 $CROPY1 $CROPX2 $CROPY2 $E_CROP_4
#func_gimp_crop $LINENO "$DSTPCHS/*$INS32$INS$I1X.$EXT" $CROPX1 $CROPY1 $CROPX2 $CROPY2 $E_CROP_5

func_echo_spin $LINENO $V_MODERATE "Convert cc1 masks ..."

# Convert 8 bit mask files to OTTD 8 bit cc1 palette
func_gimp_cc1 $LINENO "$POSTCC1/*$INS$I4X$MASK.$EXT" $E_CC1
func_gimp_32bpp_cc1 $LINENO "$POST32CC1/*$INS$I4X$MASK.$EXT" $E_CC1

func_echo_spin $LINENO $V_MODERATE "Convert cc2 masks ..."

# Convert 8 bit mask files to OTTD 8 bit cc2 palette
func_gimp_cc2 $LINENO "$POSTCC2/*$INS$I4X$MASK.$EXT" $E_CC2
func_gimp_32bpp_cc2 $LINENO "$POST32CC2/*$INS$I4X$MASK.$EXT" $E_CC2

func_echo_spin $LINENO $V_MODERATE "Merge cc1 & cc2 masks ..."

# Merge 8 bit cc1 mask with 8 bit cc2 mask
func_copy $LINENO "$POSTCC1/*$INS$I4X$MASK.$EXT" "$POSTMSK8/" $E_CP_MASK8

for ((COUNT=1; COUNT<=$SPRITES; COUNT++))
do
        func_format_name $LINENO NAME $COUNT
        func_gimp_merge $LINENO "$POSTMSK8/$NAME$INS$I4X$MASK.$EXT" "$POSTCC2/$NAME$INS$I4X$MASK.$EXT" $E_MG_MASK8
done

func_echo_spin $LINENO $V_MODERATE "Merge 32bpp masks ..."

# Merge 8 bit cc1 mask with 8 bit cc2 mask for 32bpp

for ((COUNT=1; COUNT<=$SPRITES; COUNT++))
do
        func_format_name $LINENO NAME $COUNT
	func_copy $LINENO "$PCS/magic.$EXT" "$POSTMSK32/$NAME$INS$I4X$MASK.$EXT" $E_CP_MAGIC
        func_gimp_merge $LINENO "$POSTMSK32/$NAME$INS$I4X$MASK.$EXT" "$POST32CC1/$NAME$INS$I4X$MASK.$EXT" $E_MG_MASK32
        func_gimp_merge $LINENO "$POSTMSK32/$NAME$INS$I4X$MASK.$EXT" "$POST32CC2/$NAME$INS$I4X$MASK.$EXT" $E_MG_MASK32
done

func_echo_spin $LINENO $V_MODERATE "Merge 8bpp masks ..."

# Merge 8 bit cc1 mask with 8 bit cc2 mask
for ((COUNT=1; COUNT<=$SPRITES; COUNT++))
do
        func_format_name $LINENO NAME $COUNT
        func_gimp_flatten $LINENO "$DST8/$NAME$INS$I4X.$EXT" "$POSTMSK8/$NAME$INS$I4X$MASK.$EXT" $E_MG_8BPP
done

func_echo_spin $LINENO $V_MODERATE "Convert to 8 bit files ..."

# Convert 8 bit files to OTTD 8 bit palette
func_gimp_indexed_dos_noaction $LINENO "$DST8/*$INS$I4X.$EXT" $E_INDEX_8BPP

func_echo_spin $LINENO $V_MODERATE "Convert 32bpp masks ..."

# Convert mask files to OTTD 8 bit palette
func_gimp_indexed_dos $LINENO "$POSTMSK32/*$INS$I4X$MASK.$EXT" $E_INDEX_MASK32
func_copy $LINENO "$POSTMSK32/*$INS$I4X$MASK.$EXT" "$DSTMSK32/" $E_CP_MASK32

func_echo_spin $LINENO $V_MODERATE "Copy cropped and converted image to all zoom levels ..."

# Copy cropped files to other zoom levels
for ((COUNT=1; COUNT<=$SPRITES; COUNT++))
do
        func_format_name $LINENO NAME $COUNT
	# Copy to 8 bit files
	func_copy $LINENO "$DST8/$NAME$INS$I4X.$EXT" "$DST8/$NAME$INS$I2X.$EXT" $E_CP_ZOOM_1
	func_copy $LINENO "$DST8/$NAME$INS$I4X.$EXT" "$DST8/$NAME$INS$I1X.$EXT" $E_CP_ZOOM_2
	# Copy to 32 bit files
	func_copy $LINENO "$DST32/$NAME$INS$I4X.$EXT" "$DST32/$NAME$INS$I2X.$EXT" $E_CP_ZOOM_3
	func_copy $LINENO "$DST32/$NAME$INS$I4X.$EXT" "$DST32/$NAME$INS$I1X.$EXT" $E_CP_ZOOM_4
	# Copy to 32 bit mask files
	func_copy $LINENO "$DSTMSK32/$NAME$INS$I4X$MASK.$EXT" "$DSTMSK32/$NAME$INS$I2X$MASK.$EXT" $E_CP_ZOOM_5
	func_copy $LINENO "$DSTMSK32/$NAME$INS$I4X$MASK.$EXT" "$DSTMSK32/$NAME$INS$I1X$MASK.$EXT" $E_CP_ZOOM_6
	# Copy to purchase files
	if [ $COUNT -eq "3" ] || [ $COUNT -eq "7" ] ; then
            func_copy $LINENO "$DST8/$NAME$INS$I4X.$EXT" "$DSTPCHS/$NAME$INS8$INS$I1X.$EXT" $E_CP_ZOOM_7
            func_copy $LINENO "$DSTMSK32/$NAME$INS$I4X$MASK.$EXT" "$DSTPCHS/$NAME$INS32$INS$I1X$MASK.$EXT" $E_CP_ZOOM_8
	fi
done

func_echo_spin $LINENO $V_MODERATE "Scale all zoom levels ..."

# Scale the 8 bit zoom files
func_gimp_scale $LINENO "$DST8/*$INS$I4X.$EXT" $SCALE4X $SCALE4X $METHOD4X $E_SCALE_1
func_gimp_scale $LINENO "$DST8/*$INS$I2X.$EXT" $SCALE2X $SCALE2X $METHOD2X $E_SCALE_2
func_gimp_scale $LINENO "$DST8/*$INS$I1X.$EXT" $SCALE1X $SCALE1X $METHOD1X $E_SCALE_3
func_gimp_sharpen $LINENO "$DST8/*$INS$I1X.$EXT" $E_SHARPEN_1
#func_gimp_levels_stretch $LINENO "$DST8/*$INS$I1X.$EXT" $E_LEVELS_1
# Scale the 32 bit zoom files
func_gimp_scale $LINENO "$DST32/*$INS$I4X.$EXT" $SCALE4X $SCALE4X $METHOD4X $E_SCALE_4
func_gimp_scale $LINENO "$DSTMSK32/*$INS$I4X$MASK.$EXT" $SCALE4X $SCALE4X $METHOD4X $E_SCALE_5
func_gimp_scale $LINENO "$DST32/*$INS$I2X.$EXT" $SCALE2X $SCALE2X $METHOD2X $E_SCALE_6
func_gimp_scale $LINENO "$DSTMSK32/*$INS$I2X$MASK.$EXT" $SCALE2X $SCALE2X $METHOD2X $E_SCALE_7
func_gimp_scale $LINENO "$DST32/*$INS$I1X.$EXT" $SCALE1X $SCALE1X $METHOD1X $E_SCALE_8
func_gimp_scale $LINENO "$DSTMSK32/*$INS$I1X$MASK.$EXT" $SCALE1X $SCALE1X $METHOD1X $E_SCALE_9
func_gimp_sharpen $LINENO "$DST32/*$INS$I1X.$EXT" $E_SHARPEN_2
#func_gimp_levels_stretch $LINENO "$DST32/*$INS$I1X.$EXT" $E_LEVELS_2
# Scale the purchase sprites
func_gimp_scale $LINENO "$DSTPCHS/*$INS$I1X.$EXT" $SCALE1X $SCALE1X $METHOD1X $E_SCALE_10
func_gimp_scale $LINENO "$DSTPCHS/*$INS$I1X$MASK.$EXT" $SCALE1X $SCALE1X $METHOD1X $E_SCALE_10
func_gimp_sharpen $LINENO "$DSTPCHS/*$INS$I1X.$EXT" $E_SHARPEN_3
#func_gimp_levels_stretch $LINENO "$DSTPCHS/*$INS$I1X.$EXT" $E_LEVELS_3

# Cleanup
func_echo_spin $LINENO $V_MODERATE "Removing temporary files ..."
func_remove $LINENO $TMP $E_RM_TMP

func_echo_spin $LINENO $V_STOP "Done."
