#!/bin/sh

# Session
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway
export WLR_BACKEND=vulkan
export WLR_RENDERER=vulkan
export _JAVA_AWT_WM_NONREPARENTING=1
export CLUTTER_BACKEND=wayland
export DISABLE_RTKIT=1
export EGL_PLATFORM=wayland
export GDK_BACKEND=wayland
export GDK_GL=gles
export MOZ_ENABLE_WAYLAND=1
export MOZ_GTK_TITLEBAR_DECORATION=client
export NO_AT_BRIDGE=1
export SDL_VIDEODRIVER=wayland
export VDPAU_DRIVER=radeonsi
export XKB_DEFAULT_LAYOUT=us
export ELECTRON_OZONE_PLATFORM_HINT=auto

source /usr/local/bin/wayland_enablement.sh

# Every GUI app sway spawns inherits sway's stdout/stderr. Piping that to the
# journal (systemd-cat) therefore dumped all child chatter -- Firefox JS/cubeb
# warnings and the like -- into the journal tagged sway[...]. Send the whole
# session log to an ephemeral tmpfile on the runtime tmpfs instead, so the
# journal stays clean while the log is still there for debugging this boot.
exec sway "$@" >"${XDG_RUNTIME_DIR:-/tmp}/sway.log" 2>&1
