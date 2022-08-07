#!/bin/bash

#===========#
# user-vars # CHANGE
#===========#

# can optionally change the prompt message rofi shows
prompt_message="configs"

# items
items=(
    dunst="Dunst"
    i3="i3"
    polybar="Polybar"
    picom="Picom"
    kitty="Kitty"
    chemacs="Chemacs"
    cogmacs="Cogmacs"
)

# configs for the items
# these variable names and order should match the ones in the items array
configs=(
    dunst="$HOME/.config/dunst/dunstrc"
    i3="$HOME/.config/i3/README.org"
    polybar="$HOME/.config/polybar/config"
    picom="$HOME/.config/picom/picom.conf"
    kitty="$HOME/.config/kitty/kitty.conf"
    chemacs="$HOME/.config/chemacs/profiles.el"
    cogmacs="$HOME/.config/cogmacs/README.org"
)

#=============#
# script-vars #  DONT CHANGE
#=============#

directory=$1
chemacs_directory=$2
config=$3
use_emacs=$4
use_emacsclient=$5
vertical_offset=$6
rofi_command="rofi -no-fixed-num-lines -location 2 -yoffset $vertical_offset -theme $directory/configs/$config"

# error message
err_msg() {
    rofi -theme "$directory/configs/error.rasi" -e "$1"
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
	if [[ "$use_emacs" == "y" ]] && [[ "$use_emacsclient" == "n" ]]; then
	    emacs "${configs[index]#*=}" &
	elif [[ "$use_emacs" == "n" ]] && [[ "$use_emacsclient" == "y" ]]; then
	    if [[ -f "$HOME/.emacs-profile" ]]; then
		set -- $(<"$HOME/.emacs-profile")
	    else
		set -- $(<"$chemacs_directory/profile")
	    fi
	    emacsclient -c -s "$1" "${configs[index]#*=}" -a emacs >/dev/null 2>/dev/null &
	fi
    else
	err_msg "$selection file not found."
    fi
fi
