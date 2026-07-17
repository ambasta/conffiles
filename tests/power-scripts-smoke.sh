#!/bin/bash
# Isolated state-machine smoke tests. No live power controls are touched.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOT_SCRIPT="$REPO/usr/local/bin/extreme-powersave"
USER_SCRIPT="$REPO/homedir/.local/bin/extreme-powersave-user"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_eq() {
	local expected=$1 actual=$2 label=$3
	[[ $actual == "$expected" ]] || fail "$label: expected '$expected', got '$actual'"
}

put() {
	local path=$1 value=$2
	mkdir -p "$(dirname "$path")"
	printf '%s\n' "$value" >"$path"
}

root_smoke() {
	local base="$TMP/root" sys="$TMP/root/sys" proc="$TMP/root/proc" run="$TMP/root/run"
	local bin="$TMP/root/bin" policy="$TMP/root/sys/devices/system/cpu/cpufreq/policy0"
	mkdir -p "$bin" "$run" "$sys/class/net/wlan0/wireless" "$sys/class/ieee80211/phy0"
	ln -s "$sys/class/ieee80211/phy0" "$sys/class/net/wlan0/phy80211"
	put "$sys/devices/system/cpu/smt/control" on
	put "$sys/devices/system/cpu/cpufreq/boost" 1
	put "$policy/affected_cpus" 0
	put "$policy/scaling_min_freq" 1000
	put "$policy/scaling_max_freq" 3300
	put "$policy/scaling_governor" performance
	put "$policy/energy_performance_preference" performance
	put "$policy/cpuinfo_max_freq" 3300
	put "$policy/amd_pstate_lowest_nonlinear_freq" 1100
	put "$sys/module/pcie_aspm/parameters/policy" 'default performance powersave [powersupersave]'
	put "$sys/class/drm/card0/device/power_dpm_force_performance_level" auto
	put "$sys/class/drm/card0-eDP-1/amdgpu/panel_power_savings" 0
	put "$sys/module/snd_hda_intel/parameters/power_save" 0
	put "$sys/module/snd_hda_intel/parameters/power_save_controller" Y
	put "$sys/bus/usb/devices/usb1/power/control" on
	put "$sys/bus/pci/devices/0000:c3:00.4/power/control" on
	put "$sys/bus/pci/devices/0000:c1:00.3/power/control" on
	put "$sys/bus/pci/devices/0000:c1:00.3/vendor" 0x1022
	put "$sys/bus/pci/devices/0000:c1:00.3/device" 0x15b9
	put "$sys/bus/pci/devices/0000:c1:00.3/subsystem_vendor" 0xf111
	put "$sys/bus/pci/devices/0000:c1:00.3/subsystem_device" 0x0006
	put "$proc/sys/vm/laptop_mode" 0
	put "$proc/sys/vm/dirty_writeback_centisecs" 1500
	put "$base/profile" performance
	put "$base/battery-aware" true
	put "$base/battery-aware-attempts" ''
	put "$base/log" ''
	put "$base/root-wifi" off
	put "$base/root-wifi-link" connected

	install -m 755 /dev/stdin "$bin/powerprofilesctl" <<'MOCK'
#!/bin/bash
set -eu
case "$1" in
get) cat "$MOCK/profile" ;;
query-battery-aware)
	case $(cat "$MOCK/battery-aware") in
	true) value=True ;;
	false) value=False ;;
	*) exit 2 ;;
	esac
	printf 'Dynamic changes from charger and battery events: %s\n' "$value"
	;;
configure-battery-aware)
	[[ ${2:-} == --disable ]]
	printf 'disable\n' >>"$MOCK/battery-aware-attempts"
	if [[ ${MOCK_BATTERY_AWARE_FAIL_ONCE:-0} == 1 &&
		! -e $MOCK/battery-aware-failed-once ]]; then
		: >"$MOCK/battery-aware-failed-once"
		exit 17
	fi
	[[ ${MOCK_BATTERY_AWARE_STUCK:-0} != 1 ]] || exit 0
	printf '%s\n' false >"$MOCK/battery-aware"
	;;
