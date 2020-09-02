/* AMX Mod X script.
*
*	[SH] Core: Objectives (sh_core_objectives.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <csx>
#include <cstrike>
#include <sh_core_main>
#define LIBRARY_HPAP "sh_core_hpap"
#include <sh_core_hpap>
#define LIBRARY_SPEED "sh_core_speed"
#include <sh_core_speed>
#define LIBRARY_GRAVITY "sh_core_gravity"
#include <sh_core_gravity>
#define LIBRARY_WEAPONS "sh_core_weapons"
#include <sh_core_weapons>
#define LIBRARY_EXTRADMG "sh_core_extradamage"
#include <sh_core_extradamage>
#include <sh_core_objectives_const>

#pragma semicolon 1

#define is_user_valid(%1) (1 <= %1 <= MaxClients)

new gNumHostages = 0;
new gXPBonusC4ID = -1;
new gXPBonusVIP;

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
		++gNumHostages;
		
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

	set_module_filter("module_filter");
	set_native_filter("native_filter");
}
//----------------------------------------------------------------------------------------------
public module_filter(const library[])
{
	if (equal(library, LIBRARY_HPAP) || equal(library, LIBRARY_SPEED) || equal(library, LIBRARY_GRAVITY)
	|| equal(library, LIBRARY_WEAPONS) || equal(library, LIBRARY_EXTRADMG))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
//native sh_get_c4_id()
@Native_GetC4_ID(plugin_id, num_params)
{
	return gXPBonusC4ID;
}
//----------------------------------------------------------------------------------------------
//native sh_get_vip_id()
@Native_GetVIP_ID(plugin_id, num_params)
{
	return gXPBonusVIP;
}
//----------------------------------------------------------------------------------------------
//native sh_vip_flags()
@Native_VIPFlags(plugin_id, num_params)
{
	return read_flags(CvarBlockVIP);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id, bool:newRound)
{
	if (!newRound)
		return;
	
	static flags[MAX_PLAYERS];

	if (gXPBonusVIP == id) {
		//Reset block in case flags change during rounds when a player is repeatedly the VIP
		resetBlock(id, flags[id], false);
		flags[id] = read_flags(CvarBlockVIP);
		resetBlock(id, flags[id], true);
	} else {
		if (!flags[id])
			return;

		resetBlock(id, flags[id], false);
		flags[id] = 0;
	}
}
//----------------------------------------------------------------------------------------------
resetBlock(id, flags, bool:set)
{
	if (LibraryExists(LIBRARY_WEAPONS, LibType_Library) && flags & VIP_BLOCK_WEAPONS)
		sh_block_weapons(id, set);

	if (LibraryExists(LIBRARY_HPAP, LibType_Library)) {
		if (flags & VIP_BLOCK_HEALTH) {
			sh_block_add_hp(id, set);
			sh_block_hero_hp(id, set);
		}

		if (flags & VIP_BLOCK_ARMOR) {
			sh_block_add_ap(id, set);
			sh_block_hero_ap(id, set, 200);
		}
	}

	if (LibraryExists(LIBRARY_SPEED, LibType_Library) && flags & VIP_BLOCK_SPEED)
		sh_block_hero_speed(id, set);

	if (LibraryExists(LIBRARY_GRAVITY, LibType_Library) && flags & VIP_BLOCK_GRAVITY)
		sh_block_hero_grav(id, set);

	if (flags & VIP_BLOCK_EXTRADMG) {
		if (LibraryExists(LIBRARY_WEAPONS, LibType_Library)) {
			sh_block_hero_dmgmult(id, set);
			sh_block_hero_defmult(id, set);
		}

		if (LibraryExists(LIBRARY_EXTRADMG, LibType_Library))
			sh_block_extradamage(id, set);
	}
}
//----------------------------------------------------------------------------------------------
@LogEvent_BombHolderSpawned()
{
	new id = getLoguserIndex();

	if (!is_user_valid(id))
		return;

	// Find the Index of the bomb entity and save to be used as the one that gives xp
	new ent = -1;
	while ((ent = cs_find_ent_by_owner(ent, "weapon_c4", id)) != 0) {
		// set ent to XP bomb
		gXPBonusC4ID = ent;
		break;
	}
}
//----------------------------------------------------------------------------------------------
public bomb_planted(planter)
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;
	
	if (!is_user_connected(planter) || !is_valid_ent(gXPBonusC4ID))
		return;

	if (planter != entity_get_edict2(gXPBonusC4ID, EV_ENT_owner))
		return;

	if (cs_get_user_team(planter) != CS_TEAM_T)
		return;

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
		return;

	// Only give this out once per round
	gXPBonusC4ID = -1;
	
	sh_set_user_xp(planter, CvarObjectiveXP, true);
	sh_chat_message(planter, _, "You got %d XP for planting the bomb", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
public bomb_defused(defuser)
{
	// Need to make sure gXPBonusC4ID was the bomb defused?
	if (!sh_is_active() || !CvarObjectiveXP)
		return;
	
	if (!is_user_connected(defuser))
		return;
		
	if (cs_get_user_team(defuser) != CS_TEAM_CT)
		return;
		
	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
		return;
		
	sh_set_user_xp(defuser, CvarObjectiveXP, true);
	sh_chat_message(defuser, _, "You got %d XP for defusing the bomb", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
public bomb_explode(planter, defuser)
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return PLUGIN_CONTINUE;

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
		return PLUGIN_CONTINUE;

	new players[MAX_PLAYERS], playerCount, player;
	new XPtoGive = CvarObjectiveXP;

	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (new i = 0; i < playerCount; ++i) {
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

	if (!is_user_valid(id))
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

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
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

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
		return;

	new players[MAX_PLAYERS], playerCount, player;
	new XPtoGive = CvarObjectiveXP;

	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (new i = 0; i < playerCount; ++i) {
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

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
		return;

	sh_set_user_xp(attacker, CvarObjectiveXP, true);
	sh_chat_message(attacker, _, "You got %d XP for assassinating the VIP", CvarObjectiveXP);
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPEscaped()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
		return;

	new players[MAX_PLAYERS], playerCount, player;
	new XPtoGive = CvarObjectiveXP;

	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);

	// VIP is considered dead at this point, so we have to check dead players to find him
	for (new i = 0; i < playerCount; ++i) {
		player = players[i];

		if (player == gXPBonusVIP || (is_user_alive(player) && cs_get_user_team(player) == CS_TEAM_CT)) {
			sh_set_user_xp(player, XPtoGive, true);
			sh_chat_message(player, _, "Your team got %d XP for a successful VIP esacpe", XPtoGive);
		}
	}
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPUserSpawned()
{
	// Save if user is a vip here instead of checking cs_get_user_vip all thru the code
	gXPBonusVIP = getLoguserIndex();
}
//----------------------------------------------------------------------------------------------
@LogEvent_VIPUserEscaped()
{
	if (!sh_is_active() || !CvarObjectiveXP)
		return;

	new id = getLoguserIndex();

	if (!is_user_connected(id))
		return;

	if (id != gXPBonusVIP)
		return;

	if (cs_get_user_team(id) != CS_TEAM_CT)
		return;

	new activePlayerCount = get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "CT");
	activePlayerCount += get_playersnum_ex(GetPlayers_ExcludeHLTV | GetPlayers_MatchTeam, "TERRORIST");

	if (activePlayerCount <= CvarMinPlayersXP)
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
