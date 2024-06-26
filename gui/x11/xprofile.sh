#!/bin/sh

export XIM=nabi
export XIM_ARGS=
export XIM_PROGRAM="nabi"
export XMODIFIERS="@im=nabi"
export GTK_IM_MODULE=xim
export QT_IM_MODULE=xim

# gnupg keyring agent
# ensure it's started so SSH will work
# https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart
dbus-update-activation-environment --systemd DISPLAY
gpgconf --launch gpg-agent
export "SSH_AUTH_SOCK=/run/user/$(id -u)/gnupg/S.gpg-agent.ssh"

# Keyboard layouts switch (requires setxkbmap)
setxkbmap -model pc104 -layout us,ara -variant dvorak-l, -option grp:win_space_toggle caps:swapescape keypad:pointerkeys
#export TOUCHPAD_ACCEL_SPEED=0.6
#touchpad-accel-toggle -e

# Start the key deamon
sxhkd -m 1 -c $HOME/.config/sxhkd/sxhkdrc &
#  Restores the wallpaper
nitrogen --restore &
#  Start the network manger
nm-applet &
# Start the  clipboard manger
# copyq &
# sticky keys script
stickykeys &
# Start a new terminal with tmux
$TERMINAL -e tmux &
