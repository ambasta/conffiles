#!/bin/bash
# Install etc/ and usr/ into the root filesystem. Run as root from the repo root.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

must_copy() {
	case "$1" in
	etc/systemd/* | etc/udev/* | etc/tmpfiles.d/* | etc/modprobe.d/* | etc/sysctl.d/* | usr/local/bin/*)
		return 0
		;;
	*) return 1 ;;
	esac
}

find etc usr -type f -print0 | while IFS= read -r -d '' file; do
	target="/$file"
	mkdir -p "$(dirname "$target")"
	if must_copy "$file"; then
		# Boot-critical files and root-executed programs must be available before
		# the separate /home filesystem mounts, and must not remain user-writable.
		rm -f "$target"
		install -m "$(stat -c %a "$file")" "$file" "$target"
	else
		ln -sfn "$(pwd)/$file" "$target"
	fi
done

# Prune symlinks into the repo whose source no longer exists.
REPO=$(pwd)
{ find /etc /usr/local -xtype l -print0 2>/dev/null || true; } | while IFS= read -r -d '' link; do
	case "$(readlink "$link")" in
	"$REPO"/*) rm -v "$link" ;;
	esac
done

systemctl daemon-reload
udevadm control --reload
systemd-tmpfiles --create /etc/tmpfiles.d/powersave.conf
# Reconcile the just-installed boot default with an already-active root toggle.
# With no active state this publishes and applies full performance immediately.
/usr/local/bin/runtime-power-mode current
systemctl enable --now power-mode.service
