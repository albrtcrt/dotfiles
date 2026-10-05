#!/bin/sh
set -eu

repository=${DOTFILES_REPOSITORY:-https://github.com/albrtcrt/dotfiles.git}
dotfiles="$HOME/.dotfiles"
apply=false
skip=

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--apply] [--no-packages]

Without --apply, clone the repository to ~/.dotfiles and preview the changes.
With --apply, replace existing dotfiles and install packages and tools.
--no-packages skips operating-system packages, for accounts without sudo.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply) apply=true ;;
    --no-packages) skip=packages ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

bin_dir="$HOME/.local/bin"
mkdir -p "$bin_dir"

if command -v mise >/dev/null 2>&1; then
  mise_bin=$(command -v mise)
elif [ -x "$bin_dir/mise" ]; then
  mise_bin="$bin_dir/mise"
else
  command -v curl >/dev/null 2>&1 || {
    printf 'curl is required to install mise.\n' >&2
    exit 1
  }
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="$bin_dir/mise" sh
  mise_bin="$bin_dir/mise"
fi

export PATH="$bin_dir:$PATH"

if [ ! -d "$dotfiles/.git" ]; then
  git clone "$repository" "$dotfiles"
fi

# mise finds the rest of the configuration through these links, so they must
# exist before it runs. Anything already there is kept beside the link.
link_mise_config() {
  mkdir -p "$1"
  for file in config.toml config.macos.toml config.linux.toml miserc.toml; do
    target="$1/$file"
    source="$dotfiles/mise/$file"
    if [ "$(readlink "$target" 2>/dev/null || true)" = "$source" ]; then
      continue
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      mv "$target" "$target.before-dotfiles"
      printf 'Moved %s to %s.before-dotfiles\n' "$target" "$target"
    fi
    ln -s "$source" "$target"
  done
}

if [ "$apply" != true ]; then
  preview_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-preview.XXXXXX")
  trap 'rm -rf "$preview_dir"' EXIT
  link_mise_config "$preview_dir"
  MISE_CONFIG_DIR="$preview_dir" "$mise_bin" bootstrap --dry-run --force-dotfiles \
    ${skip:+--skip "$skip"}
  printf '\nReview the plan, then run:\n  sh %s/bootstrap.sh --apply%s\n' \
    "$dotfiles" "${skip:+ --no-packages}"
  exit 0
fi

link_mise_config "$HOME/.config/mise"
"$mise_bin" bootstrap --force-dotfiles ${skip:+--skip "$skip"}
