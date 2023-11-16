# export XDG_CONFIG_HOME=$HOME/.config
# export XDG_CACHE_HOME=$HOME/.cache
source /etc/profile

export PATH=$PATH:/home/amitprakash/.local/bin:$(yarn global bin)
export SSH_AUTH_SOCK=/run/user/$(id -u)/gcr/ssh
alias awsauth='source /home/amitprakash/.virtualenvs/awsauth/bin/activate'
alias awsshell='source /home/amitprakash/.virtualenvs/awsshell/bin/activate'
alias pyshell='source /home/amitprakash/.virtualenvs/pyshell/bin/activate'

# Default components are loaded directly
# Default components are: pkcs11, secrets, ssh
# eval $(gnome-keyring-daemon --start)
# export SSH_AUTH_SOCK

# source $HOME/.config/environment.d/00-envvars.conf
# source $HOME/.config/environment.d/01-wayland.conf

# PS1='\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
