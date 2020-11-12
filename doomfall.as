/* Just a fun script that changes at what fall speed makes players die from falldamage- players also emit screaming sound
Usage:-
Put the code "DoomFallEnable( flMortalVelocitySetting, blStartOnSetting );" in MapInit
Replace or assign "flMortalVelocitySetting" to your falling speed
Replace or assign "blStartOnSetting" to true if you want it active on map start, or false if you want to have inactive- in which case
you must make a trigger_script that calls "TriggerDoomFall" to enable- to disable in map, call " DoomFallStopThink"

- Outerbeast */

int playerID = 1;
float flMortalVelocity;
bool blStartOn = true;

array<float> PLAYER_FALL_SPEED(33);
array<bool> HAS_PLAYER_FELL(33);

void DoomFallEnable(const float flMortalVelocitySetting, const bool blStartOnSetting)
{
    g_SoundSystem.PrecacheSound( "sc_persia/scream.wav" );

    if( flMortalVelocitySetting <= 0.0f ){ flMortalVelocity = 700.0f; }
    else
        flMortalVelocity = flMortalVelocitySetting;
    
    if( blStartOnSetting )
    {
        blStartOn = true;
        DoomFallStartThink(); 
    }
    else
        blStartOn = false;
}

void TriggerDoomFall(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( !blStartOn ){ DoomFallStartThink(); }
}

void DoomFallStartThink()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @TrackPlayer );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @DoomFall );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @Splat );
}

HookReturnCode TrackPlayer(CBasePlayer @pSpawnedPlyr)
{
    if( @pSpawnedPlyr is null ){ return HOOK_CONTINUE; }

    for( playerID; playerID <= g_Engine.maxClients; ++playerID )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
        PLAYER_FALL_SPEED[playerID]     = 0.0f;
        HAS_PLAYER_FELL[playerID]       = false;
    }
    return HOOK_HANDLED;
}

HookReturnCode DoomFall(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null ){ return HOOK_CONTINUE; }
    
        if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            PLAYER_FALL_SPEED[playerID]     = 0.0f;
            HAS_PLAYER_FELL[playerID]       = false;
        }

        if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            PLAYER_FALL_SPEED[playerID] = pPlayer.m_flFallVelocity;

            if( PLAYER_FALL_SPEED[playerID] >= flMortalVelocity && !HAS_PLAYER_FELL[playerID] )
            {
                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "sc_persia/scream.wav", 1.0f, ATTN_NORM );
                g_PlayerFuncs.SayText( pPlayer, "You are falling to your doom." );
                HAS_PLAYER_FELL[playerID] = true;

                return HOOK_HANDLED;
            }
            else
                return HOOK_CONTINUE; 
        }
        else
            return HOOK_CONTINUE;
}

HookReturnCode Splat(CBasePlayer@ pPlayer)
{
    if( pPlayer is null ){ return HOOK_CONTINUE; }
    
    if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) && HAS_PLAYER_FELL[playerID] )
    {
        entvars_t@ world = g_EntityFuncs.Instance(0).pev;
        pPlayer.TakeDamage(world, world, 10000.0f, DMG_FALL);
        HAS_PLAYER_FELL[playerID] = false;
        g_PlayerFuncs.SayText( pPlayer, "You went SPLAT." );

        return HOOK_HANDLED;
    }
    else
        return HOOK_CONTINUE; 
}

void DoomFallStopThink(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, @TrackPlayer );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, @DoomFall );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, @Splat );
}

/* Special thanks to the usual scripting gang:-
-KernCore
-AnggaraNothing
-H2
-Zode */
