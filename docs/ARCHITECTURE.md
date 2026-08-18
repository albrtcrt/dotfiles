# Architecture

## Scope

This repository converges one user's shell, Git, SSH client, editor, package,
and developer-tool configuration. It does not provision operating-system
accounts, SSH servers, firewalls, container daemons, production services, or
cloud infrastructure.

Chezmoi owns dotfiles. Mise owns language runtimes, portable command-line
tools, and the declared APT or DNF prerequisites. Homebrew owns macOS-native
applications.

## Machine selection

Initialization records three pieces of local data:

- `profile`: `workstation`, `server`, or `minimal`
- `manageSystemPackages`: whether bootstrap may invoke the native package
  manager and sudo
- `enableCodex`: whether Codex CLI belongs in the mise tool set

Operating-system behavior comes from `.chezmoi.os` and Linux distribution
behavior comes from `.chezmoi.osRelease.id`. Unix usernames and hostnames do
not select configuration.

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
`home/` are repository support files and are not applied by chezmoi.

```text
.
├── .chezmoiroot
├── bootstrap.sh
├── Brewfile
├── docs/
├── tests/
└── home/
    ├── .chezmoi.toml.tmpl
    ├── .chezmoiignore.tmpl
    ├── .chezmoitemplates/
    └── managed home-directory state
```
