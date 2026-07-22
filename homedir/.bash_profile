# Login shells: defer everything to .bashrc so all user config lives in one file.
if [[ -f ~/.bashrc ]]; then
  . ~/.bashrc
fi
