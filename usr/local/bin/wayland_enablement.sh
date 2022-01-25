#!/bin/sh

export CLUTTER_BACKEND=wayland
export EGL_PLATFORM=wayland
export GDK_BACKEND=wayland
export GDK_GL=gles
# export MESA_GLSL_CACHE_DISABLE=true
export DISABLE_RTKIT=1
export MOZ_ENABLE_WAYLAND=1
export MOZ_GTK_TITLEBAR_DECORATION=client
export NO_AT_BRIDGE=1
export SDL_VIDEODRIVER=wayland
export VDPAU_DRIVER=radeonsi
export XKB_DEFAULT_LAYOUT=us
export WLR_RENDERER=vulkan