set)
	printf 'ppd-set:%s\n' "$2" >>"$MOCK/ppd-attempts"
	[[ $(cat "$MOCK_SYS/devices/system/cpu/cpufreq/boost") == 1 ]] || exit 9
	if [[ ${MOCK_PPD_FAIL_ONCE:-0} == 1 && ! -e $MOCK/ppd-failed-once ]]; then
		: >"$MOCK/ppd-failed-once"
		exit 16
	fi
	printf '%s\n' "$2" >"$MOCK/profile"
	case "$2" in
	performance)
		printf '%s\n' performance >"$MOCK_SYS/devices/system/cpu/cpufreq/policy0/scaling_governor"
		printf '%s\n' performance >"$MOCK_SYS/devices/system/cpu/cpufreq/policy0/energy_performance_preference"
		;;
	power-saver)
		printf '%s\n' powersave >"$MOCK_SYS/devices/system/cpu/cpufreq/policy0/scaling_governor"
		printf '%s\n' power >"$MOCK_SYS/devices/system/cpu/cpufreq/policy0/energy_performance_preference"
		;;
	esac
	;;
esac
MOCK
	install -m 755 /dev/stdin "$bin/power-mode" <<'MOCK'
#!/bin/bash
set -eu
printf 'power-mode:%s:%s\n' "$1" "$(cat "$MOCK_SYS/devices/system/cpu/smt/control")" >>"$MOCK/log"
printf '%s\n' false >"$MOCK/battery-aware"
case "$1" in
battery)
	EXTREME_POWERSAVE_LOCK_HELD=1 "$MOCK_RUNTIME_PM" powersave
	printf '%s\n' 1 >"$MOCK_SYS/devices/system/cpu/cpufreq/boost"
	"$MOCK_BIN/powerprofilesctl" set power-saver
	printf '%s\n' 0 >"$MOCK_SYS/devices/system/cpu/cpufreq/boost"
	cat "$MOCK_SYS/devices/system/cpu/cpufreq/policy0/amd_pstate_lowest_nonlinear_freq" >"$MOCK_SYS/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
	;;
ac | auto | performance | max)
	EXTREME_POWERSAVE_LOCK_HELD=1 "$MOCK_RUNTIME_PM" performance
	printf '%s\n' 1 >"$MOCK_SYS/devices/system/cpu/cpufreq/boost"
	"$MOCK_BIN/powerprofilesctl" set performance
	cat "$MOCK_SYS/devices/system/cpu/cpufreq/policy0/cpuinfo_max_freq" >"$MOCK_SYS/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
	;;
esac
MOCK
	install -m 755 /dev/stdin "$bin/udevadm" <<'MOCK'
#!/bin/bash
exit 0
MOCK
	install -m 755 /dev/stdin "$bin/rfkill" <<'MOCK'
#!/bin/bash
exit 0
MOCK
	install -m 755 /dev/stdin "$bin/iw" <<'MOCK'
#!/bin/bash
set -eu
if [[ $1 == dev && $3 == get && $4 == power_save ]]; then
	printf 'Power save: %s\n' "$(cat "$MOCK/root-wifi")"
elif [[ $1 == dev && $3 == set && $4 == power_save ]]; then
	printf '%s\n' "$5" >"$MOCK/root-wifi"
else
	exit 2
