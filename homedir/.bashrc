# export XDG_CONFIG_HOME=$HOME/.config
# export XDG_CACHE_HOME=$HOME/.cache
source /etc/profile
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

export PATH=$PATH:/home/amitprakash/.local/bin:$(yarn global bin)
export SSH_AUTH_SOCK=/run/user/$(id -u)/gcr/ssh
alias awsauth='source /home/amitprakash/.virtualenvs/awsauth/bin/activate'
alias awsshell='source /home/amitprakash/.virtualenvs/awsshell/bin/activate'
alias pyshell='source /home/amitprakash/.virtualenvs/pyshell/bin/activate'

# keychain ~/.ssh/id_rsa
eval $(keychain --agents ssh --eval id_rsa)
eval $(keychain --eval --agents gpg F0B27A3B6D7CF774)
. ~/.keychain/${HOSTNAME}-sh
. ~/.keychain/${HOSTNAME}-sh-gpg

# Default components are loaded directly
# Default components are: pkcs11, secrets, ssh
# eval $(gnome-keyring-daemon --start)
# export SSH_AUTH_SOCK

# source $HOME/.config/environment.d/00-envvars.conf
# source $HOME/.config/environment.d/01-wayland.conf

# PS1='\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
export PATH=$PATH:/home/amitprakash/.cargo/bin

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

eval $(systemctl --user show-environment | sed 's/^/export /')

export PATH="$(yarn global bin):$PATH"

source /home/amitprakash/.bash_completions/llm_benchmark.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/amitprakash/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/amitprakash/conda/etc/profile.d/conda.sh" ]; then
        . "/home/amitprakash/conda/etc/profile.d/conda.sh"
    else
        export PATH="/home/amitprakash/conda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

