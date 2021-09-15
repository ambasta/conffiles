#!/bin/bash
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
systemctl --user stop pipewire pipewire-pulse pipewire-media-session
systemctl --user stop xdg-desktop-portal xdg-desktop-portal-wlr
systemctl --user start pipewire pipewire-media-session pipewire-pulse
systemctl --user start xdg-desktop-portal mako waybar
