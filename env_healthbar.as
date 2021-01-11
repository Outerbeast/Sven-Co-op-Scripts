/* env_healthbar
Custom entity to draw a health bar above a target entity
by Outerbeast

Note: Script is functional but prone to breaking.
Keys:
* "target"          - target entity to show a healthbar for. Can be a player, npc or breakable item ( with hud info enabled )
* "scale" "0.0"     - resize the health bar, this is 0.3 by default
* "offset" "x y z"  - adds an offset from the health bar origin
* "distance" "0.0"  - the distance you have to be to be able to see the health bar
* "spawnflags" "1"  - forces the healthbar to stay on for the entity

TO DO:
- Fix division by 0 error
- render the healthbars individually for each player
- draw healthbars for newly spawned entities (how?)
- shove this bastard into a plugin of sorts (I hope) and apply the healthbars to all entities automatically
*/

// For testing convenience, will be removed in the final version of course
void MapInit()
{
    HEALTHBAR::RegisterHealthBarEntity();
}

namespace HEALTHBAR
{

array<string> STR_HEALTHBAR_FRAMES = { "h0", "h10", "h20", "h30", "h40", "h50", "h60", "h70", "h80", "h90", "h100" };

bool blHealthBarEntityRegistered = false;

void RegisterHealthBarEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HEALTHBAR::env_healthbar", "env_healthbar" );
    blHealthBarEntityRegistered = true;
}

class env_healthbar : ScriptBaseEntity
{
    PlayerPostThinkHook@ pPlayerPostThinkFunc = null;

    private CBaseEntity@ pTrackedEntity;
    private CSprite@ pHealthBar;

    private float flDrawDistance = 12048;
    private Vector vOffset = Vector( 0, 0, 16 );

    bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "offset" ) 
		{
			g_Utility.StringToVector( vOffset, szValue );
			return true;
		}
        else if( szKey == "distance" ) 
		{
			flDrawDistance = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

    void Precache()
    {
        for( uint p = 0; p < STR_HEALTHBAR_FRAMES.length(); ++p )
        {
            g_Game.PrecacheModel( "sprites/misc/" + STR_HEALTHBAR_FRAMES[p] + ".spr" );
            g_Game.PrecacheGeneric( "sprites/misc/" + STR_HEALTHBAR_FRAMES[p] + ".spr" );
        }
    }

    void Spawn()
    {
        self.Precache();
        self.pev.movetype 	= MOVETYPE_NONE;
        self.pev.solid 		= SOLID_NOT;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.scale == 0.0f )
            self.pev.scale = 0.3f;

        if( pTrackedEntity is null )
        {
            if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
                @pTrackedEntity = g_EntityFuncs.FindEntityByTargetname( pTrackedEntity, "" + self.pev.target );
        }

        SetThink( ThinkFunction( this.TrackEntity ) );
        self.pev.nextthink = g_Engine.time + 0.01f;

        if( !self.pev.SpawnFlagBitSet( 1 ) )
        {
            @pPlayerPostThinkFunc = PlayerPostThinkHook( this.AimingPlayer );
            g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @pPlayerPostThinkFunc );
        }
    }

    void TrackEntity()
    {
        if( pTrackedEntity !is null && pTrackedEntity.pev.health != 0 && ( pTrackedEntity.IsPlayer() || pTrackedEntity.IsMonster() || ( pTrackedEntity.IsBreakable() && pTrackedEntity.pev.SpawnFlagBitSet( 32 ) ) ) )
        {
            if( pHealthBar is null )
                CreateHealthBar();

            if( pHealthBar !is null )
            {
                uint iPercentHealth = uint( ( pTrackedEntity.pev.health / pTrackedEntity.pev.max_health ) * 10 ); // BUG: this monster keeps dividing by 0 because retarded API, causing crashing
                g_EntityFuncs.SetModel( pHealthBar, "sprites/misc/" + STR_HEALTHBAR_FRAMES[iPercentHealth] + ".spr");
                pHealthBar.pev.scale = self.pev.scale;

                if( pTrackedEntity.IsBSPModel() )
                    pHealthBar.pev.origin = pTrackedEntity.pev.absmin + ( pTrackedEntity.pev.size * 0.5 ) + Vector( 0, 0, pTrackedEntity.pev.absmax.z );
                else
                    pHealthBar.pev.origin = pTrackedEntity.pev.origin + pTrackedEntity.pev.view_ofs + vOffset;
            }

            if( !pTrackedEntity.IsAlive() )
                g_EntityFuncs.Remove( pHealthBar );
        }
        self.pev.nextthink = g_Engine.time + 0.01f;
    }

    void CreateHealthBar()
    {
        @pHealthBar = g_EntityFuncs.CreateSprite( "sprites/misc/" + STR_HEALTHBAR_FRAMES[10] + ".spr", pTrackedEntity.GetOrigin(), false, 0.0f );
        pHealthBar.pev.scale = self.pev.scale;
        pHealthBar.pev.rendermode = kRenderTransAdd;

        if( self.pev.SpawnFlagBitSet( 1 ) )
            pHealthBar.pev.renderamt = 255.0f;
    }

    HookReturnCode AimingPlayer(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null )
            return HOOK_CONTINUE;
        
        CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer, flDrawDistance );

        if( pHealthBar !is null )
        {
            if( pAimedEntity is pTrackedEntity )
                pHealthBar.pev.renderamt = 255.0f;
            else if( pAimedEntity !is pTrackedEntity )
                pHealthBar.pev.renderamt = 0.0f;
        }

        return HOOK_CONTINUE;
    }
}

}
/* Special thanks to:
- Cadaver: sprites
- Snarkeh: original concept and implementation in Command&Conquer campaign
- AnggaraNothing and H2 for scripting support 
*/