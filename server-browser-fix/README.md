# Server browser fix for Source SDK Base 2006

`Server-browser-fix.zip` is an unmodified copy of the fix published by [sg-servers.net](https://fastdl.sg-servers.net/downloads/stargate_tc2/serverBrowser-fix/), who host StargateTC 2 servers. It is kept here in case that download goes away. `install.bat` installs it; this page says what is inside.

| | |
|---|---|
| Original | `https://fastdl.sg-servers.net/downloads/stargate_tc2/serverBrowser-fix/Server-browser-fix.zip` |
| MD5 | `cf1752faa984816ef0ac9eb2dab9e6aa` |
| Install | copy its `bin` and `platform` folders into `steamapps\common\Source SDK Base` |

## The problem

The `bin\ServerBrowser.dll` of Source SDK Base 2006 (Steam build of 2023) only speaks the old UDP master server protocol, with the list in `platform\config\masterservers.vdf`. Valve's old masters (`208.64.200.39:27011`, `208.64.200.52:27011`) still answer, but with an empty list for every game, even `cstrike` or `hl2mp`. So the Internet tab stays on "Getting new server list…". Servers are listed fine on Steam's current master: Source SDK Base 2007's browser asks Steam directly (`ISteamMatchmakingServers`) and sees them.

## What the zip contains

- **`bin/ServerBrowser.dll`** (MD5 `afcc488ed6b65541a91e9593919cf4a1`, built 2017-07-24, not signed): the server browser as rebuilt by the Fortress Forever team, which uses `ISteamMatchmakingServers`. It is the same code as the `bin/ServerBrowser.dll` that Steam installs with Fortress Forever (built 2017-07-26, same size; the bytes differ only by addresses).
- **`bin/engine.dll`** (MD5 `a481a0bb34626ad776fdc83eaeb75866`): Valve's Source SDK Base 2006 engine (MD5 `dc55cf8d9fe078f076205cdb24ad5eb2`) with 7 bytes changed:

  | Address | Change | Effect |
  |---|---|---|
  | `0x2000ad5b` | `e8 e0 75 06 00` → 5 × `nop` | no `Con_Printf("A2C_PRINT from %s : %s")` for out-of-band text packets: console spam only |
  | `0x201773a9` | `75 0d` → `90 90` | the master server code ignores `sv_master_legacy_mode`: a game hosted from the client registers with Steam's current master |

- **`platform/`**: Valve's interface files. Its three DLLs (`servers/serverbrowser.dll`, `friends/trackerui.dll`, `friends/trackernet.dll`) are byte for byte the ones shipped with Left 4 Dead 2 and Fortress Forever.
- `platform/config/masterservers.vdf` lists Valve's old masters. The new browser doesn't read it.

## Undo

`uninstall.bat` puts back the files it replaced (kept in `Source SDK Base\redial-backup`) and removes the ones it added. Steam's "Verify integrity of game files" on Source SDK Base 2006 also puts back the original `bin` files.
