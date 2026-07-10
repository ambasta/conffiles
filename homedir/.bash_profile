# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bash_profile.pre.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bash_profile.pre.bash"

if [[ -f ~/.bashrc ]]; then
  . ~/.bashrc
fi

_saml2aws_bash_autocomplete() {
  local cur prev opts base
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts=$(${COMP_WORDS[0]} --completion-bash "${COMP_WORDS[@]:1:$COMP_CWORD}")
  COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
  return 0
}
complete -F _saml2aws_bash_autocomplete -o default saml2aws

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash"
