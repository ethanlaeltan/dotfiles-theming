#!/usr/bin/env bash
# Bootstrap this repo onto a fresh machine: symlink its contents into the
# real config locations theme-apply and DMS expect. Safe to re-run: an
# existing symlink already pointing here is left alone, and anything else
# already at the destination is backed up (once) with a .pre-dotfiles-theming
# suffix rather than overwritten.
#
# Usage: ~/dotfiles-theming/install.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
	local src="$REPO/$1" dest="$2"
	if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
		echo "ok: $dest"
		return
	fi
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		echo "backing up existing $dest -> $dest.pre-dotfiles-theming"
		mv "$dest" "$dest.pre-dotfiles-theming"
	fi
	mkdir -p "$(dirname "$dest")"
	ln -s "$src" "$dest"
	echo "linked: $dest -> $src"
}

link matugen                  "$HOME/.config/matugen"
link colorschemes             "$HOME/.config/colorschemes"
link quickshell-themeswitcher "$HOME/.config/quickshell/themeswitcher"
mkdir -p "$HOME/.local/bin"
for f in theme-apply theme-verify theme-list dms-theme-switcher; do
	link "bin/$f" "$HOME/.local/bin/$f"
done

cat <<EOF

Done. Requires on PATH: matugen, jq, wofi, hyprctl, dms (DankMaterialShell CLI).
Apply a theme with: theme-apply <name>   (e.g. theme-apply nord)
Check it landed with: theme-verify
EOF
