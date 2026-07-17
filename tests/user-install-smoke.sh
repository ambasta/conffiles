#!/bin/bash
# Verify that user_install only touches destinations it explicitly manages.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'chmod -R u+rwX "$TMP" 2>/dev/null || true; rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
STATE_DIR="$TMP/state/conffiles"
MANIFEST="$STATE_DIR/user-install.links"
mkdir -p "$HOME_DIR/unmanaged/tree" "$STATE_DIR"

# Neither an unrelated dangling link nor unrelated directory content may be
# scanned, replaced, or removed.
ln -s /does/not/exist "$HOME_DIR/unmanaged-link"
printf 'keep\n' >"$HOME_DIR/unmanaged/tree/data"

# Seed one path that an earlier installer run explicitly recorded. It is safe
# to prune only while it remains the exact old symlink.
old_target="$HOME_DIR/.removed-managed-file"
old_source="$REPO/homedir/.removed-managed-file"
ln -s "$old_source" "$old_target"
printf '%s\t%s\n' "$old_target" "$old_source" >"$MANIFEST"

HOME="$HOME_DIR" XDG_STATE_HOME="$TMP/state" timeout 5 "$REPO/user_install.sh"

[[ ! -L $old_target ]]
[[ -L $HOME_DIR/unmanaged-link ]]
[[ $(cat "$HOME_DIR/unmanaged/tree/data") == keep ]]
[[ $(readlink "$HOME_DIR/.local/bin/extreme-powersave-user") == \
	"$REPO/homedir/.local/bin/extreme-powersave-user" ]]
[[ -s $MANIFEST && ! -L $MANIFEST ]]

# A repeated install is bounded and leaves unrelated home content untouched.
HOME="$HOME_DIR" XDG_STATE_HOME="$TMP/state" timeout 5 "$REPO/user_install.sh"
[[ -L $HOME_DIR/unmanaged-link ]]
[[ $(cat "$HOME_DIR/unmanaged/tree/data") == keep ]]

printf 'user install smoke test: PASS\n'
