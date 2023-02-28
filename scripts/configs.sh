#!/usr/bin/env bash

#===========#
# user-vars # CHANGE
#===========#

# can optionally change the prompt message rofi shows
prompt_message="Configs"

# items
items=(
    dunst="Dunst"
    i3="i3"
    polybar="Polybar"
    picom="Picom"
    kitty="Kitty"
    chemacs="Chemacs"
)

# configs for the items
# these variable names and order should match the ones in the items array
configs=(
    dunst="$HOME/.config/dunst/dunstrc"
    i3="$HOME/.config/i3/config"
    polybar="$HOME/.config/polybar/config"
    picom="$HOME/.config/picom/picom.conf"
    kitty="$HOME/.config/kitty/kitty.conf"
    chemacs="$HOME/.config/chemacs/profiles.el"
)

#=============#
# script-vars #  DONT CHANGE
#=============#

directory=$1
chemacs_directory=$2
config=$3
use_daemon=$4
vertical_offset=$5
rofi_command="rofi -no-fixed-num-lines -location 2 -yoffset $vertical_offset -theme $directory/configs/$config"

# error message
err_msg() {
    rofi -theme "$directory/configs/error.rasi" -e "$1"
}

# checks user config file locations
set_configs_directory() {
    if [[ -f "$HOME/.emacs-profile" ]]; then
        config_directory=$HOME
        profile=".emacs-profile"
    else
        config_directory=$chemacs_directory
        profile="profile"
    fi
}

# create the main menu for passing into rofi
assemble_menu() {
    declare -A menu
    declare -a order
    # assemble menu items from items array
    for item in "${items[@]}"; do
        menu+=(["${item%=*}"]="${item#*=}")
        order+=( "${item%=*}" )
    done
    for item in "${order[@]}"; do
        echo "${menu["$item"]}"
    done
}

# launch the rofi menu
selection="$(assemble_menu | $rofi_command -no-click-to-exit -p "$prompt_message" -dmenu)"

# check if selection was empty
if [[ -z "$selection" ]]; then
    exit 0
# if selection not empty, run the command for the selection
else
    # get index of selected command
    for i in "${!items[@]}"; do
        if [[ "${items[$i]#*=}" = "$selection" ]]; then
            index=$i
        fi
    done

    # execute command for selection
    if [[ -f "${configs[index]#*=}" ]]; then
        set_configs_directory
        set -- $(<"$config_directory/$profile")
        if [[ "$use_daemon" == "y" ]]; then
            emacsclient -c -s "$1" "${configs[index]#*=}" -a emacs >/dev/null 2>/dev/null &
        else
            emacs "${configs[index]#*=}" &
        fi
    fi
fi