fi
MOCK

	local -a env=(env
		EXTREME_POWERSAVE_TESTING=1
		EXTREME_POWERSAVE_SYSFS_ROOT="$sys"
		EXTREME_POWERSAVE_PROCFS_ROOT="$proc"
		EXTREME_POWERSAVE_RUN_DIR="$run"
		EXTREME_POWERSAVE_POWER_MODE="$bin/power-mode"
		EXTREME_POWERSAVE_POWERPROFILESCTL="$bin/powerprofilesctl"
		EXTREME_POWERSAVE_UDEVADM="$bin/udevadm"
		EXTREME_POWERSAVE_RFKILL="$bin/rfkill"
		EXTREME_POWERSAVE_IW="$bin/iw"
		MOCK="$base" MOCK_SYS="$sys" MOCK_BIN="$bin"
		MOCK_RUNTIME_PM="$REPO/usr/local/bin/runtime-power-mode")

	"${env[@]}" "$ROOT_SCRIPT" on >/dev/null
	[[ -f $run/extreme-powersave.state ]] || fail 'root state was not committed'
	assert_eq power-saver "$(cat "$base/profile")" 'root profile on'
	assert_eq off "$(cat "$sys/devices/system/cpu/smt/control")" 'root SMT on'
	assert_eq 0 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'root boost on'
	assert_eq 1100 "$(cat "$policy/scaling_max_freq")" 'root cap on'
	assert_eq powersupersave "$(cat "$sys/module/pcie_aspm/parameters/policy")" 'root ASPM on'
	assert_eq low "$(cat "$sys/class/drm/card0/device/power_dpm_force_performance_level")" 'root GPU on'
	assert_eq 4 "$(cat "$sys/class/drm/card0-eDP-1/amdgpu/panel_power_savings")" 'root panel ABM on'
	assert_eq 1 "$(cat "$sys/module/snd_hda_intel/parameters/power_save")" 'root HDA on'
	assert_eq 5 "$(cat "$proc/sys/vm/laptop_mode")" 'root VM on'
	assert_eq on "$(cat "$base/root-wifi")" 'root Wi-Fi power save on'
	assert_eq auto "$(cat "$sys/bus/usb/devices/usb1/power/control")" 'root USB runtime PM on'
	assert_eq auto "$(cat "$sys/bus/pci/devices/0000:c3:00.4/power/control")" 'root PCI runtime PM on'
	assert_eq on "$(cat "$sys/bus/pci/devices/0000:c1:00.3/power/control")" 'broken xHCI protected on'
	put "$sys/devices/hotplug-usb/power/control" on
	DEVPATH=/devices/hotplug-usb "${env[@]}" \
		"$REPO/usr/local/bin/runtime-power-mode" udev
	assert_eq auto "$(cat "$sys/devices/hotplug-usb/power/control")" 'hotplug USB follows powersave'
	put "$sys/devices/hotplug-xhci/power/control" on
	put "$sys/devices/hotplug-xhci/vendor" 0x1022
	put "$sys/devices/hotplug-xhci/device" 0x15b9
	put "$sys/devices/hotplug-xhci/subsystem_vendor" 0xf111
	put "$sys/devices/hotplug-xhci/subsystem_device" 0x0006
	DEVPATH=/devices/hotplug-xhci "${env[@]}" \
		"$REPO/usr/local/bin/runtime-power-mode" udev
	assert_eq on "$(cat "$sys/devices/hotplug-xhci/power/control")" 'hotplug broken xHCI protected'
	assert_eq connected "$(cat "$base/root-wifi-link")" 'root Wi-Fi association preserved on'
	assert_eq false "$(cat "$base/battery-aware")" 'PPD battery-aware disabled'

	# An already-active v2 snapshot from before root Wi-Fi support must be
	# extended before reconciliation, then restore the newly captured baseline.
	awk -F '\t' '$1 != "wifi" && $1 != "panel-power"' "$run/extreme-powersave.state" >"$run/state-without-wifi"
	mv "$run/state-without-wifi" "$run/extreme-powersave.state"
	printf '%s\n' off >"$base/root-wifi"
	printf '%s\n' 0 >"$sys/class/drm/card0-eDP-1/amdgpu/panel_power_savings"
	"${env[@]}" "$ROOT_SCRIPT" on >/dev/null
	assert_eq on "$(cat "$base/root-wifi")" 'root Wi-Fi migration apply'
	assert_eq 4 "$(cat "$sys/class/drm/card0-eDP-1/amdgpu/panel_power_savings")" 'root panel migration apply'
	grep -q $'^wifi\twlan0\toff\tphy0$' "$run/extreme-powersave.state" ||
		fail 'root Wi-Fi migration snapshot missing'
	grep -q $'^panel-power\tcard0-eDP-1\t0$' "$run/extreme-powersave.state" ||
		fail 'root panel migration snapshot missing'

	local state_hash
	state_hash=$(sha256sum "$run/extreme-powersave.state" | awk '{print $1}')
	"${env[@]}" "$ROOT_SCRIPT" on >/dev/null
	assert_eq "$state_hash" "$(sha256sum "$run/extreme-powersave.state" | awk '{print $1}')" 'root repeated on snapshot'
	grep -q '^power-mode:battery:on$' "$base/log" || fail 'root profile was not applied before SMT off'

	# A failed kernel SMT transition can expose a numeric partial state. Off must
	# normalize it back to fully-on before restoring CPU policies.
	printf '%s\n' 1 >"$sys/devices/system/cpu/smt/control"
	"${env[@]}" "$ROOT_SCRIPT" off >/dev/null
	[[ ! -e $run/extreme-powersave.state ]] || fail 'root state remained after off'
	[[ ! -e $run/extreme-powersave.recovery ]] || fail 'root recovery marker remained after off'
	assert_eq performance "$(cat "$base/profile")" 'root profile restore'
	assert_eq on "$(cat "$sys/devices/system/cpu/smt/control")" 'root SMT restore'
	assert_eq 1 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'root boost restore'
	assert_eq 3300 "$(cat "$policy/scaling_max_freq")" 'root max restore'
	assert_eq auto "$(cat "$sys/class/drm/card0/device/power_dpm_force_performance_level")" 'root GPU restore'
	assert_eq 0 "$(cat "$sys/class/drm/card0-eDP-1/amdgpu/panel_power_savings")" 'root panel ABM restore'
	assert_eq 0 "$(cat "$sys/module/snd_hda_intel/parameters/power_save")" 'root HDA restore'
	assert_eq 0 "$(cat "$proc/sys/vm/laptop_mode")" 'root VM restore'
	assert_eq off "$(cat "$base/root-wifi")" 'root Wi-Fi power save restore'
	assert_eq on "$(cat "$sys/bus/usb/devices/usb1/power/control")" 'root USB performance restore'
	assert_eq on "$(cat "$sys/bus/pci/devices/0000:c3:00.4/power/control")" 'root PCI performance restore'
	printf '%s\n' auto >"$sys/devices/hotplug-usb/power/control"
	DEVPATH=/devices/hotplug-usb "${env[@]}" \
		"$REPO/usr/local/bin/runtime-power-mode" udev
	assert_eq on "$(cat "$sys/devices/hotplug-usb/power/control")" 'hotplug USB follows performance'
	put "$run/extreme-powersave.recovery" off
	if "${env[@]}" "$ROOT_SCRIPT" status >"$base/recovery-status" 2>&1; then
		fail 'root recovery status returned success'
	fi
	grep -q 'RECOVERY REQUIRED (off transition incomplete)' "$base/recovery-status" ||
		fail 'root recovery phase was not reported'
	rm -f "$run/extreme-powersave.recovery"
	assert_eq connected "$(cat "$base/root-wifi-link")" 'root Wi-Fi association preserved off'
	printf '%s\n' power-saver >"$base/profile"
	printf '%s\n' 0 >"$sys/devices/system/cpu/cpufreq/boost"
	printf '%s\n' 1100 >"$policy/scaling_max_freq"
	printf '%s\n' powersave >"$policy/scaling_governor"
	printf '%s\n' power >"$policy/energy_performance_preference"
	printf '%s\n' off >"$sys/devices/system/cpu/smt/control"
	"${env[@]}" "$ROOT_SCRIPT" off >/dev/null
	assert_eq performance "$(cat "$base/profile")" 'repeated off performance profile'
	assert_eq on "$(cat "$sys/devices/system/cpu/smt/control")" 'repeated off SMT on'
	assert_eq 1 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'repeated off boost on'
	assert_eq 3300 "$(cat "$policy/scaling_max_freq")" 'repeated off max cap'

	# The real power-mode helper must defer udev transitions while an extreme
	# state exists, then apply them normally after that state is gone.
	put "$run/extreme-powersave.state" sentinel
	printf '%s\n' 1 >"$sys/devices/system/cpu/cpufreq/boost"
	printf '%s\n' 3300 >"$policy/scaling_max_freq"
	EXTREME_POWERSAVE_TESTING=1 \
	EXTREME_POWERSAVE_SYSFS_ROOT="$sys" \
	EXTREME_POWERSAVE_RUN_DIR="$run" \
	EXTREME_POWERSAVE_POWERPROFILESCTL="$bin/powerprofilesctl" \
	MOCK="$base" MOCK_SYS="$sys" \
		"$REPO/usr/local/bin/power-mode" battery >/dev/null
	assert_eq 1 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'deferred power-mode boost'
	assert_eq 3300 "$(cat "$policy/scaling_max_freq")" 'deferred power-mode cap'
	[[ -e $run/extreme-powersave.power-source-dirty ]] || fail 'deferred power source marker missing'
	rm -f "$run/extreme-powersave.state"
	rm -f "$run/extreme-powersave.power-source-dirty"

	# Battery-aware handling must be idempotent, tolerate a transient D-Bus
	# failure, and verify that a successful setter actually changed PPD state.
	printf '%s\n' false >"$base/battery-aware"
	: >"$base/battery-aware-attempts"
	"${env[@]}" "$REPO/usr/local/bin/power-mode" performance >/dev/null
	[[ ! -s $base/battery-aware-attempts ]] ||
		fail 'power-mode redundantly disabled an already-false battery-aware state'

	printf '%s\n' true >"$base/battery-aware"
	: >"$base/battery-aware-attempts"
	rm -f "$base/battery-aware-failed-once"
	MOCK_BATTERY_AWARE_FAIL_ONCE=1 "${env[@]}" \
		"$REPO/usr/local/bin/power-mode" performance >/dev/null
	assert_eq false "$(cat "$base/battery-aware")" 'battery-aware transient retry state'
	assert_eq 2 "$(wc -l <"$base/battery-aware-attempts")" 'battery-aware transient retry count'

	printf '%s\n' true >"$base/battery-aware"
	: >"$base/battery-aware-attempts"
	if MOCK_BATTERY_AWARE_STUCK=1 "${env[@]}" \
		"$REPO/usr/local/bin/power-mode" performance >"$base/battery-aware-stuck.out" 2>&1; then
		fail 'power-mode accepted a battery-aware state that remained true'
	fi
	assert_eq true "$(cat "$base/battery-aware")" 'battery-aware stuck state'
	grep -q 'failed to disable PPD battery-aware overrides' "$base/battery-aware-stuck.out" ||
		fail 'power-mode did not report battery-aware verification failure'
	printf '%s\n' false >"$base/battery-aware"

	# PPD rejects every per-policy operation when global boost is zero. The real
	# helper must temporarily enable it and retry a transient profile failure.
	printf '%s\n' performance >"$base/profile"
	printf '%s\n' performance >"$policy/scaling_governor"
	printf '%s\n' performance >"$policy/energy_performance_preference"
	printf '%s\n' 0 >"$sys/devices/system/cpu/cpufreq/boost"
	: >"$base/ppd-attempts"
	rm -f "$base/ppd-failed-once"
	MOCK_PPD_FAIL_ONCE=1 EXTREME_POWERSAVE_TESTING=1 \
	EXTREME_POWERSAVE_SYSFS_ROOT="$sys" \
	EXTREME_POWERSAVE_RUN_DIR="$run" \
	EXTREME_POWERSAVE_POWERPROFILESCTL="$bin/powerprofilesctl" \
	MOCK="$base" MOCK_SYS="$sys" \
		"$REPO/usr/local/bin/power-mode" battery >/dev/null
	assert_eq 0 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'normal power-mode boost'
	assert_eq 1100 "$(cat "$policy/scaling_max_freq")" 'normal power-mode cap'
	assert_eq power-saver "$(cat "$base/profile")" 'normal power-mode profile'
	assert_eq powersave "$(cat "$policy/scaling_governor")" 'normal power-mode governor'
	assert_eq power "$(cat "$policy/energy_performance_preference")" 'normal power-mode EPP'
	assert_eq 2 "$(grep -c '^ppd-set:power-saver$' "$base/ppd-attempts")" 'power-mode profile retry'

	# The retained legacy snapshot must now recover from SMT-off/boost-off and
	# finish the migration rather than looping on the PPD boost error.
	put "$run/extreme-powersave.state" $'brightness=1234\nkbd=0\naspm=powersupersave'
	printf '%s\n' off >"$sys/devices/system/cpu/smt/control"
	printf '%s\n' 0 >"$sys/devices/system/cpu/cpufreq/boost"
	printf '%s\n' performance >"$base/profile"
	printf '%s\n' performance >"$policy/scaling_governor"
	printf '%s\n' performance >"$policy/energy_performance_preference"
	"${env[@]}" EXTREME_POWERSAVE_POWER_MODE="$REPO/usr/local/bin/power-mode" \
		"$ROOT_SCRIPT" off >/dev/null
	[[ ! -e $run/extreme-powersave.state ]] || fail 'legacy root state remained after fixed off'
	assert_eq on "$(cat "$sys/devices/system/cpu/smt/control")" 'legacy SMT restore'
	assert_eq 1 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'legacy final performance boost'
	assert_eq performance "$(cat "$base/profile")" 'legacy final performance profile'

	# Off always ends in full CPU performance even when the v2 snapshot was
	# captured with the normal battery policy and boost already disabled.
	"${env[@]}" "$ROOT_SCRIPT" on >/dev/null
	"${env[@]}" "$ROOT_SCRIPT" off >/dev/null
	assert_eq 1 "$(cat "$sys/devices/system/cpu/cpufreq/boost")" 'v2 forced performance boost'
	assert_eq 3300 "$(cat "$policy/scaling_max_freq")" 'v2 forced performance cap'
	assert_eq performance "$(cat "$base/profile")" 'v2 forced performance profile'

	# SMT hotplug refusal is optional: the rest of extreme mode must commit, and
	# off must still restore the original state exactly.
	"${env[@]}" EXTREME_POWERSAVE_SMT_OFF_FORCE_FAIL=1 "$ROOT_SCRIPT" on >/dev/null
	[[ -f $run/extreme-powersave.state ]] || fail 'SMT-busy activation did not commit'
	assert_eq on "$(cat "$sys/devices/system/cpu/smt/control")" 'SMT-busy fallback state'
	"${env[@]}" "$ROOT_SCRIPT" status >/dev/null
	"${env[@]}" "$ROOT_SCRIPT" off >/dev/null
}

