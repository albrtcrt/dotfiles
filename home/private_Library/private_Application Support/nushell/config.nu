$env.config.buffer_editor = "vi"

$env.path ++= ["~/.orbstack/bin", "~/.local/bin"]

source ($nu.default-config-dir | path join "carapace.nu")
source ($nu.default-config-dir | path join aliases.nu)
use ($nu.default-config-dir | path join mise.nu)
