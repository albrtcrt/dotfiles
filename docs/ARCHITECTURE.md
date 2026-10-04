# Architecture

## Scope

This repository converges one user's shell, Git, SSH client, editor, package,
and developer-tool configuration. It does not provision operating-system
accounts, SSH servers, firewalls, container daemons, production services, or
cloud infrastructure.

Chezmoi owns dotfiles. Mise owns language runtimes, portable command-line
tools, and system packages: Homebrew formulae and casks on macOS, APT or DNF
packages on Linux.

## Machine selection

Initialization records two pieces of local data:

- `profile`: `workstation` or `server`
- `manageSystemPackages`: whether bootstrap may invoke the native package
  manager and sudo

Dotfile behavior comes from `.chezmoi.os`. Tool and package behavior comes from
mise's `auto_env` setting, which loads `config.macos.toml` or
`config.linux.toml`. On Linux, mise skips package managers the machine does not
have, so APT entries apply to Debian and Ubuntu and DNF entries to Fedora. Unix
usernames and hostnames do not select configuration.

## Mise configuration

Mise writes to its global configuration when tools or packages are added, so
those files are not chezmoi templates. The repository keeps them in `mise/`,
and chezmoi links each file in `~/.config/mise/` to its repository copy.
Machine-specific overrides go in `~/.config/mise/config.local.toml`, which
stays outside the repository.

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

`.chezmoiroot` maps `home/` onto the destination home directory. Files outside
`home/` are repository support files and are not applied by chezmoi, except
that chezmoi links the files in `mise/` into `~/.config/mise/`.

```text
.
├── .chezmoiroot
├── bootstrap.sh
├── docs/
├── mise/
│   ├── config.toml
│   ├── config.macos.toml
│   ├── config.linux.toml
│   └── miserc.toml
├── tests/
└── home/
    ├── .chezmoi.toml.tmpl
    ├── .chezmoiignore.tmpl
    ├── .chezmoitemplates/
    └── managed home-directory state
```
