#!/bin/bash
# Symlink every file under homedir/ into $HOME, preserving relative paths.
# Only paths recorded in this installer's manifest are ever pruned.
set -euo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/conffiles
MANIFEST="$STATE_DIR/user-install.links"

mkdir -p "$STATE_DIR"
declare -A managed=()

while IFS= read -r -d '' file; do
	rel=${file#"$DIR/homedir/"}
	target="$HOME/$rel"
	managed["$target"]=$file

	# Never recursively remove user data to make room for a managed file.
	if [ -d "$target" ] && [ ! -L "$target" ]; then
		printf 'user_install: refusing to replace directory: %s\n' "$target" >&2
		exit 1
	fi

	mkdir -p "$(dirname "$target")"
	ln -sfn "$file" "$target"
done < <(find "$DIR/homedir" -type f -print0)

# Remove only a destination that a previous run recorded, that the current repo
# no longer manages, and that is still the exact symlink we installed. This
# deliberately avoids crawling or cleaning unrelated parts of $HOME.
if [ -f "$MANIFEST" ] && [ ! -L "$MANIFEST" ]; then
	while IFS=$'\t' read -r old_target old_source; do
		case "$old_target" in
		"$HOME"/*) ;;
		*) continue ;;
		esac
		[ -n "$old_source" ] || continue
		[ "${managed[$old_target]+present}" = present ] && continue
		if [ -L "$old_target" ] && [ "$(readlink "$old_target")" = "$old_source" ]; then
			rm -v -- "$old_target"
		fi
	done <"$MANIFEST"
fi

tmp=$(mktemp "$STATE_DIR/user-install.links.XXXXXX")
for target in "${!managed[@]}"; do
	printf '%s\t%s\n' "$target" "${managed[$target]}"
done | LC_ALL=C sort >"$tmp"
chmod 600 "$tmp"
mv -f "$tmp" "$MANIFEST"
