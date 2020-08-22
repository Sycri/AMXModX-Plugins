// BLACK PANTHER! from Marvel Comics!
// Hero Originally named Windwalker, changed since there is no such character.

/* CVARS - copy and paste to shconfig.cfg

//Black Panther
blackpanther_level 0

*/

#include <amxmodx>
#include <fakemeta>
#include <sh_core_main>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Black Panther";

new bool:gHasBlackPanther[MAX_PLAYERS + 1];
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Black Panther", SH_VERSION_STR, "AssKicR/JTP10181");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("blackpanther_level", "0", .has_min = true, .min_val = 0.0);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Silent Boots", "Your boots have Vibranium soles that absorb sound");

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	register_forward(FM_PlayerPreThink, "@Forward_PlayerPreThink");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	gHasBlackPanther[id] = mode ? true : false;

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Forward_PlayerPreThink(id)
{
	if (sh_is_active() && is_user_alive(id) && gHasBlackPanther[id]) {
		set_pev(id, pev_flTimeStepSound, 999);
	}
}
//----------------------------------------------------------------------------------------------