#!/usr/bin/bash

#===========#
# user-vars # CHANGE
#===========#

# this is only used if you do not use ~/.emacs-profiles.el and ~/.emacs-profile
# if you have a different $XDG_CONFIG_HOME then change this to match
chemacs_directory="$HOME/.config/chemacs"

# must set your install directory
directory="$HOME/projects/rofi-chemacs"

# set which command you want to use
# these must be in opposition
use_emacs="n"
use_emacsclient="y"

# can optionally change the prompt message rofi shows
prompt_message="Emacs"

# distance from top of screen in pixels
vertical_offset=57

#=============#
# script-vars #  CAN CHANGE ICON GLYPHS, nothing else
#=============#

# define menu options
default=" Default"
set_default=" Set Default"
configurations=" Configs"
kill_emacs=" Kill Emacs"
start_daemon=" Start Daemon"

#=============#
# script-vars #  DONT CHANGE
#=============#

config="${0##*/}"; config="${config%.*}.rasi"
# to change location increase the -yoffset
rofi_command="rofi -no-fixed-num-lines -location 2 -yoffset $vertical_offset -theme $directory/configs/$config"

# error message
err_msg() {
    rofi -theme "$directory/configs/error.rasi" -e "$1"
}

# create the main menu for passing into rofi
assemble_menu() {
    echo $default
    if [[ -f "$HOME/.emacs-profiles" ]]; then
	grep -Po '[^"]+(?=" . \()' $HOME/.emacs-profiles.el
    else
	grep -Po '[^"]+(?=" . \()' $chemacs_directory/profiles.el
    fi
    echo $set_default
    echo $configurations
    echo $kill_emacs
    echo $start_daemon
}

kill_all_emacs() {
    # can kill both client and daemon
    if [[ "$use_emacs" == "y" ]] && [[ "$use_emacsclient" == "n" ]]; then
	killall emacs
    elif [[ "$use_emacs" == "n" ]] && [[ "$use_emacsclient" == "y" ]]; then
	if [[ -f "$HOME/.emacs-profile" ]]; then
	    set -- $(<"$HOME/.emacs-profile")
	    if emacsclient -s "$1" -e "(kill-emacs)" >/dev/null 2>/dev/null; then
		return
	    else
		killall emacs >/dev/null 2>/dev/null
	    fi	    
	else
	    set -- $(<"$chemacs_directory/profile")
	    if emacsclient -s "$1" -e "(kill-emacs)" >/dev/null 2>/dev/null; then
		return
	    else
		killall emacs >/dev/null 2>/dev/null
	    fi	    	    
	fi
    fi
}

# menu items
selection="$(assemble_menu | $rofi_command -no-click-to-exit -p "$prompt_message" -dmenu)"

# if selection was empty, do nothing
if [[ -z "$selection" ]]; then
    exit 0
else
    # check for known variable options
    case $selection in
	$default)
	    if [[ "$use_emacs" == "y" ]] && [[ "$use_emacsclient" == "n" ]]; then
		emacs &
	    elif [[ "$use_emacs" == "n" ]] && [[ "$use_emacsclient" == "y" ]]; then
		if [[ -f "$HOME/.emacs-profile" ]]; then
		    set -- $(<"$HOME/.emacs-profile")
		    emacsclient -c -s "$1" -a emacs >/dev/null 2>/dev/null &
		else
		    set -- $(<"$chemacs_directory/profile")
		    emacsclient -c -s "$1" -a emacs >/dev/null 2>/dev/null &
		fi
	    fi
	    exit 0
	;;
	$set_default)
	    if [[ -f "$HOME/.emacs-profile" ]]; then
		new_default="$(grep -Po '[^"]+(?=" . \()' $HOME/.emacs-profiles.el |  $rofi_command -no-click-to-exit -p "$prompt_message" -dmenu)"
		if [[ -z "$new_default" ]]; then
		    exit 0
		else
		    kill_all_emacs
		    echo $new_default > "$HOME/.emacs-profile"
		fi
	    else
		new_default="$(grep -Po '[^"]+(?=" . \()' $chemacs_directory/profiles.el |  $rofi_command -no-click-to-exit -p "$prompt_message" -dmenu)"
		if [[ -z "$new_default" ]]; then
		    exit 0
		else
		    kill_all_emacs
		    echo $new_default > $chemacs_directory/profile
		fi
	    fi
	    if [[ "$use_emacs" == "n" ]] && [[ "$use_emacsclient" == "y" ]]; then
		emacs --daemon
	    fi
	    exit 0
	;;
	$configurations)
	    if [[ -f "$directory/scripts/configs.sh" ]]; then
		bash "$directory/scripts/configs.sh" $directory $chemacs_directory $config $use_emacs $use_emacsclient $vertical_offset
	    else
		err_msg "$configurations file not found"
	    fi
	    exit 0
	;;
	$kill_emacs)
	    kill_all_emacs
	    exit 0    
	;;
	$start_daemon)
	    # daemon is launched using the default profile
	    emacs --daemon
	    exit 0
	;;
    esac
    
    # if no known variables launched, must be a profile, launch it using desired method.
    if [[ "$use_emacs" == "y" ]] && [[ "$use_emacsclient" == "n" ]]; then
	emacs --with-profile $selection &
    elif [[ "$use_emacs" == "n" ]] && [[ "$use_emacsclient" == "y" ]]; then
	if [[ -f "$HOME/.emacs-profile" ]]; then
	    set -- $(<"$HOME/.emacs-profile")
	else
	    set -- $(<"$chemacs_directory/profile")
	fi
	if [[ "$selection" == "$1" ]]; then
	    emacsclient -c -s $selection -a "emacs --with-profile $selection" >/dev/null 2>/dev/null &
	else
	    emacs --with-profile $selection &
	fi
    fi    
fi
