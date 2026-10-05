#!/bin/sh
# Install or uninstall system packages and record the change in the mise
# configuration, so the repository always matches the machine. The mise tasks
# `brew`, `cask`, `apt`, and `dnf` call this script, for example:
#
#   mise brew install jq             mise brew uninstall jq
#   mise brew install --cask zed     mise cask uninstall zed
#   mise apt install htop            mise dnf remove htop
#
# The word `install` is optional: `mise brew jq` installs jq.
set -eu

manager=${1:?usage: packages.sh brew|cask|apt|dnf [install|uninstall] NAME...}
shift

action=install
case "${1-}" in
  install | add) shift ;;
  uninstall | remove | rm) action=uninstall; shift ;;
  autoremove | cleanup | info | list | ls | outdated | purge | reinstall | \
    search | show | update | upgrade)
    native=$manager
    [ "$manager" = cask ] && native=brew
    printf 'mise %s only installs and uninstalls; use %s for %s.\n' \
      "$manager" "$native" "$1" >&2
    exit 2
    ;;
esac

names=
for arg in "$@"; do
  case "$arg" in
    --cask)
      [ "$manager" = brew ] && manager=cask && continue
      ;;
    --formula)
      [ "$manager" = brew ] && continue
      ;;
  esac
  case "$arg" in
    -*)
      printf 'Unsupported option: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
  names="$names $arg"
done

if [ -z "$names" ]; then
  printf 'Name at least one package.\n' >&2
  exit 2
fi

case "$manager" in
  brew) prefix=brew: file=config.macos.toml ;;
  cask) prefix=brew-cask: file=config.macos.toml ;;
  apt) prefix=apt: file=config.linux.toml ;;
  dnf) prefix=dnf: file=config.linux.toml ;;
  *)
    printf 'Unknown package manager: %s\n' "$manager" >&2
    exit 2
    ;;
esac
config="$HOME/.config/mise/$file"

if [ "$action" = install ]; then
  set --
  for name in $names; do
    set -- "$@" "$prefix$name"
  done
  exec mise bootstrap packages use -p "$config" "$@"
fi

# Remove the declarations first, so the next `mise bootstrap` does not
# reinstall the packages. Writing through the link keeps it intact.
for name in $names; do
  key="\"$prefix$name\""
  if ! awk -v key="$key" '$1 == key { found = 1 } END { exit !found }' "$config"; then
    printf '%s was not recorded in %s.\n' "$name" "$file"
    continue
  fi
  updated=$(awk -v key="$key" '$1 != key' "$config")
  printf '%s\n' "$updated" >"$config"
  printf 'Removed %s from %s.\n' "$name" "$file"
done

sudo=
[ "$(id -u)" -ne 0 ] && sudo=sudo

case "$manager" in
  brew)
    # shellcheck disable=SC2086
    brew uninstall $names
    ;;
  cask)
    for name in $names; do
      if brew list --cask "$name" >/dev/null 2>&1; then
        brew uninstall --cask "$name"
      else
        printf '%s was not installed by Homebrew; remove the app yourself.\n' \
          "$name"
      fi
    done
    ;;
  apt)
    # shellcheck disable=SC2086
    $sudo apt-get remove $names
    ;;
  dnf)
    # shellcheck disable=SC2086
    $sudo dnf remove $names
    ;;
esac
