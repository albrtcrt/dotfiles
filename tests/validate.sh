#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

sh -n "$repository_root/bootstrap.sh"
sh -n "$repository_root/linux/bash_profile"
sh -n "$repository_root/linux/bashrc"
sh -n "$repository_root/linux/profile"
sh -n "$repository_root/macos/profile"

if [ "$(uname -s)" = Linux ]; then
  bash_prompt=$(
    PS1='\s-\v\$ ' HOME=/tmp PATH=/usr/bin:/bin \
      bash --noprofile --rcfile "$repository_root/linux/bashrc" \
      -ic 'printf "%s\n" "$PS1"' 2>/dev/null
  )

  case "$bash_prompt" in
    *'\u'*'\h'*'\w'* | *'\u'*'\h'*'\W'*) ;;
    *)
      printf 'Bash prompt does not include user, host, and directory: %s\n' \
        "$bash_prompt" >&2
      exit 1
      ;;
  esac
fi

if ! command -v mise >/dev/null 2>&1; then
  printf 'mise is required for configuration validation.\n' >&2
  exit 1
fi

validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-validation.XXXXXX")
cleanup() {
  case "$validation_dir" in
    "${TMPDIR:-/tmp}"/dotfiles-validation.*)
      rm -rf -- "$validation_dir"
      ;;
  esac
}
trap cleanup EXIT HUP INT TERM

# Prepare the home directory the way bootstrap.sh does: the repository at
# ~/.dotfiles and the mise configuration linked into ~/.config/mise.
home="$validation_dir/home"
mkdir -p "$home/.config/mise" "$home/.local/bin"
ln -s "$repository_root" "$home/.dotfiles"
for mise_file in config.toml config.macos.toml config.linux.toml miserc.toml; do
  ln -s "$home/.dotfiles/mise/$mise_file" "$home/.config/mise/$mise_file"
done

# Run outside the repository so mise reads only the linked global files, and
# keep its data, state, and cache inside the validation directory.
run_mise() {
  (
    cd "$validation_dir" &&
      env -u MISE_ENV -u MISE_AUTO_ENV -u MISE_GLOBAL_CONFIG_FILE \
        HOME="$home" \
        MISE_CONFIG_DIR="$home/.config/mise" \
        MISE_DATA_DIR="$validation_dir/mise/data" \
        MISE_STATE_DIR="$validation_dir/mise/state" \
        MISE_CACHE_DIR="$validation_dir/mise/cache" \
        mise "$@"
  )
}

case "$(uname -s)" in
  Darwin) mise_os_file=config.macos.toml mise_other_file=config.linux.toml ;;
  *) mise_os_file=config.linux.toml mise_other_file=config.macos.toml ;;
esac

if ! mise_files=$(run_mise config ls 2>&1); then
  printf 'mise could not read its configuration:\n%s\n' "$mise_files" >&2
  exit 1
fi

case "$mise_files" in
  *'unknown field'*)
    printf 'mise does not recognize part of its configuration:\n%s\n' \
      "$mise_files" >&2
    exit 1
    ;;
  *"$mise_other_file"*)
    printf 'mise loaded %s on the wrong operating system:\n%s\n' \
      "$mise_other_file" "$mise_files" >&2
    exit 1
    ;;
esac

for mise_file in /config.toml "$mise_os_file"; do
  case "$mise_files" in
    *"$mise_file"*) ;;
    *)
      printf 'mise did not load %s:\n%s\n' "${mise_file#/}" "$mise_files" >&2
      exit 1
      ;;
  esac
done

if ! apply_output=$(run_mise dot apply --yes 2>&1); then
  printf 'mise could not apply the dotfiles:\n%s\n' "$apply_output" >&2
  exit 1
fi

if ! status_output=$(run_mise dot status --missing 2>&1); then
  printf 'Dotfiles are not in their desired state:\n%s\n' "$status_output" >&2
  exit 1
fi

git_include=$(git config --file "$home/.gitconfig" --get include.path)
if [ "$git_include" != "~/.gitconfig.local" ]; then
  printf 'Git configuration does not include ~/.gitconfig.local.\n' >&2
  exit 1
fi

file_mode() {
  case "$(uname -s)" in
    Darwin) stat -f '%Lp' "$1" ;;
    *) stat -c '%a' "$1" ;;
  esac
}

for private_path in .local:700 .ssh:700 .ssh/config:600; do
  path=${private_path%:*}
  expected=${private_path#*:}
  mode=$(file_mode "$home/$path")
  if [ "$mode" != "$expected" ]; then
    printf '~/%s mode is %s, expected %s\n' "$path" "$mode" "$expected" >&2
    exit 1
  fi
done

if [ "$(uname -s)" = Linux ]; then
  login_path=$(
    HOME="$home" PATH=/usr/bin:/bin \
      bash -c '. "$HOME/.bash_profile"; printf "%s\n" "$PATH"'
  )
  case ":$login_path:" in
    *":$home/.local/bin:"*) ;;
    *)
      printf 'Linux login profile does not add ~/.local/bin to PATH.\n' >&2
      exit 1
      ;;
  esac

  non_login_path=$(
    HOME="$home" PATH=/usr/bin:/bin \
      bash --noprofile --rcfile "$home/.bashrc" \
      -ic 'printf "%s\n" "$PATH"' 2>/dev/null
  )
  case ":$non_login_path:" in
    *":$home/.local/bin:"*) ;;
    *)
      printf 'Linux non-login Bash does not add ~/.local/bin to PATH.\n' >&2
      exit 1
      ;;
  esac
elif [ -e "$home/.bash_profile" ]; then
  printf '.bash_profile must only be managed on Linux.\n' >&2
  exit 1
fi

printf 'Validation passed.\n'
