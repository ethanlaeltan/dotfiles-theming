# dotfiles-theming

Git-tracked home for the DankMaterialShell (DMS) theming pipeline. The real
files live here; the paths under `~/.config` and `~/.local/bin` are symlinks
into this repo, so editing either side edits the same file.

## Layout

| Path here                  | Symlinked from                          | What it is |
|-----------------------------|------------------------------------------|------------|
| `matugen/`                 | `~/.config/matugen`                     | matugen config + templates for GTK/Qt/Hyprland/kitty/etc |
| `colorschemes/<name>/`     | `~/.config/colorschemes`                | one `<name>.toml` (+ wallpaper) per theme; the source of truth `theme-apply` reads |
| `quickshell-themeswitcher/`| `~/.config/quickshell/themeswitcher`    | the click-to-switch-theme quickshell widget |
| `bin/`                     | individual files in `~/.local/bin`      | `theme-apply`, `theme-verify`, `theme-list`, `dms-theme-switcher` |
| `legacy/` (gitignored)     | n/a                                      | old/stale files kept on disk for reference, not tracked |

## How a theme switch actually works

1. `quickshell-themeswitcher/shell.qml` (or `dms-theme-switcher`, or a
   terminal) runs `theme-apply <name>` with the folder name under
   `colorschemes/`.
2. `theme-apply` reads `colorschemes/<name>/<name>.toml`, writes DMS's own
   `theme.json`, restarts the DMS shell, then renders `matugen/templates/*`
   via `matugen/config.toml` to produce real GTK/Qt/Hyprland/kitty/etc config
   files.
3. `theme-verify` checks the result actually landed everywhere it should.

## dms-shell 1.6.0 note (2026-09-05)

That release deleted DMS's own on-disk matugen templates
(`/usr/share/quickshell/dms/matugen/*`) in favor of an engine embedded in the
`dms` binary. `matugen/templates/{gtk-colors.css,qtct-colors.conf,hypr-colors.lua}`
are local copies pulled from the last 1.5.3 package (still plain matugen
templates, no DMS-internal placeholders) so `theme-apply`'s own matugen run
keeps working without depending on files DMS no longer ships. Nothing
regenerates them automatically anymore -- if a future DMS version changes its
color-role mapping, these need updating by hand.

## Adding a new colorscheme

Copy an existing `colorschemes/<name>/<name>.toml`, adjust its colors (and
optionally add a `wallpaper`, `font`, `radius`, or `[ansi]` table -- see any
existing file for the shape), then `theme-apply <name>`.
