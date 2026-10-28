# What the installer does

`install.bat` runs `install.ps1` with Windows PowerShell. Everything it does can also be done by hand, as below.

## Where things are

| | Found from | Default |
|---|---|---|
| Steam | registry `HKCU\Software\Valve\Steam\SteamPath` | `C:\Program Files (x86)\Steam` |
| The mod | registry `SourceModInstallPath` + `stargatetc2` | `Steam\steamapps\sourcemods\stargatetc2` |
| Source SDK Base 2006 | every Steam library in `steamapps\libraryfolders.vdf` | `Steam\steamapps\common\Source SDK Base` |

`-ModDir` and `-SdkBaseDir` override them. The installer stops if StargateTC 2 is running (it would lock the files).

## 1. Bot files

`payload\` is copied into the mod's folder:

| File | What |
|---|---|
| `addons\botrix.dll` | the bot plugin (release zip only) |
| `addons\botrix\config.ini` | bot settings: weapons, classes, skills |
| `addons\botrix\waypoints\*.way` | the paths of the 4 maps |
| `cfg\botrix_sg2_sanctuary.cfg` | 14 players on that map (run by the plugin after `server.cfg`) |
| `materials\console\background01.vtf` | the menu background with "REDIAL V1.0.0" (release zip only; not with `-NoSplash`) |

A file that already exists and differs is first copied to `stargatetc2\redial-backup\` (same relative path). `redial-backup\installed.txt` lists every file installed: `A` added, `R` replaced, `C` cfg created.

## 2. addons\botrix.vdf

The Source 2006 engine loads plugins relative to `<Source SDK Base>\bin`, not to the mod, so the path depends on where Steam put the mod and Source SDK Base. The installer writes it for this computer. With everything in the main Steam folder:

```
"Plugin"
{
	"file"	"../../../sourcemods/stargatetc2/addons/botrix"
}
```

(from `steamapps\common\Source SDK Base\bin`: three levels up is `steamapps`). If the mod and Source SDK Base are on different drives, the installer writes an absolute path and says so.

## 3. cfg\server.cfg

This block is added at the end (`cfg\listenserver.cfg` runs `server.cfg`, so it applies to games created from the menu too). The file keeps its own line endings, and the uninstaller removes only this block:

```
// >>> Stargate Redial bots (added by install.bat; uninstall.bat removes this block)
// Botrix bots (addons/botrix): players + bots kept at this total, bots balance the teams.
// A map can have its own total in cfg/botrix_<map>.cfg (sg2_sanctuary: 14).
botrix config bot quota 10
// Bot skill range: fool stupied normal smart pro.
botrix config bot intelligence normal smart
// Respawn mode (a StargateTC 2 option): 0 = the dead wait for the end of the round, 1 = respawn waves
// during the round (about every 60 s), so a player can join a round in progress.
sgtc2_respawn 1
// <<< Stargate Redial bots
```

`sgtc2_respawn` is the mod's own "Respawn Mode" option. Values 2 and 3 stopped every fight in tests: keep 0 or 1.

## 4. Server browser fix

Unless `-NoServerBrowserFix` is given:

1. Check the MD5 of `server-browser-fix\Server-browser-fix.zip` (`cf1752faa984816ef0ac9eb2dab9e6aa`).
2. If `bin\ServerBrowser.dll` and `bin\engine.dll` of Source SDK Base already have the fix's MD5s, stop here (it was installed before, by Redial or by hand).
3. Extract the zip and copy its `bin\` and `platform\` folders into Source SDK Base. Replaced files go to `Source SDK Base\redial-backup\`, with the same `installed.txt` list.

The installer refuses to run while any game started from Source SDK Base 2006 is open. What the fix contains: [server-browser-fix/README.md](../server-browser-fix/README.md).

## Uninstall

`uninstall.bat` reads both `installed.txt` lists. It puts back the `R` files, deletes the `A` files and the folders they leave empty, and removes the cfg block. Then it deletes `redial-backup`. `-KeepServerBrowserFix` leaves Source SDK Base alone.

## By hand

1. Copy `payload\*` into `steamapps\sourcemods\stargatetc2`.
2. Write `addons\botrix.vdf` as in section 2, with the path from `<Source SDK Base>\bin` to `<mod>\addons\botrix` (no extension).
3. Add the lines of section 3 to `cfg\server.cfg`.
4. Copy the `bin` and `platform` folders of `Server-browser-fix.zip` into `steamapps\common\Source SDK Base`.

To check the bots loaded: `plugin_print` in the console lists Botrix.

## Bot commands

| Command | Effect |
|---|---|
| `botrix config bot quota N` | players + bots kept at N (0 = off) |
| `botrix config bot intelligence MIN MAX` | skill range of new bots: fool, stupied, normal, smart, pro |
| `botrix bot add [skill] [team] [class]` | add a bot, e.g. `botrix bot add normal tauri carter` |
| `botrix bot kick all` | remove every bot |
| `botrix bot` | all bot commands |
| `sgtc2_objectives` | what the bots know about the map: gates, DHD, objectives, artefact |

Botrix writes its log to `addons\botrix\botrix.log`.
