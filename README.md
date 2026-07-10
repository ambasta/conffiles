# conffiles

Gentoo (systemd, sway/Wayland) configuration for my machines, installed by
symlinking files from this repo into place.

## Layout

| Path        | Installed to | Contents                                        |
| ----------- | ------------ | ----------------------------------------------- |
| `etc/`      | `/etc`       | portage, greetd, system sway drop-ins           |
| `usr/`      | `/usr`       | session launch scripts (`sway-run.sh`)          |
| `homedir/`  | `$HOME`      | shell, sway, foot, nvim (LazyVim), user systemd |

## Install

```sh
# as root, from the repo root — links etc/ and usr/ into /
./root_install.sh

# as the user — links homedir/ into $HOME and prunes stale links
./user_install.sh
```

Then emerge the sets referenced by `/var/lib/portage/world_sets`
(`@devutils @editors @fonts @k8s @sway`). The remaining files under
`etc/portage/sets/` are optional toolchains, installed on demand.

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
- `root_install.sh` symlinks `/etc` and `/usr` files to this user-owned repo,
  so anything that can write `$HOME` can influence root-executed config
  (e.g. `make.conf`). Acceptable on a single-admin machine; switch the script
  to copying if that ever stops being true.
