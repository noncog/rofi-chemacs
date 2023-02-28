#!/usr/bin/env bash

#===========#
# user-vars # CHANGE
#===========#

# this is only used if you do not use ~/.emacs-profiles.el and ~/.emacs-profile
# if you have a different $XDG_CONFIG_HOME then change this to match
chemacs_directory="$HOME/.config/chemacs"

# must set your install directory
directory="$HOME/.config/rofi/rofi-chemacs"

# set which command you want to use to launch, emacs or emacsclient and it's daemon.
use_daemon="n"

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
start_daemon=" Start Daemon"
kill_emacs=" Kill Emacs"

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
    echo $configurations
    echo $set_default
    echo $start_daemon
    echo $kill_emacs
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

kill_all_emacs() {
# can kill both client and daemon

    # check for daemon usage
    if [[ "$use_daemon" == "y" ]]; then
        # check if using home directory configs
        if [[ -f "$HOME/.emacs-profile" ]]; then
            set -- $(<"$HOME/.emacs-profile")
            # if kill succesful, return
            if emacsclient -s "$1" -e "(kill-emacs)" >/dev/null 2>/dev/null; then
                return 0
            # if fail, run global kill command
            else
                killall emacs >/dev/null 2>/dev/null
            fi
        else
            # use chemacs directory config
            set -- $(<"$chemacs_directory/profile")
            # if kill succesful, return
            if emacsclient -s "$1" -e "(kill-emacs)" >/dev/null 2>/dev/null; then
                return 0
            # if fail, run global kill command
            else
                killall emacs >/dev/null 2>/dev/null
            fi
        fi
    fi
}

# main menu
selection="$(assemble_menu | $rofi_command -no-click-to-exit -p "$prompt_message" -dmenu)"

# if selection was empty, do nothing
if [[ -z "$selection" ]]; then
    exit 0
else
    # check for 'known' variable menu options
    case $selection in
    $default)
        if [[ "$use_daemon" == "y" ]]; then
            set_configs_directory
            set -- $(<"$config_directory/$profile")
            emacsclient -c -s "$1" -a emacs >/dev/null 2>/dev/null &
        else
            emacs &
        fi
        exit 0
    ;;
    $set_default)
        # set correct user config directory
        set_configs_directory
        # select new default profile from correct config file
        new_default="$(grep -Po '[^"]+(?=" . \()' $config_directory/profiles.el |  $rofi_command -no-click-to-exit -p "Default" -dmenu)"
        # check if selection was empty/canceled
        if [[ -z "$new_default" ]]; then
            exit 0
        else
            # stop emacs
            kill_all_emacs
            # set new default
            echo $new_default > "$config_directory/$profile"
        fi
        # relaunch daemon if using it, with new default profile
        if [[ "$use_daemon" == "y" ]]; then
            emacs --daemon
        fi
        exit 0
    ;;
    $configurations)
        # make sure configs script exists and run it
        if [[ -f "$directory/scripts/configs.sh" ]]; then
            bash "$directory/scripts/configs.sh" $directory $chemacs_directory $config $use_daemon $vertical_offset
        else
            err_msg "$configurations file not found."
        fi
        exit 0
    ;;
    $start_daemon)
        # daemon is launched using the default profile
        emacs --daemon
        exit 0
    ;;
    $kill_emacs)
        kill_all_emacs
        exit 0
    ;;
    esac

    # if no 'known' menu options launched, must be a profile, launch it using desired method

    # set correct user config directory
    set_configs_directory
    set -- $(<"$config_directory/$profile")
    # launch profile using desired method
    if [[ "$use_daemon" == "y" ]]; then
        emacsclient -c -s $selection -a "emacs --with-profile $selection" >/dev/null 2>/dev/null &
    else
        emacs --with-profile $selection &
    fi
fi
