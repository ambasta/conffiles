# conffiles

Gentoo (systemd, sway/Wayland) configuration for my machines, installed from
this repo with symlinks plus root-owned copies for boot-critical files.

## Layout

| Path        | Installed to | Contents                                        |
| ----------- | ------------ | ----------------------------------------------- |
| `etc/`      | `/etc`       | portage, greetd, system sway drop-ins           |
| `usr/`      | `/usr`       | session launch scripts (`sway-run.sh`)          |
| `homedir/`  | `$HOME`      | shell, sway, foot, nvim (LazyVim), user systemd |

## Install

```sh
# as root, from the repo root — installs etc/ and usr/ into /
./root_install.sh

# as the user — links homedir/ into $HOME and prunes stale links
./user_install.sh
```

`user_install.sh` records only its own destinations under
`${XDG_STATE_HOME:-$HOME/.local/state}/conffiles`; it never scans or cleans
unmanaged parts of the home directory.

Then emerge the sets referenced by `/var/lib/portage/world_sets`
(`@devutils @editors @fonts @k8s @sway`). The remaining files under
`etc/portage/sets/` are optional toolchains, installed on demand.

## Extreme power saving

The toggle is split so the root process never reaches into a graphical user
session:

```sh
# In a root shell: CPU/profile, SMT, USB/PCI runtime PM, GPU, panel ABM,
# ASPM, VM, HDA and Wi-Fi.
extreme-powersave on
extreme-powersave off

# In the Sway session: 60 Hz, brightness, keyboard light, Bluetooth, idle
# display power-off and the slower status refresh.
extreme-powersave-user on
extreme-powersave-user off
```

Repeated `on` does not overwrite either script's first snapshot. User-session
`off` restores its exact display/radio state. Root `off` restores captured
non-CPU controls, then always forces full performance mode: SMT and boost
enabled, full frequency cap, performance governor/EPP, PPD `performance`, and
USB/PCI runtime PM disabled (`power/control=on`). Repeated root `off` reasserts
that policy. Root `on` enables USB/PCI runtime PM (`auto`) along with the other
privileged power-saving controls. The Framework AMD xHCI controller matching
`1022:15b9`/`f111:0006` remains `on` in both modes because it cannot enter D3
and otherwise floods the kernel journal; its USB children can still autosuspend.
The user helper powers off the internal display after five idle minutes.
It limits brightness to 20% by default; set
`EXTREME_POWERSAVE_BRIGHTNESS_PERCENT` to choose another usable floor. Set
`EXTREME_POWERSAVE_IDLE_SECONDS` to change the display-off timeout. Automatic
suspend is disabled by default; set `EXTREME_POWERSAVE_SUSPEND_SECONDS` to a
non-zero timeout to opt in. Wi-Fi remains connected: the root toggle changes
only the driver's runtime power-save flag and restores its previous value on
`off`. On supported AMD panels, the root toggle also uses maximum adaptive
backlight modulation (level 4). This saves panel power without changing the
configured 20% brightness, but can affect color fidelity; set
`EXTREME_POWERSAVE_ABM_LEVEL` to `0` through `4` to choose the tradeoff.

`root_install.sh` reloads systemd/udev, applies tmpfiles settings, and enables
the persistent performance service. The tmpfiles boot default is full
performance, while a udev hook makes newly attached USB/PCI devices follow the
current root toggle. Runtime PM is privileged and intentionally remains out of
the userspace helper. Back in the Sway user's shell, link the user helper:

```sh
./user_install.sh
```

After updating these power-policy files, install and reconcile them from a root
shell:

```sh
cd /home/amitprakash/conffiles
./root_install.sh
extreme-powersave off
extreme-powersave status
```

The final status line should report `runtime PM = performance` with every
present USB/PCI device matching. Use `extreme-powersave on` when you want those
devices to autosuspend, then run `extreme-powersave status` again to verify the
`powersave` target.

## HDR display brightness

The Odyssey OLED G9 keeps HDR enabled and uses `wl-gammarelay-rs` for
per-output software dimming. This is deliberately independent of both extreme
power-saving toggles. Install the tracked Sway package set, then link and start
the user service:

```sh
emerge --ask @sway
./user_install.sh
systemctl --user daemon-reload
systemctl --user start wl-gammarelay-rs.service
```

The normal brightness keys adjust every active display in 5% steps using the
appropriate backend: `brightnessctl` for an internal eDP/LVDS/DSI panel and
the per-output `wl-gammarelay-rs` object for each external monitor. The bindings
also work while locked and continue repeating while held. `Shift` plus a
brightness key always adjusts only the laptop panel. Relative changes preserve
each display's independent starting level. The same controls are available
directly:

```sh
display-brightness status
display-brightness up
display-brightness down 10
display-brightness set 60
display-brightness reset
display-brightness internal up
display-brightness external down
```

The Keychron K6 reports its brightness-labelled keys as plain `F5`/`F6`, so
those two keys are mapped to brightness down/up only for the Keychron input
interfaces. Other keyboards retain their normal `F5`/`F6` behavior.

External brightness is clamped to 10–100% to avoid an accidentally black
screen. The last value for each external monitor is restored when the relay
restarts. This changes the gamma LUT rather than the monitor backlight, so HDR
remains enabled but PQ tone mapping and color accuracy are intentionally
compromised.

## Machine-local files (intentionally untracked)

These are referenced by tracked configs but stay per-machine:

- `/etc/portage/make.conf.local` — sourced by `make.conf`; MAKEOPTS and other
  host-specific vars.
- `~/.bashrc.local` — sourced by `.bashrc`; **all secrets/tokens go here**,
  never in the repo.
- `~/.config/sway/resolution`, `~/.config/sway/input` — per-display/per-input
  sway settings, included by the sway config.
- `~/.config/foot/overrides.ini` — per-machine foot overrides (DPI/font size).

## Secrets policy

Nothing under version control may contain credentials. Tokens, AWS keys, and
auth headers live in `~/.bashrc.local`. Before committing, sanity-check with:

```sh
git diff --cached | grep -nE 'ghp_|AKIA|eyJ[A-Za-z0-9_-]{20,}'
```

## Notes

- History was rewritten on 2026-07-10 (`git filter-repo`) to drop ~150 MB of
  long-deleted binaries (Eclipse JDTLS jars, an AWS session-manager-plugin
  binary, a jdtls workspace index). Old clones must be re-cloned or hard-reset
  to `origin/main`.
- `root_install.sh` copies boot-critical configuration and `/usr/local/bin`
  programs so they are available before the separate `/home` filesystem mounts
  and are not user-writable. Later-boot configuration such as Portage and Sway
  remains symlinked for direct editing.
