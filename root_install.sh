#!/bin/bash
# Symlink etc/ and usr/ into the root filesystem. Run as root from the repo root.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

find etc usr -type f -print0 | while IFS= read -r -d '' file; do
	target="/$file"
	mkdir -p "$(dirname "$target")"
	ln -sfn "$(pwd)/$file" "$target"
done

# Prune symlinks into the repo whose source no longer exists.
REPO=$(pwd)
{ find /etc /usr/local -xtype l -print0 2>/dev/null || true; } | while IFS= read -r -d '' link; do
	case "$(readlink "$link")" in
	"$REPO"/*) rm -v "$link" ;;
	esac
done
