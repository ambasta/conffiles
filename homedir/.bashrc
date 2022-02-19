export PATH="$PATH:$(yarn global bin):$HOME/.local/bin"
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

alias awsauth='source /home/amitprakash/.virtualenvs/awsauth/bin/activate'
alias awsshell='source /home/amitprakash/.virtualenvs/awsshell/bin/activate'
alias pyshell='source /home/amitprakash/.virtualenvs/pyshell/bin/activate'
alias chrome='/home/amitprakash/chrome/chrome --ozone-platform=wayland --enable-features=UseOzonePlatform'

# Default components are loaded directly
# Default components are: pkcs11, secrets, ssh
eval $(gnome-keyring-daemon --start)
export SSH_AUTH_SOCK

source $HOME/.config/environment.d/00-envvars.conf
source $HOME/.config/environment.d/01-wayland.conf

PS1='\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '
