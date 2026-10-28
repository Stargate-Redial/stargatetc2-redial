#!/bin/bash
# StargateTC 2 dedicated server, native Linux (Source 2006 "episode1" engine), with the Redial bots.
# Setup: docs/LINUX_SERVER.md. Run it as the server's user, e.g. under screen or from linux/stargatetc2.service.
#
# The loop restarts srcds after a crash (-norestart: restarts belong to this loop, and it logs them);
# -debug makes srcds_run pass a core dump to gdb (stack in debug.log).
# Don't use "set -e": srcds exits with a non-zero code after every crash.
set -uo pipefail

# --- Settings -----------------------------------------------------------------------------------------------
# The engine folder must be named "srcds2006": Botrix recognises the game by the folder of the srcds executable.
SRCDS_DIR=${SRCDS_DIR:-$HOME/sgtc2-server/srcds2006}
IP=${IP:-0.0.0.0}               # the public address on a multi-homed host
PORT=${PORT:-27015}
CLIENTPORT=${CLIENTPORT:-27005}
MAXPLAYERS=${MAXPLAYERS:-16}
MAP=${MAP:-sg2_temple}
# ------------------------------------------------------------------------------------------------------------

cd "$SRCDS_DIR" || exit 1
# bin/srcds2006_fix_i486.so (linux/srcds2006_fix.c): Steam2 lookups answer "no server" (they hung the server loop)
# and memcpy = memmove (the command buffer copies with overlap; on some CPUs +map never ran). Only for srcds_run
# and what it starts: ld.so says "wrong ELF class" for the 64-bit tools among them, harmless.
PRELOAD=$SRCDS_DIR/bin/srcds2006_fix_i486.so
ulimit -c unlimited

while :; do
	echo "$(date '+%F %T') starting StargateTC 2 ($PORT)" | tee -a restarts.log
	rc=0
	LD_PRELOAD=$PRELOAD ./srcds_run -binary ./srcds_i686 -debug -norestart -game stargatetc2 -console \
		-ip "$IP" -port "$PORT" +clientport "$CLIENTPORT" -nohltv +sv_master_legacy_mode 0 +sv_lan 0 \
		+maxplayers "$MAXPLAYERS" -condebug +log on +map "$MAP" || rc=$?
	echo "$(date '+%F %T') srcds exited (code $rc), restarting in 5 s" | tee -a restarts.log

	# console.log (-condebug): one file per run, stamped when it ends.
	L=stargatetc2/console.log
	[ -f "$L" ] && mv -- "$L" "${L%.log}-$(date +%Y%m%d-%H%M%S).log"
	# Keep the 2 newest core dumps.
	find . -maxdepth 1 -type f -regextype posix-extended -regex '.*/core(\.[0-9]+)?' -printf '%T@ %p\n' 2>/dev/null |
		sort -rn | tail -n +3 | cut -d' ' -f2- | while IFS= read -r c; do rm -f -- "$c"; done
	sleep 5
done
