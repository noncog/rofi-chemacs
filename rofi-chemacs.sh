#!/usr/bin/bash

# TODO add a note that is only used for _ but otherwise the default profile file is found automatically and if it does not exist searchs here.
chemacs_directory="$HOME/.config/chemacs"

# must set your install directory
directory="$HOME/projects/rofi-chemacs"
# set which command you want to use.
use_emacs="n"
use_emacsclient="y" # these must be in opposition

emacsclient_default_options="-c -a emacs"
emacsclient_selected_profile_options="-c -a emacs"

directory="$HOME/projects/rofi-chemacs"
prompt_message="Emacs"
config="${0##*/}"; config="${config%.*}.rasi"
# to change location increase the -yoffset
rofi_command="rofi -no-fixed-num-lines -location 2 -yoffset 57 -theme $directory/configs/$config"          # rofi config for menu

# define menu options
default=" Default"
set_default=" Set Default"
configurations=" Configs"
kill_emacs=" Kill Emacs"
start_daemon=" Start Daemon"

# Error msg
err_msg() {
    rofi -theme "$directory/configs/error.rasi" -e "$1"
}

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
		    emacsclient -c -s "$1" -a emacs &
		else
		    set -- $(<"$chemacs_directory/profile")
		    emacsclient -c -s "$1" -a emacs &
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
		    set -- $(<"$HOME/.emacs-profile")
		    emacsclient -s "$1" -e "(kill-emacs)"
		    echo $new_default > "$HOME/.emacs-profile"
		fi
	    else
		new_default="$(grep -Po '[^"]+(?=" . \()' $chemacs_directory/profiles.el |  $rofi_command -no-click-to-exit -p "$prompt_message" -dmenu)"
		if [[ -z "$new_default" ]]; then
		    exit 0
		else
		    set -- $(<"$chemacs_directory/profile")
		    emacsclient -s "$1" -e "(kill-emacs)"
		    echo $new_default > $chemacs_directory/profile
		fi
	    fi
	    emacs --daemon	    
	    exit 0
	;;
	$configurations)
	    if [[ -f "$directory/scripts/configs.sh" ]]; then
		bash "$directory/scripts/configs.sh" $directory $chemacs_directory $config $use_emacs $use_emacsclient
	    else
		err_msg "$configurations file not found"
	    fi
	    exit 0
	;;
	$kill_emacs)
	    # kills both client and daemon
	    if [[ -f "$HOME/.emacs-profile" ]]; then
		set -- $(<"$HOME/.emacs-profile")
		emacsclient -s "$1" -e "(kill-emacs)"
	    else
		set -- $(<"$chemacs_directory/profile")
		emacsclient -s "$1" -e "(kill-emacs)"		
	    fi
	    #killall emacs
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
	    emacsclient -c -s $selection -a "emacs --with-profile $selection" &
	else
	    emacs --with-profile $selection &
	fi
    fi    
fi
