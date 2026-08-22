$env.config.buffer_editor = "vi"

# Keep these user-level tools available without changing their precedence over
# Homebrew's binaries.
$env.path ++= ["~/.orbstack/bin", "~/.local/bin"]

# env.nu creates these modules before config.nu is parsed.
source ($nu.default-config-dir | path join "carapace.nu")
source ($nu.default-config-dir | path join aliases.nu)

# env.nu generates mise.nu before config.nu is loaded.
use ($nu.default-config-dir | path join mise.nu)
