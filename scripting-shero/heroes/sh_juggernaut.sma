// Juggernaut! - from The X-Men!

/* CVARS - copy and paste to shconfig.cfg

//Juggernaut
juggernaut_level 5
juggernaut_armor 500			//Juggernaut's armor (Def=500)
juggernaut_paintolerance 150	//Amount of pain that Juggernaut can endure until he must stop (Def=150)

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_hpap>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Juggernaut";

new bool:gHasJuggernaut[MAX_PLAYERS + 1];

new Float:CvarPainTolerance;
//----------------------------------------------------------------------------------------------
public plugin_init() {
	// Plugin Info
	register_plugin("SUPERHERO Juggernaut", "1.1", "Sycri");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("juggernaut_level", "5", .has_min = true, .min_val = 0.0);
	new pcvarArmor = create_cvar("juggernaut_armor", "500");
	bind_pcvar_float(create_cvar("juggernaut_paintolerance", "150", .has_min = true, .min_val = 0.0), CvarPainTolerance);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Unstoppable Movement", "You can resist some damage to continue running! Also have tons of armor");
	sh_set_hero_hpap(gHeroID, _, pcvarArmor);
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	RegisterHamPlayer(Ham_TakeDamage, "@Forward_Player_TakeDamage_Post", 1);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	gHasJuggernaut[id] = mode ? true : false;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!sh_is_active() || !gHasJuggernaut[victim])
		return HAM_IGNORED;
	
	if (damage > CvarPainTolerance)
		return HAM_IGNORED;
	
	set_ent_data_float(victim, "CBasePlayer", "m_flVelocityModifier", 1.0);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
