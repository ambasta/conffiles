# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bashrc.pre.bash"

source /etc/profile

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export PYTHONDONTWRITEBYTECODE=1

export SSH_AUTH_SOCK="/run/user/$(id -u)/gcr/ssh"
eval "$(keychain -q --eval --extended sshk:id_rsa gpgk:F0B27A3B6D7CF774)"
source "${HOME}/.keychain/${HOSTNAME}-sh"

# Import the systemd user environment (sway session vars etc.), except PATH.
# show-environment shell-quotes values with spaces ($'...'), so eval each line.
while IFS= read -r line; do
  [[ $line == PATH=* ]] && continue
  eval "export $line"
done < <(systemctl --user show-environment)

export GOPATH="$HOME/.go"
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
export BUN_INSTALL="$HOME/.bun"

PATH="$PATH:$GOPATH/bin:$HOME/.cargo/bin:$HOME/.local/bin:$BUN_INSTALL/bin"
[[ -d "$HOME/.yarn/bin" ]] && PATH="$PATH:$HOME/.yarn/bin"
export PATH

GITHUB_TOKEN=$(gh auth token 2>/dev/null)
export GITHUB_TOKEN

# Machine-local secrets and overrides (untracked).
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bashrc.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bashrc.post.bash"

. "$HOME/.moon/bin/env"
