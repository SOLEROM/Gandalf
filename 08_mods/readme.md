# 08_mods: my Claude Code mods

This folder is a local plugin marketplace (`gandalf-mods`). Each subfolder with a `.claude-plugin/plugin.json` is one mod.

| Folder | Mod | Source |
| --- | --- | --- |
| `context/` | context-bar: a stacked bar above the prompt showing what fills the context window. `/context-bar` shows or hides it | [hamzafer/claude-code-mods](https://github.com/hamzafer/claude-code-mods/tree/main/mods/context-bar) (MIT) |

## Install on a host

```sh
./install.sh            # all mods; safe to re-run
./install.sh context-bar
```

Then restart Claude Code. The script copies the mods to `~/.claude/mods/gandalf-mods` and installs them from there, so this folder can be moved or deleted afterwards. After editing a mod here, run `./install.sh` again to push the change, then restart or run `/reload-plugins`.

## Add a mod

Put the plugin in a new subfolder here and re-run `./install.sh`. The script rebuilds `.claude-plugin/marketplace.json` from the subfolders.
