#!/bin/bash
# Install etc/ and usr/ into the root filesystem. Run as root from the repo root.
# Everything is symlinked except the files must_copy() lists; both kinds are
# pruned from / once they are removed from the repo.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
REPO=$(pwd)
STATE_DIR=/var/lib/conffiles
MANIFEST="$STATE_DIR/root-install.copies"

must_copy() {
	case "$1" in
	# Read by systemd, udev, tmpfiles, modprobe and sysctl before the separate
	# /home filesystem (and so this repo) is mounted; a symlink would dangle.
	etc/systemd/* | etc/udev/* | etc/tmpfiles.d/* | etc/modprobe.d/* | etc/sysctl.d/*)
		return 0
		;;
	# Executed as root from udev, systemd or a root shell: they must exist at
	# boot and must not remain user-writable.
	usr/local/bin/extreme-powersave | usr/local/bin/power-mode | usr/local/bin/runtime-power-mode)
		return 0
		;;
	# NetworkManager refuses dispatcher scripts that are symlinks or not owned
	# by root, so they must be installed as real root-owned copies.
	etc/NetworkManager/dispatcher.d/*)
		return 0
		;;
	*) return 1 ;;
	esac
}

file_sum() {
	local sum
	sum=$(sha256sum <"$1")
	printf '%s\n' "${sum%% *}"
}

mkdir -p "$STATE_DIR"
declare -A copied=()

while IFS= read -r -d '' file; do
	target="/$file"
	mkdir -p "$(dirname "$target")"
	if must_copy "$file"; then
		rm -f "$target"
		install -m "$(stat -c %a "$file")" "$file" "$target"
		copied["$target"]=$(file_sum "$target")
	else
		ln -sfn "$REPO/$file" "$target"
	fi
done < <(find etc usr -type f -print0)

# Prune symlinks into the repo whose source no longer exists.
{ find /etc /usr/local -xtype l -print0 2>/dev/null || true; } | while IFS= read -r -d '' link; do
	case "$(readlink "$link")" in
	"$REPO"/*) rm -v "$link" ;;
	esac
done

# Prune copies a previous run recorded that the repo no longer manages, but
# only while they are still the regular file with the exact content installed,
# so a local edit or a file converted to a symlink is never removed. A removed
# unit is disabled first so no dangling *.wants symlink outlives it.
if [ -f "$MANIFEST" ] && [ ! -L "$MANIFEST" ]; then
	while IFS=$'\t' read -r old_target old_sum; do
		case "$old_target" in
		/etc/* | /usr/*) ;;
		*) continue ;;
		esac
		[ "${copied[$old_target]+present}" = present ] && continue
		[ -f "$old_target" ] && [ ! -L "$old_target" ] || continue
		[ "$(file_sum "$old_target")" = "$old_sum" ] || {
			printf 'root_install: keeping locally modified %s\n' "$old_target" >&2
			continue
		}
		case "$old_target" in
		/etc/systemd/system/*.service | /etc/systemd/system/*.timer | /etc/systemd/system/*.socket | /etc/systemd/system/*.path)
			systemctl disable --now -- "${old_target##*/}" || :
			;;
		esac
		rm -v -- "$old_target"
	done <"$MANIFEST"
fi

tmp=$(mktemp "$MANIFEST.XXXXXX")
for target in "${!copied[@]}"; do
	printf '%s\t%s\n' "$target" "${copied[$target]}"
done | LC_ALL=C sort >"$tmp"
chmod 644 "$tmp"
mv -f "$tmp" "$MANIFEST"

systemctl daemon-reload
udevadm control --reload
systemd-tmpfiles --create /etc/tmpfiles.d/powersave.conf
# Reconcile the just-installed boot default with an already-active root toggle.
# With no active state this publishes and applies full performance immediately.
/usr/local/bin/runtime-power-mode current
# reenable (not enable) so a changed [Install] section prunes stale WantedBy
# symlinks. power-mode.service moved from multi-user.target to graphical.target
# to break an ordering cycle with power-profiles-daemon; a plain enable would
# leave the old multi-user.target.wants symlink in place and keep the cycle.
systemctl reenable power-mode.service
systemctl start power-mode.service
