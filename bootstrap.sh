#!/bin/sh
set -eu

repository=${DOTFILES_REPOSITORY:-https://github.com/albrtcrt/dotfiles.git}
apply=false

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--apply]

Without --apply, initialize chezmoi and show the proposed changes.
With --apply, apply the dotfiles and install the selected tool profile.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply) apply=true ;;
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

if command -v chezmoi >/dev/null 2>&1; then
  chezmoi_bin=$(command -v chezmoi)
elif [ -x "$bin_dir/chezmoi" ]; then
  chezmoi_bin="$bin_dir/chezmoi"
else
  command -v curl >/dev/null 2>&1 || {
    printf 'curl is required to install chezmoi.\n' >&2
    exit 1
  }
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$bin_dir"
  chezmoi_bin="$bin_dir/chezmoi"
fi

"$chezmoi_bin" init "$repository"
"$chezmoi_bin" diff

if [ "$apply" != true ]; then
  printf '\nReview the diff, then run:\n  %s apply -v\n  %s/dotfiles-bootstrap\n' \
    "$chezmoi_bin" "$bin_dir"
  exit 0
fi

"$chezmoi_bin" apply -v
"$bin_dir/dotfiles-bootstrap"
