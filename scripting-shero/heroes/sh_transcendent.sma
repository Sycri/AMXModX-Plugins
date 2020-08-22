// Transcendent - Evolve to become a higher level of existence

/* CVARS - copy and paste to shconfig.cfg

//Transcendent
transcendent_level 10
transcendent_health 1000			//Transcendent's health. (Def=1000)
transcendent_damagemulti 3.0		//Damage X this cvar = New Damage. (Def=3.0)
transcendent_defensemulti 0.2		//Damage X this cvar = New Damage. (Def=0.2)

*/

#include <amxmodx>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_hpap>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Transcendent";

new bool:gIsTranscendent[MAX_PLAYERS + 1];

new Float:CvarDamageMult, Float:CvarDefenseMult;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Transcendent", "1.1", "Sycri (Kristaps08)");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("transcendent_level", "10", .has_min = true, .min_val = 0.0);
	new pcvarHealth = create_cvar("transcendent_health", "1000");
	bind_pcvar_float(create_cvar("transcendent_damagemulti", "3.0", .has_min = true, .min_val = 0.0), CvarDamageMult);
	bind_pcvar_float(create_cvar("transcendent_defensemulti", "0.2", .has_min = true, .min_val = 0.0), CvarDefenseMult);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Higher Level Existence", "Massive increase in lifeforce. Regular attacks are infused and defended with divinity");
	sh_set_hero_hpap(gHeroID, pcvarHealth);
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	RegisterHamPlayer(Ham_TakeDamage, "@Forward_Player_TakeDamage_Pre");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	gIsTranscendent[id] = mode ? true : false;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!sh_is_active() || !is_user_connected(attacker) || victim == attacker)
		return HAM_IGNORED;

	static isTranscendent;
	isTranscendent = false;
	
	if (gIsTranscendent[attacker]) {
		isTranscendent = true;
		SetHamParamFloat(4, damage *= CvarDamageMult);
	}
	
	if (gIsTranscendent[victim]) {
		SetHamParamFloat(4, damage *= CvarDefenseMult);
		isTranscendent = true;
	}

	if (isTranscendent)
		return HAM_HANDLED;
	
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
