# Make Homebrew-installed tools available before config.nu imports generated
# modules. This path is specific to supported Apple Silicon Macs.
if "/opt/homebrew/bin" not-in $env.PATH {
  $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")
}

# These modules are generated before config.nu is parsed. They are deliberately
# machine state, not chezmoi-managed dotfiles, so they can track tool updates.
let mise_path = $nu.default-config-dir | path join "mise.nu"
let carapace_path = $nu.default-config-dir | path join "carapace.nu"
let carapace_version_path = $nu.default-config-dir | path join "carapace.version"

if (which mise | is-not-empty) {
  ^mise activate nu | save $mise_path --force
} else {
  "export def --env main [] {}" | save $mise_path --force
}

$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"

if (which carapace | is-not-empty) {
  let installed_version = (^carapace --version | str trim)
  let cached_version = if ($carapace_version_path | path exists) {
    open $carapace_version_path | str trim
  } else {
    ""
  }

  if (not ($carapace_path | path exists)) or ($cached_version != $installed_version) {
    carapace _carapace nushell | save $carapace_path --force
    $installed_version | save $carapace_version_path --force
  }
} else {
  "" | save $carapace_path --force
}
