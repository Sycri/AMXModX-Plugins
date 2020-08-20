// THE TICK! - from The Tick, The big blue arachnid who is nigh invunerable.
// Based on v3x's "No fall damage" 0.2, off of leakgfhp's method.

/* CVARS - copy and paste to shconfig.cfg

//The Tick
thetick_level 0

*/

/*
* v1.3 - vittu - 8/18/08
*       - Improved no fall damage method based on suggestion by Guilty Spark.
*       - Updated to be SH 1.2.0 compliant.
*
* v1.2 - vittu - 7/19/06
*       - Converted to fakemeta.
*
* v1.1 - vittu - 3/31/06
*       - Small code changes.
*
*/

#include <superheromod>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "The Tick";

new bool:gHasTheTick[MAX_PLAYERS + 1];
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO The Tick", "1.4", "vittu");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("thetick_level", "0", .has_min = true, .min_val = 0.0);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "No Fall Damage", "SPOOOON! Take no damage from falling");

	RegisterHamPlayer(Ham_TakeDamage, "@Forward_Player_TakeDamage");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	gHasTheTick[id] = mode ? true : false;

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (damagebits & DMG_FALL && gHasTheTick[victim])
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------