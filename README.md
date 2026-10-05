# dotfiles

Personal, public dotfiles managed with [mise](https://mise.jdx.dev/).

The repository prepares a user environment without requiring GitHub
authentication. It intentionally excludes credentials, private keys, real SSH
hosts, infrastructure addresses, project clones, and service state.

## Supported systems

| System | Package layer | Interactive shell |
| --- | --- | --- |
| macOS (Apple Silicon) | Homebrew | Zsh and Nushell |
| Debian | APT | Bash |
| Ubuntu | APT | Bash |
| Fedora | DNF | Bash |

The operating system selects the configuration; behavior never depends on a
Unix username or hostname.

## Bootstrap a new machine

The preview-first flow installs mise, clones the repository to `~/.dotfiles`,
and shows the planned changes without applying them:

```sh
sh -c "$(curl -fsLS https://raw.githubusercontent.com/albrtcrt/dotfiles/main/bootstrap.sh)"
```

Review the plan and apply it:

```sh
sh ~/.dotfiles/bootstrap.sh --apply
```

Applying replaces existing dotfiles with the repository versions and installs
packages and tools. Existing files in `~/.config/mise/` are kept with a
`.before-dotfiles` suffix.

Prerequisites are `curl`, Git, and CA certificates. System-package installation
also requires sudo. A restricted account should pass `--no-packages`, and can
set `system_packages.sudo = false` in its `~/.config/mise/config.local.toml` so
later runs print package commands instead of elevating.

On a new Mac, install the Xcode Command Line Tools and Homebrew before running
the bootstrap. The public repository can be fetched before 1Password or a
GitHub identity is configured.

## How files are deployed

The repository must live at `~/.dotfiles`. Files shared by every machine are in
`common/`, and operating-system files are in `macos/` and `linux/`. The mise
configuration in `mise/` lists where each one goes:

| File | Loaded on | Contents |
| --- | --- | --- |
| `config.toml` | every machine | Runtimes, CLIs, and shared dotfiles |
| `config.macos.toml` | macOS | Homebrew formulae and casks, macOS dotfiles |
| `config.linux.toml` | Linux | APT and DNF packages, Linux dotfiles |
| `miserc.toml` | every machine | `auto_env`, which selects the OS file |

Most dotfiles are symbolic links into the repository, so editing them, or
running commands such as `mise use -g`, changes the repository directly and
shows up in `git status`. Check that output before committing: this repository
is public.

`~/.gitconfig` and `~/.ssh/config` are copies instead, because other programs
add credentials and private hosts to them. Edit the repository version and run
`mise dot apply`; changes made to the copies are overwritten.

## SSH and private machine state

`~/.ssh/config` includes every file under `~/.ssh/config.d/`. Put real hosts,
usernames, addresses, and identity files in an unmanaged file such as:

```text
~/.ssh/config.d/20-local
```

Keep that directory and its files private:

```sh
chmod 700 ~/.ssh ~/.ssh/config.d
chmod 600 ~/.ssh/config.d/*
```

## Local Git authentication

`~/.gitconfig` includes `~/.gitconfig.local`. Keep credential helpers and other
machine-specific Git settings in that unmanaged file so an apply cannot remove
them and the public repository never contains authentication details.

## Tool policy

Mise is the source of truth for language runtimes, portable developer CLIs, and
system packages. Runtime release channels and current CLI releases are used
intentionally, so `mise upgrade` advances the environment.

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
mise dot status
mise dot diff
mise dot apply
git -C ~/.dotfiles pull && mise bootstrap
mise use -g <tool>
mise bootstrap packages use -p ~/.config/mise/config.macos.toml brew:<formula>
mise bootstrap packages use -p ~/.config/mise/config.macos.toml brew-cask:<app>
```

For anonymous fetches and authenticated authoring, use separate remote URLs:

```sh
git -C ~/.dotfiles remote set-url origin \
  https://github.com/albrtcrt/dotfiles.git
git -C ~/.dotfiles remote set-url --push origin \
  git@github.com:albrtcrt/dotfiles.git
```

## Moving a machine from chezmoi

Machines set up before the move to mise keep the repository in
`~/.local/share/chezmoi`. Update mise, clone the repository to `~/.dotfiles`,
and apply:

```sh
mise self-update
git clone https://github.com/albrtcrt/dotfiles.git ~/.dotfiles
sh ~/.dotfiles/bootstrap.sh
sh ~/.dotfiles/bootstrap.sh --apply
```

Then remove what chezmoi left behind:

```sh
rm ~/.local/bin/dotfiles-bootstrap
rm -r ~/.config/chezmoi ~/.local/share/chezmoi
```
