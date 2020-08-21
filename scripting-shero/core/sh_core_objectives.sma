/* AMX Mod X script.
*
*   [SH] Core: Objectives (sh_core_objectives.sma)
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <csx>
#include <cstrike>
#include <sh_core_main>

#pragma semicolon 1

new gNumHostages = 0;
new gXpBonusC4ID = -1;
new gXpBonusVIP;

new CvarObjectiveXP, CvarBlockVIP[8];
new CvarMinPlayersXP;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
    register_plugin("[SH] Core: Objectives", SH_VERSION_STR, SH_AUTHOR_STR);

    register_logevent("@LogEvent_BombHolderSpawned", 3, "2=Spawned_With_The_Bomb");
    register_logevent("@LogEvent_HostageKilled", 3, "2=Killed_A_Hostage");
    register_logevent("@LogEvent_HostageRescued", 3, "2=Rescued_A_Hostage");
    register_logevent("@LogEvent_AllHostagesRescued", 6, "3=All_Hostages_Rescued");
    register_logevent("@LogEvent_VIPAssassinated", 3, "2=Assassinated_The_VIP");
    register_logevent("@LogEvent_VIPEscaped", 6, "3=VIP_Escaped");
    register_logevent("@LogEvent_VIPUserSpawned", 3, "2=Became_VIP");
    register_logevent("@LogEvent_VIPUserEscaped", 3, "2=Escaped_As_VIP");

	// Count number of hostages for sh_objectivexp
	// This should have a better method of counting, maybe check when keyvalue is set
    new ent = -1;
    while ((ent = cs_find_ent_by_class(ent, "hostage_entity")) > 0)
        gNumHostages++;
        
    bind_pcvar_num(create_cvar("sh_objectivexp", "8", .has_min = true, .min_val = 0.0), CvarObjectiveXP);
    bind_pcvar_string(create_cvar("sh_blockvip", "abcdef"), CvarBlockVIP, charsmax(CvarBlockVIP));
    
    if (cvar_exists("sh_minplayersxp"))
        bind_pcvar_num(get_cvar_pointer("sh_minplayersxp"), CvarMinPlayersXP);
    else
        bind_pcvar_num(create_cvar("sh_minplayersxp", "2"), CvarMinPlayersXP);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
    register_library("sh_core_objectives");

    register_native("sh_get_c4_id", "@Native_GetC4_ID");
    register_native("sh_get_vip_id", "@Native_GetVIP_ID");
    register_native("sh_vip_flags", "@Native_VIPFlags");
}
//----------------------------------------------------------------------------------------------
//native sh_get_c4_id()
@Native_GetC4_ID()
{
	return gXpBonusC4ID;
}
//----------------------------------------------------------------------------------------------
//native sh_get_vip_id()
@Native_GetVIP_ID()
{
	return gXpBonusVIP;
}
//----------------------------------------------------------------------------------------------
//native sh_vip_flags()
@Native_VIPFlags()
{
	return read_flags(CvarBlockVIP);
}
//----------------------------------------------------------------------------------------------
@LogEvent_BombHolderSpawned()
{
	new id = getLoguserIndex();

	if (id < 1 || id > MaxClients)
		return;

	// Find the Index of the bomb entity and save to be used as the one that gives xp
	new ent = -1;
	while ((ent = cs_find_ent_by_owner(ent, "weapon_c4", id)) != 0) {
		// set ent to XP bomb
		gXpBonusC4ID = ent;
		break;
	}
}
//----------------------------------------------------------------------------------------------
public bomb_planted(planter)
{
    if (!sh_is_active() || !CvarObjectiveXP)
		return;
    
    if (!is_user_connected(planter) || !pev_valid(gXpBonusC4ID))
		return;

    if (planter != pev(gXpBonusC4ID, pev_owner))
		return;

    if (cs_get_user_team(planter) != CS_TEAM_T)
		return;

    if (get_playersnum() <= CvarMinPlayersXP)
		return;

	// Only give this out once per round
    gXpBonusC4ID = -1;
    
    sh_set_user_xp(planter, CvarObjectiveXP, true);
    sh_chat_message(planter, _, "You got %d XP for planting the bomb", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
public bomb_defused(defuser)
{
	// Need to make sure gXpBonusC4ID was the bomb defused?
    if (!sh_is_active() || !CvarObjectiveXP)
		return;
    
    if (!is_user_connected(defuser))
		return;
        
    if (cs_get_user_team(defuser) != CS_TEAM_CT)
		return;
        
    if (get_playersnum() <= CvarMinPlayersXP)
		return;
        
    sh_set_user_xp(defuser, CvarObjectiveXP, true);
    sh_chat_message(defuser, _, "You got %d XP for defusing the bomb", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
public bomb_explode(planter, defuser)
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return PLUGIN_CONTINUE;

	if (get_playersnum() <= CvarMinPlayersXP)
		return PLUGIN_CONTINUE;

	new players[32], playerCount, player;
	new XPtoGive = CvarObjectiveXP;

	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (new i = 0; i < playerCount; i++) {
		player = players[i];

		if (cs_get_user_team(player) != CS_TEAM_T)
			continue;

		sh_set_user_xp(player, XPtoGive, true);
		sh_chat_message(player, _, "Your team got %d XP for a successful bomb explosion", XPtoGive);
	}
	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
@LogEvent_HostageKilled()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	new id = getLoguserIndex();

	if (id < 1 || id > MaxClients)
		return;

	sh_set_user_xp(id, -CvarObjectiveXP, true);
	sh_chat_message(id, _, "You lost %d XP for killing a hostage", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
@LogEvent_HostageRescued()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	new id = getLoguserIndex();

	if (!is_user_connected(id))
		return;

	if (cs_get_user_team(id) != CS_TEAM_CT)
		return;

	if (get_playersnum() < CvarMinPlayersXP)
		return;

	// Give at least 1 xp per hostage even if sh_objectivexp is really low
	// gNumHostages should never be 0 if this is called so no need to check for div by 0
	new XPtoGive = max(1, floatround(float(CvarObjectiveXP) / gNumHostages));

	sh_set_user_xp(id, XPtoGive, true);
	sh_chat_message(id, _, "You got %d XP for rescuing a hostage", XPtoGive);
}
//----------------------------------------------------------------------------------------------
@LogEvent_AllHostagesRescued()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	if (get_playersnum() <= CvarMinPlayersXP)
		return;

	new players[32], playerCount, player;
	new XPtoGive = CvarObjectiveXP;

	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (new i = 0; i < playerCount; i++) {
		player = players[i];

		if (cs_get_user_team(player) != CS_TEAM_CT)
			continue;

		sh_set_user_xp(player, XPtoGive, true);
		sh_chat_message(player, _, "Your team got %d XP for rescuing all the hostages", XPtoGive);
	}
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPAssassinated()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	new attacker = getLoguserIndex();

	if (!is_user_connected(attacker))
		return;

	if (cs_get_user_team(attacker) != CS_TEAM_T)
		return;

	if (get_playersnum() <= CvarMinPlayersXP)
		return;

	sh_set_user_xp(attacker, CvarObjectiveXP, true);
	sh_chat_message(attacker, _, "You got %d XP for assassinating the VIP", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPEscaped()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	if (get_playersnum() <= CvarMinPlayersXP)
		return;

	new players[32], playerCount, player;
	new XPtoGive = CvarObjectiveXP;

	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);

	// VIP is considered dead at this point, so we have to check dead players to find him
	for (new i = 0; i < playerCount; i++) {
		player = players[i];

		if (player == gXpBonusVIP || (is_user_alive(player) && cs_get_user_team(player) == CS_TEAM_CT)) {
			sh_set_user_xp(player, XPtoGive, true);
			sh_chat_message(player, _, "Your team got %d XP for a successful VIP esacpe", XPtoGive);
		}
	}
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPUserSpawned()
{
	// Save if user is a vip here instead of checking cs_get_user_vip all thru the code
	gXpBonusVIP = getLoguserIndex();
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPUserEscaped()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	new id = getLoguserIndex();

	if (!is_user_connected(id))
		return;

	if (id != gXpBonusVIP)
		return;

	if (cs_get_user_team(id) != CS_TEAM_CT)
		return;

	if (get_playersnum() <= CvarMinPlayersXP)
		return;

	sh_set_user_xp(id, CvarObjectiveXP, true);
	sh_chat_message(id, _, "You got %d XP for escaping as the VIP", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
getLoguserIndex()
{
	static loguser[80], name[32];
	read_logargv(0, loguser, charsmax(loguser));
	parse_loguser(loguser, name, charsmax(name));

	return get_user_index(name);
}
//----------------------------------------------------------------------------------------------
