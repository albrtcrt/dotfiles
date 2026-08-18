# dotfiles

Personal, public dotfiles managed with
[chezmoi](https://www.chezmoi.io/) and
[mise](https://mise.jdx.dev/).

The repository prepares a user environment without requiring GitHub
authentication. It intentionally excludes credentials, private keys, real SSH
hosts, infrastructure addresses, project clones, and service state.

## Supported systems

| System | Default profile | Package layer | Interactive shell |
| --- | --- | --- | --- |
| macOS (Apple Silicon) | `workstation` | Homebrew | Zsh and Nushell |
| Debian | `server` | APT | Bash |
| Ubuntu | `server` | APT | Bash |
| Fedora | `server` | DNF | Bash |

`minimal` is also available for short-lived machines. Initialization asks
whether system packages and Codex CLI should be installed. These choices are
stored in chezmoi's local configuration; behavior never depends on a Unix
username.

## Bootstrap a new machine

The preview-first flow installs chezmoi, initializes the public repository, and
shows the proposed changes:

```sh
sh -c "$(curl -fsLS https://raw.githubusercontent.com/albrtcrt/dotfiles/main/bootstrap.sh)"
```

Review the diff and apply it:

```sh
chezmoi apply -v
~/.local/bin/dotfiles-bootstrap
```

To apply and install the selected tool profile in one pass:

```sh
sh -c "$(curl -fsLS https://raw.githubusercontent.com/albrtcrt/dotfiles/main/bootstrap.sh)" -- --apply
```

Prerequisites are `curl`, Git, and CA certificates. System-package installation
also requires sudo. A restricted account should answer `no` when asked to
install operating-system packages.

On a new Mac, install the Xcode Command Line Tools and Homebrew before running
the workstation tool bootstrap. The public repository can be fetched before
1Password or a GitHub identity is configured.

## SSH and private machine state

Chezmoi manages `~/.ssh/config` and includes every file under
`~/.ssh/config.d/`. Put real hosts, usernames, addresses, and identity files in
an unmanaged file such as:

```text
~/.ssh/config.d/20-local
```

Keep that directory and its files private:

```sh
chmod 700 ~/.ssh ~/.ssh/config.d
chmod 600 ~/.ssh/config.d/*
```

The `private_` prefix in chezmoi source names controls target permissions; it
does not make repository contents secret.

## Tool policy

Mise is the source of truth for language runtimes and portable developer CLIs.
Runtime release channels and current CLI releases are used intentionally, so
`mise upgrade` advances the environment. Homebrew remains responsible for
macOS-native applications and utilities.

## Daily use

```sh
chezmoi edit ~/.bashrc
chezmoi diff
chezmoi apply
chezmoi update
chezmoi verify
mise install
```

For anonymous fetches and authenticated authoring, use separate remote URLs:

```sh
git -C "$(chezmoi source-path)" remote set-url origin \
  https://github.com/albrtcrt/dotfiles.git
git -C "$(chezmoi source-path)" remote set-url --push origin \
  git@github.com:albrtcrt/dotfiles.git
```
