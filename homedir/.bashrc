# export XDG_CONFIG_HOME=$HOME/.config
# export XDG_CACHE_HOME=$HOME/.cache
source /etc/profile
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

userid="$(id -u)"
export SSH_AUTH_SOCK=/run/user/$userid/gcr/ssh

# keychain ~/.ssh/id_rsa
eval "$(keychain -q --agents ssh --eval id_rsa)"
eval "$(keychain -q --eval --agents gpg F0B27A3B6D7CF774)"
# shellcheck source=/home/amitprakash/.keychain/${HOSTNAME}-sh
source "/home/amitprakash/.keychain/${HOSTNAME}-sh"
# shellcheck source=/home/amitprakash/.keychain/${HOSTNAME}-sh-gpg
source "/home/amitprakash/.keychain/${HOSTNAME}-sh-gpg"

# source $HOME/.config/environment.d/00-envvars.conf
# source $HOME/.config/environment.d/01-wayland.conf

# PS1='\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '

eval "$(systemctl --user show-environment | sed 's/^/export /')"

# uv
yarn_binpath="$(yarn global bin)"
go_path=$HOME/.go
export GOPATH=$go_path
go_binpath=$go_path/bin
export PATH=$PATH:$yarn_binpath:$go_binpath:/home/amitprakash/.cargo/bin:/home/amitprakash/.local/bin
