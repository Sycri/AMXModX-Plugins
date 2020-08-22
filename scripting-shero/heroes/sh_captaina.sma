// CAPTAIN AMERICA!

/* CVARS - copy and paste to shconfig.cfg

//Captain America
captaina_level 0
captaina_pctperlev 0.02		//Percentage that factors into godmode randomness (Default 0.02)
captaina_godsecs 1.0		//# of seconds of god mode

*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <sh_core_main>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Captain America";

new bool:gHasCaptainAmerica[MAX_PLAYERS + 1];
new Float:gMaxLevelFactor;

new Float:CvarPercentPerLevel, Float:CvarGodSecs;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Captain America", SH_VERSION_STR, "{HOJ} Batman/JTP10181");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("captaina_level", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(create_cvar("captaina_pctperlev", "0.02", .has_min = true, .min_val = 0.0), CvarPercentPerLevel);
	bind_pcvar_float(create_cvar("captaina_godsecs", "1.0", .has_min = true, .min_val = 0.0), CvarGodSecs);

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Super Shield", "Random Invincibility, better chance the higher your level");

	// OK Random Generator
	set_task_ex(1.0, "@Task_CaptainALoop", _, _, _, SetTask_Repeat);
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	// Check here so sh_get_num_lvls has time to set itself
	gMaxLevelFactor = (10.0 / sh_get_num_lvls()) * 100.0;
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	gHasCaptainAmerica[id] = mode ? true : false;

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Task_CaptainALoop()
{
	if (!sh_is_active())
		return;

	static heroLevel;

	static players[32], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; i++) {
		player = players[i];

		if (gHasCaptainAmerica[player] && !get_user_godmode(player)) {
			heroLevel = floatround(sh_get_user_lvl(player) * CvarPercentPerLevel * gMaxLevelFactor);

			if (heroLevel >= random_num(0, 100)) {
				sh_set_godmode(player, CvarGodSecs);

				//Quick Blue Screen Flash Letting You know about god mode
				sh_screen_fade(player, CvarGodSecs, CvarGodSecs / 2, 0, 0, 255, 50, SH_FFADE_MODULATE);
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
