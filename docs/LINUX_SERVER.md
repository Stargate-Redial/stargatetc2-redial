# Hosting a StargateTC 2 Linux dedicated server

The Stargate Redial server (`92.222.243.147:27032`) runs this way, natively on Debian 13, with no Wine and no emulation. With 10 bots it uses about 10 % of one vCPU and 150 MB.

The engine and the game content belong to Valve and are not in this repository: you fetch them yourself, as below. The files referred to as `linux/...` are in this repository, and the built ones are in the `linux` folder of the release zip.

You need a 64-bit Linux with 32-bit support (Debian: `dpkg --add-architecture i386 && apt install lib32gcc-s1 lib32stdc++6`), `screen`, and Python 3 for the tools.

## 1. The engine: Source 2006 "episode1" for Linux

Valve never moved the episode1 Linux binaries to SteamPipe in 2013. App 205 only has Windows files, and app 204 ("Source Dedicated Server Linux") is empty for anonymous logins ([Source-1-Games #1614](https://github.com/ValveSoftware/Source-1-Games/issues/1614), open since 2014). The last version (v96, 2009-08-27) survives in the Steam2 depot collection of archive.org:

| File | archive.org item | Size | MD5 |
|---|---|---|---|
| `204.data` | `steam2dats-part1` | 486 003 829 | `82545d7ced5eb448c2547601ab666f0d` |
| `checksums-indexes-manifests-patched.7z` | `steam2dats-meta` | 572 446 903 | `d9bc2f450239b022399ae4eb003838aa` |

From the 7z you need `indexes/204.index`, `checksums/204.checksums` and `manifests/204_96.manifest`. Put `204.data` and `204.index` in one folder and extract with `linux/s2extract.py` (standard library only):

```
python3 -I s2extract.py extract 204_96.manifest <storage dir> 204 srcds2006
```

You get 65 files: `srcds_i486`, `srcds_i686`, `srcds_amd`, `srcds_run`, `bin/engine_*.so`, `bin/dedicated_*.so`, `bin/steam_api_i486.so`, `bin/steamclient_i486.so` and a minimal `hl2/`. **Keep the folder name `srcds2006`:** Botrix recognises the game by the name of the folder that holds the srcds executable (`games =` in `addons/botrix/config.ini`).

## 2. Engine fixes

1. **Steam client.** The 2009 `bin/steamclient_i486.so` can't log on any more. Replace it with a link to the `linux32/steamclient.so` of a current SteamCMD (`~/.steam/sdk32/steamclient.so` once SteamCMD has run). It still serves the old interfaces that `steam_api` asks for. Keep the original as `.2009`.
2. **`sv_master_legacy_mode 0`,** on the command line and in `server.cfg`. Otherwise the engine looks for the old HL2 master through Steam2 directory servers, which are gone, and hangs.
3. **`bin/srcds2006_fix_i486.so`,** preloaded (`LD_PRELOAD`). Source: `linux/srcds2006_fix.c`; build with `gcc -m32 -shared -fPIC -O2 -fno-builtin -o srcds2006_fix_i486.so srcds2006_fix.c`, or take it from the release zip.
   - The game DLL still looks up Steam2 stats servers every frame. Each lookup is a blocking `connect()` to a dead address, so the whole server loop froze. The library answers "no server".
   - The command buffer (`Cbuf_Execute`) moves its text with an overlapping `memcpy`. glibc picks its `memcpy` by CPU: on an AMD Ryzen it happened to work, on an Intel Haswell VPS the buffer came out garbled, and `+maxplayers` / `+map` never ran. That's the "doesn't work on Intel" problem reported in 2015. The library maps `memcpy` to `memmove`.

With these, the console shows "Connection to Steam servers successful" and "VAC secure mode is activated", and the server appears in the Steam list (app 215, `stargatetc2`).

## 3. Half-Life 2 content

The 2009 engine can't read VPK files: extract what a server needs with `linux/vpk.py`. Take the VPKs from a Source SDK Base 2006 install (`steamapps/common/Source SDK Base/vpks`), depots 206, 207 and 208, in that order:

```
python3 -I vpk.py extract srcds2006/hl2 server <depot 206 _dir.vpk> <depot 207 _dir.vpk> <depot 208 _dir.vpk>
```

The `server` filter leaves out textures, sounds of voices and music, videos and interface files, and keeps the `.dx90.vtx` model files (without them the server logs "MDLCache: Failed load of .VTX data" in a loop). Then extract the depot 204 `hl2/` files again on top. `hl2/` ends up at about 590 MB.

## 4. The mod

1. Copy `sourcemods/stargatetc2` from a client install. Leave out the `.vtf` textures, logs, `bin/*.dll`, `updater/`, `sdk/`, `scene.cache` and the uninstaller. It's about 280 MB.
2. Put the Linux game DLL in `stargatetc2/bin/server_i486.so`. It comes from the mod's server edition ([ModDB](https://www.moddb.com/downloads/stargatetc-2-beta-1-server-edition-linux-win), `stargatetc2_server_b1.zip`, MD5 of the `.so` `b91b1018…`). It is older than the client's `server.dll` (2008-06-30 against 2008-07-11), but clients connect fine.
3. Bots, from the release zip:
   - `linux/addons/botrix_i486.so` → `stargatetc2/addons/botrix_i486.so`;
   - `linux/botrix.vdf` → `stargatetc2/addons/botrix.vdf`. It differs from the Windows one: on Linux the episode1 engine loads `<srcds folder>/bin/<file>_i486.so`, so the path is `../stargatetc2/addons/botrix`;
   - `payload/addons/botrix/` (settings and waypoints) and `payload/cfg/botrix_sg2_sanctuary.cfg` → into `stargatetc2/`;
   - the bot block of [DETAILS.md](DETAILS.md#3-cfgservercfg) at the end of `stargatetc2/cfg/server.cfg`.
4. In `stargatetc2/cfg/server.cfg`, also set `hostname`, `sv_lan 0`, `sv_master_legacy_mode 0`, `log on` and `sv_logflush 1` (each log line written at once). Keep the RCON password out of it: `exec rcon.cfg`, with `rcon_password` in a `cfg/rcon.cfg` readable only by the server's user.

## 5. Run

`linux/run-server.sh` starts srcds in a loop that restarts it after a crash. Copy it next to the `srcds2006` folder and set its variables (or pass them in the environment): `SRCDS_DIR`, `IP`, `PORT`, `CLIENTPORT`, `MAXPLAYERS`, `MAP`. `linux/stargatetc2.service` is a systemd unit that runs it in a `screen`.

- Open the game port in UDP in your firewall.
- `-nohltv` is set: SourceTV isn't needed, and its port (27020) is often taken by another server.
- On a host with several addresses, set `IP` to the public one.
- The engine ignores A2S queries (server browser) that come from `127.0.0.1`: a monitoring script must query the public address.
- `linux/a2s.py host port` queries the server like the browser does; `linux/rcon.py host port - "status"` runs an RCON command, with the password in `RCON_PASSWORD`.

Harmless messages: "proxy not found" for materials (normal on a dedicated server), and "no ServerGameDLL006 interface" from Botrix (this `.so` only has `ServerGameDLL005`; Botrix finds the game DLL by its file name instead).

## 6. How the Linux port of the bots works

The Windows port finds the game's functions and fields by address and offset in `server.dll`. On Linux, everything is in the `#elif defined(__linux__)` branches of the patch and in `mods/sgtls/linux_server.cpp`:

- **Symbols.** The mod's `server_i486.so` (GCC) exports all its symbols, so functions are found by `dlsym` with their mangled names. The module is found by `dladdr` on the game's interface, or by its file name.
- **Vtables.** An object's vtable pointer is 2 entries after the `_ZTV…` symbol (offset-to-top and typeinfo); `dladdr1` gives the symbol's size to bound slot searches. The `.so` has text relocations, so its vtables are in the read-only text segment: they are written through `mprotect`.
- **Calling convention.** GCC's `thiscall` is `cdecl` with `this` first.
- **Field offsets.** GCC's member function pointers take 8 bytes instead of 4, so the mod's own fields move. For `CBFLStargate` the shift is +0x14 (chevrons 0x488, active 0x4a5, outgoing 0x4b4, incoming 0x4b5, destination 0x4cc), checked in the gate functions and in live memory dumps. Network properties (SendTables) need no change.
- **DHD buttons** are found by their vtable (`_ZTV14CBFL_DHDBUTTON`) and pressed by calling their `Use` by name.
- **End of round.** A jump at the start of `CHL2MPRules::WinScreen(int)` goes to a plain C function that logs which rule ended the round (`dladdr` on the return address), then calls the original through a trampoline.
- Windows only: the crash logger (`crash_handler.cpp`).

Build: [BUILDING.md](BUILDING.md#linux). The plugin links its own static libstdc++ before `tier0_i486.so` (which exports an old one) and uses `-Bsymbolic`, so that its globals (`g_pCVar`...) are its own.
