# Architecture

## Scope

This repository converges one user's shell, Git, SSH client, editor, package,
and developer-tool configuration. It does not provision operating-system
accounts, SSH servers, firewalls, container daemons, production services, or
cloud infrastructure.

Mise owns everything: dotfiles, language runtimes, portable command-line tools,
and system packages (Homebrew formulae and casks on macOS, APT or DNF packages
on Linux). `bootstrap.sh` only installs mise, clones the repository, and links
the mise configuration so mise can find the rest.

## Machine selection

Mise's `auto_env` setting, enabled in `miserc.toml`, loads `config.macos.toml`
on macOS and `config.linux.toml` on Linux, so no file needs an operating-system
condition. On Linux, mise skips package managers the machine does not have, so
APT entries apply to Debian and Ubuntu and DNF entries to Fedora. Unix
usernames and hostnames do not select configuration.

Each operating-system file also defines the tasks that install or uninstall
packages and record the change in that file: `brew` and `cask` on macOS, `apt`
and `dnf` on Linux. They share `mise/packages.sh`, because mise has no command
that removes a package declaration.

Machine-specific overrides, such as tools to skip or `system_packages.sudo`,
go in `~/.config/mise/config.local.toml`, which stays outside the repository.

## Dotfile deployment

Mise writes to its global configuration when tools or packages are added, and
people edit their shell files in place, so most dotfiles are symbolic links
into the repository rather than rendered copies. The repository has no
templates.

`~/.gitconfig` and `~/.ssh/config` are copied instead. Programs such as
credential helpers and VPN clients add private data to them, and a link would
put that data in the public working tree. The SSH copy keeps mode `0600`, and
`~/.ssh` and `~/.local` keep mode `0700`.

## Repository boundary

This repository may contain personal preferences and a public Git author
identity. It must not contain:

- authentication tokens or password-manager exports
- private or public key material used to identify a private machine
- real infrastructure hosts or addresses
- repository-specific deploy-key aliases
- account identifiers, UID/GID layouts, or security runbooks
- Codex sessions, project clones, or production state

The public SSH configuration includes `~/.ssh/config.d/*`. Those unmanaged
files are the boundary for machine-specific connectivity.

## Source layout

```text
.
├── bootstrap.sh
├── common/       files for every machine
├── docs/
├── linux/        files for Linux
├── macos/        files for macOS
├── mise/
│   ├── config.toml
│   ├── config.macos.toml
│   ├── config.linux.toml
│   ├── miserc.toml
│   └── packages.sh
└── tests/
```
