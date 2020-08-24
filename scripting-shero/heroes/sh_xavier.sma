// XAVIER! - BASED ON SPACEDUDE'S NEW XTRAFUNMOD - FORGOT WHERE I FOUND THE TRACEME CODE
// 1.14.4 - significant change - no xtrafun needed for this now...

/* CVARS - copy and paste to shconfig.cfg

//Xavier
xavier_level 7
xavier_traillength 25			//Length of trail behind players
xavier_showteam 0			//Show trails on your team
xavier_showenemy 1			//Show trails on enemies
xavier_refreshtimer 5.0			//How often do the trails refresh

*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sh_core_main>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Xavier";

new bool:gHasXavier[MAX_PLAYERS + 1];

new CvarTrailLength, CvarShowTeam, CvarShowEnemy;
new Float:CvarRefreshTimer;

new gSpriteLaserBeam;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Xavier", SH_VERSION_STR, "{HOJ} Batman");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("xavier_level", "7", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("xavier_traillength", "25", .has_min = true, .min_val = 0.0), CvarTrailLength);
	bind_pcvar_num(create_cvar("xavier_showteam", "0"), CvarShowTeam);
	bind_pcvar_num(create_cvar("xavier_showenemy", "1"), CvarShowEnemy);
	bind_pcvar_float(create_cvar("xavier_refreshtimer", "5.0", .has_min = true, .min_val = 0.1), CvarRefreshTimer);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Team Detection", "Detect what team a player is on by a glowing trail");
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSpriteLaserBeam = precache_model("sprites/laserbeam.spr");
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	remove_task(id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	// Clear out any stale tasks
	remove_task(id);

	switch(mode) {
		case SH_HERO_ADD: {
			gHasXavier[id] = true;
			@Task_AddAllMarks(id);
			set_task_ex(CvarRefreshTimer, "@Task_AddAllMarks", id, _, _, SetTask_Repeat);
		}
		case SH_HERO_DROP: {
			gHasXavier[id] = false;
			remove_all_marks(id);
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (!gHasXavier[id])
		return;

	@Task_AddAllMarks(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim)
{
	if (!sh_is_active())
		return;

	remove_all_marks(victim);
}
//----------------------------------------------------------------------------------------------
@Task_AddAllMarks(id)
{
	if (!sh_is_active() || !is_user_alive(id) || !gHasXavier[id])
		return;

	static bool:sameTeam;
	static CsTeams:idTeam;
	static CsTeams:playerTeam;

	idTeam = cs_get_user_team(id);

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		if (player == id)
			continue;

		playerTeam = cs_get_user_team(player);

		sameTeam = idTeam == playerTeam;

		if ((sameTeam && CvarShowTeam) || (!sameTeam && CvarShowEnemy)) {
			remove_mark(id, player);

			switch(playerTeam) {
				case CS_TEAM_T: make_trail(id, player, 255, 0, 0);
				case CS_TEAM_CT: make_trail(id, player, 0, 0, 255);
				default: make_trail(id, player, 255, 255, 255);
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
make_trail(id, player, red, green, blue)
{
	if (!sh_is_active() || !is_user_alive(id) || !is_user_alive(player))
		return;

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_BEAMFOLLOW);
	write_short(player);
	write_short(gSpriteLaserBeam);
	write_byte(CvarTrailLength);//length
	write_byte(8); //width
	write_byte(red); //red
	write_byte(green); //green
	write_byte(blue); //blue
	write_byte(150); //bright
	message_end();
}
//----------------------------------------------------------------------------------------------
remove_all_marks(id)
{
	if (is_user_connected(id) && gHasXavier[id]) {
		new players[MAX_PLAYERS], playerCount, player;
		get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

		for (new i = 0; i < playerCount; ++i) {
			player = players[i];

			if (player == id)
				continue;

			remove_mark(id, player);
		}
	}
}
//----------------------------------------------------------------------------------------------
remove_mark(id, player)
{
	if (!is_user_connected(id) || !is_user_connected(player))
		return;

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_KILLBEAM);
	write_short(player);
	message_end();
}
//----------------------------------------------------------------------------------------------