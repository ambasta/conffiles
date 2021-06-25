export N_PREFIX="$HOME/.local"
export GPG_TTY=$(tty)

export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export _JAVA_AWT_WM_NONREPARENTING=1

alias awsauth='source /home/amitprakash/.virtualenvs/aws/bin/activate'
alias pyshell='source /home/amitprakash/.virtualenvs/pyshell/bin/activate'
alias chrome='google-chrome-stable --ozone-platform=wayland --enable-features=UseOzonePlatform'

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
# [ -f /home/amitprakash/.config/yarn/global/node_modules/tabtab/.completions/serverless.bash ] && . /home/amitprakash/.config/yarn/global/node_modules/tabtab/.completions/serverless.bash
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
# [ -f /home/amitprakash/.config/yarn/global/node_modules/tabtab/.completions/sls.bash ] && . /home/amitprakash/.config/yarn/global/node_modules/tabtab/.completions/sls.bash
# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
# [ -f /home/amitprakash/.config/yarn/global/node_modules/tabtab/.completions/slss.bash ] && . /home/amitprakash/.config/yarn/global/node_modules/tabtab/.completions/slss.bash

eval `keychain -q --eval --agents gpg,ssh id_rsa F4ED5371C992A1D4C487C307F0B27A3B6D7CF774`

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
