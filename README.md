# Omahide

Hide windows with Super+H. An icon appears on the Omarchy bar for that workspace. Click it to restore. Super+H does not toggle.

## Install

```sh
omarchy plugin add https://github.com/Hutsoncap/omahide.git --enable --section left
```

Then load the Hyprland binds once from `~/.config/hypr/bindings.lua`:

```lua
dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/omahide/hypr.lua")
```

Reload Hyprland (`hyprctl reload`). Restart the shell if the bar widget does not appear: `omarchy restart shell`.

## Usage

| Bind | Action |
| --- | --- |
| Super+H | Hide the focused window |
| Super+Shift+H | Hide every other window on this workspace |
| Super+Alt+H | Restore the last hidden window |
| Click the bar icon | Restore that window |

Hidden icons only show on the workspace they were hidden from.

## Remove

```sh
omarchy plugin remove omahide
```

Then delete the `dofile(...omahide/hypr.lua)` line from `~/.config/hypr/bindings.lua` and reload Hyprland.

## License

MIT
