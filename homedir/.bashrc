export N_PREFIX="$HOME/.local"
export GPG_TTY=$(tty)

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export _JAVA_AWT_WM_NONREPARENTING=1

alias awsauth='source /home/amitprakash/.virtualenvs/aws/bin/activate'
alias pyshell='source /home/amitprakash/.virtualenvs/pyshell/bin/activate'
alias chrome='/home/amitprakash/chrome/chrome --ozone-platform=wayland --enable-features=UseOzonePlatform'

eval $(gnome-keyring-daemon --start)
export SSH_AUTH_SOCK
export PATH="$PATH:$(yarn global bin)"
export PATH="$PATH:$N_PREFIX/bin"
