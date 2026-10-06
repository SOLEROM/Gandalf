# 08_mods: my Claude Code mods

This folder is a local plugin marketplace (`gandalf-mods`). Each subfolder with a `.claude-plugin/plugin.json` is one mod.

| Folder | Mod | Source |
| --- | --- | --- |
| `mods/` | mods: `/mods hide` hides every mod here at once, `/mods show` brings them back, `/mods` flips. Kept across sessions | this repo |
| `context/` | context-bar: a stacked bar showing what fills the context window, above the prompt, under it or in a pane. `/context-bar` shows or hides it | [hamzafer/claude-code-mods](https://github.com/hamzafer/claude-code-mods/tree/main/mods/context-bar) (MIT) |

## Install on a host

```sh
./install.sh            # all mods; safe to re-run
./install.sh context-bar
```

Then restart Claude Code. The script copies the mods to `~/.claude/mods/gandalf-mods` and installs them from there, so this folder can be moved or deleted afterwards. After editing a mod here, run `./install.sh` again to push the change, then restart or run `/reload-plugins`.

## Options

`config.json` holds each mod's options. Every `./install.sh` run applies them with `claude plugin configure`, which saves them in `~/.claude/settings.json` under `pluginConfigs`. Restart Claude Code after changing one.

```sh
./install.sh --set context-bar.position=below   # edits config.json, then installs
```

| Mod | Option | Values |
| --- | --- | --- |
| context-bar | `position` | `above` (default): the boxed bar and legend above the prompt. `below`: one plain-text line under the prompt (no colors there). `pane`: the boxed bar in a pane, a sidebar in fullscreen mode and a full view otherwise. Claude Code has no place at the top of the window, so `pane` is the nearest. |
| context-bar | `legend` | `true` (default) or `false`: the legend lines under the boxed bar |

To try a position without reinstalling, run `/context-bar above`, `/context-bar below` or `/context-bar pane`. That lasts for the current session only.

## Hide all mods

`/mods hide` hides every mod at once and `/mods show` brings them back. `/mods` on its own switches between the two. The choice is kept across sessions. A mod's own command, such as `/context-bar`, still hides or shows that mod alone.

## Add a mod

Put the plugin in a new subfolder here and re-run `./install.sh`. The script rebuilds `.claude-plugin/marketplace.json` from the subfolders.

For `/mods hide` to hide a new mod too, the mod has to read the switch:

1. Add `"dependencies": ["mods"]` to its `plugin.json`.
2. In its hooks, read `atom({ plugin: 'mods', key: 'isHidden' } as const, false)` with `read($, …)` and draw nothing while it is true. The band above the prompt redraws on its own when the switch changes.
3. Anything it shows outside a render hook, such as `$.ui.status` or a pane it opens, needs a `state.set` hook on `{ plugin: 'mods', key: 'isHidden' }` to update it. See `context/hooks/register.tsx`.
