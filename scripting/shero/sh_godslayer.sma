// GOD SLAYER!

/* CVARS - copy and paste to shconfig.cfg

//God Slayer
godslayer_level 8

*/

#include <superheromod>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "God Slayer";

new bool:gHasGodSlayer[MAX_PLAYERS + 1];
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO God Slayer", "1.1", "Sycri (Kristaps08)");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("godslayer_level", "8", .has_min = true, .min_val = 0.0);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Divinity Slaying", "Destroy your enemies' godmode shields");
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	RegisterHamPlayer(Ham_TraceAttack, "@Forward_Player_TraceAttack_Pre");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	gHasGodSlayer[id] = mode ? true : false;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TraceAttack_Pre(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if (!sh_is_active() || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	if (!gHasGodSlayer[attacker] || victim == attacker)
		return HAM_IGNORED;
	
	if (!(damagebits & DMG_BULLET) && !(damagebits & DMG_SLASH))
		return HAM_IGNORED;
	
	if(get_user_godmode(victim) && (cs_get_user_team(victim) != cs_get_user_team(attacker) || sh_friendlyfire_on()))
		set_user_godmode(victim, 0);
	
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
