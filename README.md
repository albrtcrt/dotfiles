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

Initialization asks whether operating-system packages should be installed. The
answer is stored in chezmoi's local configuration; behavior never depends on a
Unix username.

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

## Local Git authentication

The managed `~/.gitconfig` includes `~/.gitconfig.local`. Keep credential
helpers and other machine-specific Git settings in that unmanaged file so a
chezmoi apply cannot remove them and the public repository never contains
authentication details.

## Tool policy

Mise is the source of truth for language runtimes, portable developer CLIs, and
system packages. Runtime release channels and current CLI releases are used
intentionally, so `mise upgrade` advances the environment.

The configuration lives in `mise/`, and chezmoi links each file in
`~/.config/mise/` to its repository copy. Commands that change the global
configuration, such as `mise use -g`, therefore edit the repository directly
and show up in `git status`.

| File | Loaded on | Contents |
| --- | --- | --- |
| `config.toml` | every machine | Runtimes and CLIs |
| `config.macos.toml` | macOS | Homebrew formulae and casks |
| `config.linux.toml` | Linux | APT and DNF packages |
| `miserc.toml` | every machine | `auto_env`, which selects the OS file |

Homebrew packages install into the normal Homebrew prefix, so `brew upgrade`
keeps working. Apps that were installed by hand are adopted rather than
replaced.

Machine-specific settings belong in `~/.config/mise/config.local.toml`, which
is not linked into the repository. For example, to skip a tool on one machine:

```toml
[settings]
disable_tools = ["npm:@openai/codex"]
```

## Daily use

```sh
chezmoi edit ~/.bashrc
chezmoi diff
chezmoi apply
chezmoi update
chezmoi verify
mise install
mise use -g <tool>
mise bootstrap packages use -p ~/.config/mise/config.macos.toml brew:<formula>
mise bootstrap packages use -p ~/.config/mise/config.macos.toml brew-cask:<app>
```

For anonymous fetches and authenticated authoring, use separate remote URLs:

```sh
git -C "$(chezmoi source-path)" remote set-url origin \
  https://github.com/albrtcrt/dotfiles.git
git -C "$(chezmoi source-path)" remote set-url --push origin \
  git@github.com:albrtcrt/dotfiles.git
```
