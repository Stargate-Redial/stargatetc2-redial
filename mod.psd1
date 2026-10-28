# What install.ps1 / uninstall.ps1 do for StargateTC 2 (Source SDK Base 2006).
@{
    Title                 = 'StargateTC 2: Redial'
    ModName               = 'StargateTC 2'
    ModFolder             = 'stargatetc2'
    PluginDll             = 'addons\botrix.dll'
    SdkBaseFolder         = 'Source SDK Base'
    SdkAppId              = 215
    # The 2006 engine loads plugins relative to <Source SDK Base>\bin: addons\botrix.vdf is written per computer.
    VdfFromSdkBin         = $true
    # cfg\listenserver.cfg runs cfg\server.cfg.
    CfgFiles              = @('cfg\server.cfg')
    CfgBlock              = @(
        '// Botrix bots (addons/botrix): players + bots kept at this total, bots balance the teams.',
        '// A map can have its own total in cfg/botrix_<map>.cfg (sg2_sanctuary: 14).',
        'botrix config bot quota 10',
        '// Bot skill range: fool stupied normal smart pro.',
        'botrix config bot intelligence normal smart',
        '// Respawn mode (a StargateTC 2 option): 0 = the dead wait for the end of the round, 1 = respawn waves',
        '// during the round (about every 60 s), so a player can join a round in progress.',
        'sgtc2_respawn 1'
    )
    ServerBrowserFix      = $true
    ServerBrowserFixMd5   = 'CF1752FAA984816EF0AC9EB2DAB9E6AA'
    ServerBrowserFixFiles = @{
        'bin\ServerBrowser.dll' = 'AFCC488ED6B65541A91E9593919CF4A1'
        'bin\engine.dll'        = 'A481A0BB34626AD776FDC83EAEB75866'
    }
    PublicServer          = '92.222.243.147:27032'
    Discord               = 'https://discord.com/invite/SgHPP4mZyB'
    Releases              = 'https://github.com/Stargate-Redial/stargatetc2-redial/releases'
}