user_smoke() {
	local base="$TMP/user" sys="$TMP/user/sys" run="$TMP/user/run" bin="$TMP/user/bin"
	local backlight="$sys/class/backlight/panel" keyboard="$sys/class/leds/chromeos::kbd_backlight"
	mkdir -p "$bin" "$run" "$sys/class/net/wlan0/wireless"
	put "$sys/kernel/random/boot_id" 11111111-2222-3333-4444-555555555555
	put "$backlight/brightness" 20000
	put "$backlight/max_brightness" 65535
	put "$keyboard/brightness" 100
	put "$base/refresh" 120000
	put "$base/power" true
	put "$base/rfsoft" unblocked
	put "$base/wifi" off
	put "$base/uuid" 7e7e7510-d122-4b91-b86a-b06d6df7af03

	install -m 755 /dev/stdin "$bin/swaymsg" <<'MOCK'
#!/bin/bash
set -eu
if [[ $1 == -t && $2 == get_version ]]; then
	printf '{"human_readable":"1.12"}\n'
elif [[ $1 == -t && $2 == get_outputs ]]; then
	printf '[{"name":"eDP-1","active":true,"power":%s,"current_mode":{"width":2880,"height":1920,"refresh":%s},"modes":[{"width":2880,"height":1920,"refresh":120000},{"width":2880,"height":1920,"refresh":60001}]}]\n' "$(cat "$MOCK/power")" "$(cat "$MOCK/refresh")"
elif [[ $1 == -q && $2 == output ]]; then
	case "$4" in
	mode)
		value=${5#*@}; value=${value%Hz}
		whole=${value%%.*}; fraction=${value#*.}
		printf '%s\n' "$((10#$whole * 1000 + 10#$fraction))" >"$MOCK/refresh"
		;;
	power) [[ $5 == on ]] && printf 'true\n' >"$MOCK/power" || printf 'false\n' >"$MOCK/power" ;;
	esac
fi
MOCK
	install -m 755 /dev/stdin "$bin/rfkill" <<'MOCK'
#!/bin/bash
set -eu
case "$1" in
block) printf 'blocked\n' >"$MOCK/rfsoft"; exit ;;
unblock) printf 'unblocked\n' >"$MOCK/rfsoft"; exit ;;
esac
if [[ $* == *ID,DEVICE,TYPE,SOFT* ]]; then
	printf '0 hci0 bluetooth %s\n' "$(cat "$MOCK/rfsoft")"
