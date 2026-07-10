#!/bin/bash
# Symlink every file under homedir/ into $HOME, preserving relative paths.
# Also prunes symlinks left dangling by files removed from the repo.
set -euo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

find "$DIR/homedir" -type f -print0 | while IFS= read -r -d '' file; do
	rel=${file#"$DIR/homedir/"}
	target="$HOME/$rel"

	# A real directory in the way (not a symlink) must go before ln -sfn,
	# which would otherwise create the link *inside* it.
	if [ -d "$target" ] && [ ! -L "$target" ]; then
		rm -rf "$target"
	fi

	mkdir -p "$(dirname "$target")"
	ln -sfn "$file" "$target"
done

# Prune symlinks into the repo whose source no longer exists.
# find exits nonzero on unreadable dirs (e.g. rootless-container storage); that
# must not fail the script.
{ find "$HOME" -xdev -xtype l -print0 2>/dev/null || true; } | while IFS= read -r -d '' link; do
	case "$(readlink "$link")" in
	"$DIR"/*) rm -v "$link" ;;
	esac
done
