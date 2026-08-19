#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

sh -n "$repository_root/bootstrap.sh"
sh -n "$repository_root/home/dot_local/bin/executable_dotfiles-bootstrap"
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
  Darwin)
    profile=workstation
    osid=darwin
    ;;
  Linux)
    profile=server
    os_release_id=linux
    if [ -r /etc/os-release ]; then
      os_release_id=$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')
    fi
    osid="linux-$os_release_id"
    ;;
  *)
    profile=minimal
    osid=unsupported
    ;;
esac

cat >"$validation_dir/chezmoi.toml" <<EOF
umask = 0o022

[data]
profile = "$profile"
manageSystemPackages = true
enableCodex = true
enableOnePassword = $([ "$profile" = workstation ] && printf true || printf false)
osid = "$osid"
gitName = "albrtcrt"
gitEmail = "85366724+albrtcrt@users.noreply.github.com"
EOF

HOME="$validation_dir/home" chezmoi \
  --config "$validation_dir/chezmoi.toml" \
  --source "$repository_root" \
  --destination "$validation_dir/home" \
  apply --dry-run

printf 'Validation passed.\n'
