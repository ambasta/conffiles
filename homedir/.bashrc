export N_PREFIX="$HOME/.local"

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export _JAVA_AWT_WM_NONREPARENTING=1

alias awsauth='source /home/amitprakash/.virtualenvs/awsauth/bin/activate'
alias awsshell='source /home/amitprakash/.virtualenvs/awsshell/bin/activate'
alias pyshell='source /home/amitprakash/.virtualenvs/pyshell/bin/activate'
alias chrome='/home/amitprakash/chrome/chrome --ozone-platform=wayland --enable-features=UseOzonePlatform'

# eval $(gnome-keyring-daemon --start)
eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
# export PATH="$PATH:$(yarn global bin):$N_PREFIX/bin"

source $HOME/.config/environment.d/00-envvars.conf
source $HOME/.config/environment.d/01-wayland.conf
