/* AMX Mod X script.
*
*   [SH] Addon: MercyXP (sh_addon_mercyxp.sma)
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <sh_core_main>

#pragma semicolon 1

new gPlayerStartXP[MAX_PLAYERS + 1];
new bool:gBlockMercyXP[MAX_PLAYERS + 1];
new bool:gGiveMercyXP = true;

new CvarMercyXPMode, CvarMercyXP;
new CvarFreeForAll, CvarMinPlayersXP;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
    register_plugin("[SH] Addon: MercyXP", SH_VERSION_STR, SH_AUTHOR_STR);

    register_event_ex("TextMsg", "@Event_TextMsg_GameJoin", RegisterEvent_Global, "2&#Game_join_");
    register_logevent("@LogEvent_RoundEnd", 2, "1=Round_End");
    register_logevent("@LogEvent_RoundRestart", 2, "1&Restart_Round_");
    
    bind_pcvar_num(create_cvar("sh_mercyxp", "0", .has_min = true, .min_val = 0.0), CvarMercyXP);
    bind_pcvar_num(create_cvar("sh_mercyxpmode", "1"), CvarMercyXPMode);
    
    bind_pcvar_num(get_cvar_pointer("sh_ffa"), CvarFreeForAll);
    if (cvar_exists("sh_minplayersxp"))
        bind_pcvar_num(get_cvar_pointer("sh_minplayersxp"), CvarMinPlayersXP);
    else
        bind_pcvar_num(create_cvar("sh_minplayersxp", "2"), CvarMinPlayersXP);
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
    gBlockMercyXP[id] = false;
}
//----------------------------------------------------------------------------------------------
//Called when a client types "kill" in the console (engine module)
public client_kill(id)
{
    gBlockMercyXP[id] = true;
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (gGiveMercyXP && sh_user_is_loaded(id) && !gBlockMercyXP[id]) {
		if (CvarMercyXPMode != 0 && gPlayerStartXP[id] >= sh_get_user_xp(id) && get_playersnum() > CvarMinPlayersXP) {
            new XPtoGive = 0;

            switch (CvarMercyXPMode) {
                case 1: {
                    XPtoGive = CvarMercyXP;
                }
                case 2: {
                    new playerLevel = sh_get_user_lvl(id);

                    if (playerLevel <= CvarMercyXP)
				        XPtoGive = sh_get_kill_xp(CvarMercyXP - playerLevel) / 2;
                }
            }

            if (XPtoGive != 0) {
				sh_set_user_xp(id, XPtoGive, true);
				sh_chat_message(id, _, "You were given %d MercyXP points", XPtoGive);
			}
		}
		gPlayerStartXP[id] = sh_get_user_xp(id);
	}

	gBlockMercyXP[id] = false;
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim, attacker)
{
    if (victim == attacker)
        return;
        
    if (cs_get_user_team(attacker) == cs_get_user_team(victim) && !CvarFreeForAll)
        gBlockMercyXP[attacker] = true;
}
//----------------------------------------------------------------------------------------------
@Event_TextMsg_GameJoin()
{
    gBlockMercyXP[read_data(1)] = true;
}
//----------------------------------------------------------------------------------------------
@LogEvent_RoundRestart()
{
	//Round end is not called when round is set to restart, so lets just force it right away.
	@LogEvent_RoundEnd();
	gGiveMercyXP = false;
}
//----------------------------------------------------------------------------------------------
@LogEvent_RoundEnd()
{
	gGiveMercyXP = false;

	static players[32], playerCount, player, CsTeams:playerTeam, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; i++) {
		player = players[i];

		playerTeam = cs_get_user_team(player);

		if (playerTeam == CS_TEAM_UNASSIGNED || playerTeam == CS_TEAM_SPECTATOR)
			continue;

		if (!gBlockMercyXP[player])
			gGiveMercyXP = true;
	}
}
//----------------------------------------------------------------------------------------------
