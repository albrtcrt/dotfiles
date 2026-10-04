#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

sh -n "$repository_root/bootstrap.sh"
sh -n "$repository_root/home/private_dot_local/bin/executable_dotfiles-bootstrap"
sh -n "$repository_root/home/dot_bash_profile"
sh -n "$repository_root/home/dot_bashrc"
sh -n "$repository_root/home/.chezmoitemplates/profile_darwin.tmpl"
sh -n "$repository_root/home/.chezmoitemplates/profile_linux.tmpl"

if [ "$(uname -s)" = Linux ]; then
  bash_prompt=$(
    PS1='\s-\v\$ ' HOME=/tmp PATH=/usr/bin:/bin \
      bash --noprofile --rcfile "$repository_root/home/dot_bashrc" \
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

if ! command -v chezmoi >/dev/null 2>&1; then
  printf 'chezmoi is required for render validation.\n' >&2
  exit 1
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

mkdir -p "$validation_dir/home"

case "$(uname -s)" in
  Darwin) profile=workstation ;;
  *) profile=server ;;
esac

generated_config="$validation_dir/generated-chezmoi.toml"
HOME="$validation_dir/home" chezmoi \
  --source "$repository_root" \
  --output "$generated_config" \
  execute-template \
  --init \
  --promptChoice "Machine profile=$profile" \
  --promptBool "Install operating-system packages=true" \
  --file "$repository_root/home/.chezmoi.toml.tmpl"

generated_source=$(
  HOME="$validation_dir/home" chezmoi \
    --config "$generated_config" \
    source-path
)
expected_source="$repository_root/home"
if [ "$generated_source" != "$expected_source" ]; then
  printf 'Generated config forgot source directory: expected %s, got %s\n' \
    "$expected_source" "$generated_source" >&2
  exit 1
fi

cat >"$validation_dir/chezmoi.toml" <<EOF
umask = 0o022

[data]
profile = "$profile"
manageSystemPackages = true
enableOnePassword = $([ "$profile" = workstation ] && printf true || printf false)
gitName = "albrtcrt"
gitEmail = "85366724+albrtcrt@users.noreply.github.com"
EOF

HOME="$validation_dir/home" chezmoi \
  --config "$validation_dir/chezmoi.toml" \
  --source "$repository_root" \
  --destination "$validation_dir/home" \
  apply --dry-run

mkdir -p "$validation_dir/home/.local"
chmod 700 "$validation_dir/home/.local"

HOME="$validation_dir/home" chezmoi \
  --config "$validation_dir/chezmoi.toml" \
  --source "$repository_root" \
  --destination "$validation_dir/home" \
  apply --include=dirs

case "$(uname -s)" in
  Darwin) local_mode=$(stat -f '%Lp' "$validation_dir/home/.local") ;;
  Linux) local_mode=$(stat -c '%a' "$validation_dir/home/.local") ;;
  *) local_mode=700 ;;
esac

if [ "$local_mode" != 700 ]; then
  printf 'Rendered ~/.local mode is %s, expected 700\n' "$local_mode" >&2
  exit 1
fi

HOME="$validation_dir/home" chezmoi \
  --config "$validation_dir/chezmoi.toml" \
  --source "$repository_root" \
  --destination "$validation_dir/home" \
  apply

git_include=$(
  git config --file "$validation_dir/home/.gitconfig" --get include.path
)
if [ "$git_include" != "~/.gitconfig.local" ]; then
  printf 'Git configuration does not include ~/.gitconfig.local.\n' >&2
  exit 1
fi

# mise rewrites its own configuration, so each file must be a link into the
# repository rather than a rendered copy.
for mise_file in config.toml config.macos.toml config.linux.toml miserc.toml; do
  mise_link=$(readlink "$validation_dir/home/.config/mise/$mise_file" || true)
  if [ "$mise_link" != "$repository_root/mise/$mise_file" ]; then
    printf '~/.config/mise/%s does not link to the repository copy: %s\n' \
      "$mise_file" "$mise_link" >&2
    exit 1
  fi
done

case "$(uname -s)" in
  Darwin) mise_os_file=config.macos.toml mise_other_file=config.linux.toml ;;
  *) mise_os_file=config.linux.toml mise_other_file=config.macos.toml ;;
esac

# Run outside the repository so mise reads only the linked global files, and
# keep its data, state, and cache inside the validation directory.
if ! mise_files=$(
  cd "$validation_dir" &&
    env -u MISE_ENV -u MISE_AUTO_ENV -u MISE_GLOBAL_CONFIG_FILE \
      HOME="$validation_dir/home" \
      MISE_CONFIG_DIR="$validation_dir/home/.config/mise" \
      MISE_DATA_DIR="$validation_dir/mise/data" \
      MISE_STATE_DIR="$validation_dir/mise/state" \
      MISE_CACHE_DIR="$validation_dir/mise/cache" \
      mise config ls 2>&1
); then
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

if [ "$(uname -s)" = Linux ]; then
  login_path=$(
    HOME="$validation_dir/home" PATH=/usr/bin:/bin \
      bash -c '. "$HOME/.bash_profile"; printf "%s\n" "$PATH"'
  )
  case ":$login_path:" in
    *":$validation_dir/home/.local/bin:"*) ;;
    *)
      printf 'Linux login profile does not add ~/.local/bin to PATH.\n' >&2
      exit 1
      ;;
  esac

  non_login_path=$(
    HOME="$validation_dir/home" PATH=/usr/bin:/bin \
      bash --noprofile --rcfile "$validation_dir/home/.bashrc" \
      -ic 'printf "%s\n" "$PATH"' 2>/dev/null
  )
  case ":$non_login_path:" in
    *":$validation_dir/home/.local/bin:"*) ;;
    *)
      printf 'Linux non-login Bash does not add ~/.local/bin to PATH.\n' >&2
      exit 1
      ;;
  esac
elif [ -e "$validation_dir/home/.bash_profile" ]; then
  printf '.bash_profile must only be managed on Linux.\n' >&2
  exit 1
fi

printf 'Validation passed.\n'
