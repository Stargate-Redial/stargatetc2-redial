/*
 * LD_PRELOAD for the Linux episode1 srcds (Source Dedicated Server, Steam2 depot 204, 2009) on a current system.
 *
 * 1. Steam2 lookups. The engine still looks up Steam2 "general directory servers" to find the legacy master
 *    servers (CMaster::InitConnection) and the stats servers (CUploadGameStats::UpdateConnection, every frame
 *    from the game DLL). Those servers are gone: each lookup is a blocking connect() that hangs the whole
 *    server loop for minutes. Steam3 (steamclient) does the real work: authentication, VAC and the server
 *    list. So the Steam2 lookups answer "no server" at once.
 *
 * 2. Overlapping memcpy. The command buffer (Cbuf_Execute, Quake heritage) moves the text left over after a
 *    command with memcpy( text, text + i, size ): source and destination overlap. glibc picks its memcpy by
 *    CPU: on the AMD test PC it happened to work, on the OVH VPS (Intel Haswell) the buffer came out garbled
 *    ("couldn't exec ususerconfig.cferPanel...") and the command line (+maxplayers, +map) never ran. memcpy
 *    becomes memmove, which allows overlap.
 *
 * The engine binds these calls through its dynamic symbols, so the preloaded definitions win.
 * Build: gcc -m32 -shared -fPIC -O2 -fno-builtin -o srcds2006_fix_i486.so srcds2006_fix.c
 */
#include <stdio.h>
#include <string.h>

int SteamFindServersNumServers( int eServerType )
{
	(void)eServerType;
	return 0;
}

int SteamFindServersIterateServer( int eServerType, unsigned int uIndex, char *szServerAddress, int iAddressChars )
{
	(void)eServerType;
	(void)uIndex;
	if ( szServerAddress && iAddressChars > 0 )
		szServerAddress[0] = '\0';
	return -1;
}

void *memcpy( void *pDest, const void *pSource, size_t iSize )
{
	return memmove( pDest, pSource, iSize );
}

__attribute__(( constructor )) static void Announce( void )
{
	fprintf( stderr, "srcds2006_fix: Steam2 directory server lookups disabled, memcpy = memmove\n" );
}
