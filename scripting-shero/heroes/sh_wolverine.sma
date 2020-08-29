// WOLVERINE!

/* CVARS - copy and paste to shconfig.cfg

//Wolverine
wolv_level 0
wolv_healpoints 3			//The # of HP healed per second
wolv_knifespeed 290			//Speed of wolveine when holding knife
wolv_knifemult 1.35			//Multiplier for knife damage

*/

// v1.17 - JTP - fixed runtime error on damage event if user is already dead
// v1.17.5 - JTP - Added code to allow you to regen to your max heatlh

//---------- User Changeable Defines --------//


// Comment out to force not using the model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
#define USE_WEAPON_MODEL


//------- Do not edit below this point ------//

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_hpap>
#include <sh_core_speed>
#include <sh_core_weapons>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Wolverine";

new bool:gHasWolverine[MAX_PLAYERS + 1];

new CvarHealPoints;

#if defined USE_WEAPON_MODEL
	new const gModel_V_Knife[] = "models/shmod/wolv_knife.mdl";
	new bool:gModelLoaded;
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Wolverine", SH_VERSION_STR, "{HOJ}Batman/JTP10181");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("wolv_level", "0", .has_min = true, .min_val = 0.0);
	new pcvarSpeed = create_cvar("wolv_knifespeed", "290");
	new pcvarKnifeMult = create_cvar("wolv_knifemult", "1.35");
	bind_pcvar_num(create_cvar("wolv_healpoints", "3", .has_min = true, .min_val = 0.0), CvarHealPoints);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Auto-Heal & Claws", "Auto-Heal, Extra Knife Damage and Speed Boost");
	sh_set_hero_speed(gHeroID, pcvarSpeed, 1 << CSW_KNIFE);
	sh_set_hero_dmgmult(gHeroID, pcvarKnifeMult, CSW_KNIFE);

#if defined USE_WEAPON_MODEL
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	if (gModelLoaded)
		RegisterHam(Ham_Item_Deploy, "weapon_knife", "@Forward_Knife_Deploy_Post", 1);
#endif

	// HEAL LOOP
	set_task_ex(1.0, "@Task_WolvLoop", _, _, _, SetTask_Repeat);
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
public plugin_precache()
{
	// Method servers 2 purposes, moron check and optional way to not use the model
	if (file_exists(gModel_V_Knife)) {
		precache_model(gModel_V_Knife);
		gModelLoaded = true;
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_Knife);
		gModelLoaded = false;
	}
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	switch(mode) {
		case SH_HERO_ADD: {
			gHasWolverine[id] = true;
#if defined USE_WEAPON_MODEL
			if (gModelLoaded && get_user_weapon(id) == CSW_KNIFE)
				switch_model(id);
#endif
		}
		case SH_HERO_DROP: {
			gHasWolverine[id] = false;
#if defined USE_WEAPON_MODEL
			if (gModelLoaded && get_user_weapon(id) == CSW_KNIFE)
				reset_model(id);
#endif
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
@Forward_Knife_Deploy_Post(weapon_ent)
{
	if (!sh_is_active())
		return;

	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent);
	
	switch_model(owner);
}
//----------------------------------------------------------------------------------------------
switch_model(index)
{
	if (!is_user_alive(index) || !gHasWolverine[index])
		return;

	if (cs_get_user_shield(index))
		return;
	
	set_pev(index, pev_viewmodel2, gModel_V_Knife);
}
//----------------------------------------------------------------------------------------------
reset_model(index)
{
	if (!is_user_alive(index))
		return;

	if (cs_get_user_shield(index))
		return;
	
	new weaponEnt = cs_get_user_weapon_entity(index);
	
	// Let CS update weapon models
	ExecuteHamB(Ham_Item_Deploy, weaponEnt);
}
//----------------------------------------------------------------------------------------------
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
}
#endif
//----------------------------------------------------------------------------------------------
@Task_WolvLoop()
{
	if (!sh_is_active())
		return;

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		if (gHasWolverine[player])
			sh_add_hp(player, CvarHealPoints);
	}
}
//----------------------------------------------------------------------------------------------
