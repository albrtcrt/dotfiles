# GUI applications such as Zed import their environment from a non-interactive
# login shell. Mise's prompt hook does not run there, so expose its shims as the
# stable entry point for all mise-managed tools.
use std/util "path add"

path add "~/.local/share/mise/shims"