else
	cat "$MOCK/rfsoft"
fi
MOCK
	install -m 755 /dev/stdin "$bin/nmcli" <<'MOCK'
#!/bin/bash
printf 'called\n' >"$MOCK/nmcli-called"
exit 77
MOCK
	install -m 755 /dev/stdin "$bin/iw" <<'MOCK'
#!/bin/bash
set -eu
printf 'Power save: %s\n' "$(cat "$MOCK/wifi")"
MOCK

	local -a env=(env
		SWAYSOCK=mock-sway.sock
		EXTREME_POWERSAVE_USER_TESTING=1
		EXTREME_POWERSAVE_USER_SYSFS_ROOT="$sys"
		EXTREME_POWERSAVE_USER_RUN_DIR="$run"
		EXTREME_POWERSAVE_ROOT_STATE="$base/no-root-state"
		EXTREME_POWERSAVE_SWAYMSG="$bin/swaymsg"
		EXTREME_POWERSAVE_SWAYIDLE="$bin/missing-swayidle"
		EXTREME_POWERSAVE_SWAYLOCK="$bin/missing-swaylock"
		EXTREME_POWERSAVE_RFKILL="$bin/rfkill"
		EXTREME_POWERSAVE_NMCLI="$bin/nmcli"
		EXTREME_POWERSAVE_IW="$bin/iw"
		MOCK="$base")

	"${env[@]}" "$USER_SCRIPT" on >/dev/null
	[[ -f $run/extreme-powersave-user/state ]] || fail 'user state was not committed'
	assert_eq 13107 "$(cat "$backlight/brightness")" 'user brightness on'
	assert_eq 0 "$(cat "$keyboard/brightness")" 'user keyboard on'
	assert_eq 60001 "$(cat "$base/refresh")" 'user refresh on'
	assert_eq blocked "$(cat "$base/rfsoft")" 'user Bluetooth on'
	assert_eq off "$(cat "$base/wifi")" 'user Wi-Fi connection unchanged on'
	[[ ! -e $base/nmcli-called ]] || fail 'user helper invoked NetworkManager'

	local state_hash
	state_hash=$(sha256sum "$run/extreme-powersave-user/state" | awk '{print $1}')
	"${env[@]}" "$USER_SCRIPT" on >/dev/null
	assert_eq "$state_hash" "$(sha256sum "$run/extreme-powersave-user/state" | awk '{print $1}')" 'user repeated on snapshot'

	"${env[@]}" "$USER_SCRIPT" off >/dev/null
	[[ ! -e $run/extreme-powersave-user/state ]] || fail 'user state remained after off'
	assert_eq 20000 "$(cat "$backlight/brightness")" 'user brightness restore'
	assert_eq 100 "$(cat "$keyboard/brightness")" 'user keyboard restore'
	assert_eq 120000 "$(cat "$base/refresh")" 'user refresh restore'
	assert_eq unblocked "$(cat "$base/rfsoft")" 'user Bluetooth restore'
	assert_eq off "$(cat "$base/wifi")" 'user Wi-Fi connection unchanged off'
	[[ ! -e $base/nmcli-called ]] || fail 'user restore invoked NetworkManager'
	"${env[@]}" "$USER_SCRIPT" off >/dev/null

	# Enabling from an already-low baseline must never raise brightness or
	# refresh, and an already-blocked radio must stay blocked after restore.
	printf '5000\n' >"$backlight/brightness"
	printf '0\n' >"$keyboard/brightness"
	printf '60001\n' >"$base/refresh"
	printf 'blocked\n' >"$base/rfsoft"
	"${env[@]}" "$USER_SCRIPT" on >/dev/null
	assert_eq 5000 "$(cat "$backlight/brightness")" 'low brightness preserved on'
	assert_eq 60001 "$(cat "$base/refresh")" '60 Hz preserved on'
	"${env[@]}" "$USER_SCRIPT" off >/dev/null
	assert_eq 5000 "$(cat "$backlight/brightness")" 'low brightness restore'
	assert_eq 60001 "$(cat "$base/refresh")" '60 Hz restore'
	assert_eq blocked "$(cat "$base/rfsoft")" 'blocked Bluetooth restore'

	put "$base/no-root-state" 'brightness=1234'
	if "${env[@]}" "$USER_SCRIPT" on >/dev/null 2>&1; then
		fail 'user helper accepted an active legacy root snapshot'
	fi
	rm -f "$base/no-root-state"
}

root_smoke
user_smoke
printf 'power script smoke tests: PASS\n'
