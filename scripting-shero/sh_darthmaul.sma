// DARTH MAUL! evil Sith apprentice from Star Wars - Episode I: The Phantom Menace. Double Bladed Lightsaber is his trademark.

/* CVARS - copy and paste to shconfig.cfg

//Darth Maul
darth_level 6
darth_healpoints 10			//the # of HP healed per second
darth_knifespeed 400		//speed of Darth Maul in knife mode
darth_knifemult 2.70		//multiplier for knife damage...

*/

/*
* v1.4 - vittu - 3/10/11
*      - Changed model change method to use Ham_Item_Deploy instead of the CurWeapon event.
*
* v1.3 - vittu - 3/8/11
*      - Updated to SH 1.2.0.14 or above.
*      - Added define to disable use of weapon models.
*
* v1.2 - vittu - 6/19/05
*      - Minor code clean up.
*      - Added p_ knife model.
*
* v1.1 - vittu - 12/21/04
*      -SH mod 1.17.6 and up only
*      -Model name and location changed (to follow new standard)
*      -Also only needed one of the models not both (deleted useless second model)
*      -Now heals past 100hp if you have more
*      -Fixed extra speed to use knife
*
*   Darth Maul based on {HOJ}Batman's wolverine hero which is where most of the credit should go
*/

//---------- User Changeable Defines --------//


// Comment out to force not using the model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
#define USE_WEAPON_MODEL


//------- Do not edit below this point ------//

#include <superheromod>
#include <amxmisc>

#pragma semicolon 1

// CS Weapon CBase Offsets (win32)
const PDATA_SAFE = 2;
const OFFSET_WEAPONOWNER = 41;
const OFFSET_LINUX_WEAPONS = 4;

// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373;

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Darth Maul";

new bool:gHasDarthMaul[MAX_PLAYERS + 1];

new CvarHealPoints;

#if defined USE_WEAPON_MODEL
	new const gModel_V_Knife[] = "models/shmod/darthmaul_knife.mdl";
	new const gModel_P_Knife[] = "models/shmod/darthmaul_p_knife.mdl";
	new bool:gModelLoaded;
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Darth Maul", "1.5", "Chivas2973");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("darth_level", "6", .has_min = true, .min_val = 0.0);
	new pcvarKnifeSpeed = create_cvar("darth_knifespeed", "400");
	new pcvarKnifeMult = create_cvar("darth_knifemult", "2.70", .has_min = true, .min_val = 1.0);
	bind_pcvar_num(create_cvar("darth_healpoints", "10", .has_min = true, .min_val = 0.0), CvarHealPoints);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero("Darth Maul", pcvarLevel);
	sh_set_hero_info(gHeroID, "Sith Lightsaber & Regen", "Get a Sith Double Bladed Lightsaber with more Damage and Speed, also regenerate HP");
	sh_set_hero_speed(gHeroID, pcvarKnifeSpeed, {CSW_KNIFE});
	sh_set_hero_dmgmult(gHeroID, pcvarKnifeMult, CSW_KNIFE);

#if defined USE_WEAPON_MODEL
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	if (gModelLoaded)
		RegisterHam(Ham_Item_Deploy, "weapon_knife", "@Forward_Knife_Deploy_Post", 1);
#endif

	// HEAL LOOP
	set_task_ex(1.0, "@Task_DarthLoop", _, _, _, SetTask_Repeat);
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
public plugin_precache()
{
	// Method serves 2 purposes, moron check and optional way to not use the model
	// Seperate checks so the model that is missing can be reported
	gModelLoaded = true;
	if (file_exists(gModel_V_Knife)) {
		precache_model(gModel_V_Knife);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_Knife);
		gModelLoaded = false;
	}

	if (file_exists(gModel_P_Knife)) {
		precache_model(gModel_P_Knife);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_P_Knife);
		gModelLoaded = false;
	}
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	switch (mode) {
		case SH_HERO_ADD: {
			gHasDarthMaul[id] = true;
#if defined USE_WEAPON_MODEL
			if (gModelLoaded && get_user_weapon(id) == CSW_KNIFE)
				switch_model(id);
#endif
		}
		case SH_HERO_DROP: {
			gHasDarthMaul[id] = false;
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
	if (!is_user_alive(index) || !gHasDarthMaul[index])
		return;

	if (cs_get_user_shield(index))
		return;
	
	set_pev(index, pev_viewmodel2, gModel_V_Knife);
	set_pev(index, pev_weaponmodel2, gModel_P_Knife);
}
//----------------------------------------------------------------------------------------------
reset_model(index)
{
	if (!is_user_alive(index))
		return;

	if (cs_get_user_shield(index))
		return;
	
	new weaponEnt = fm_cs_get_current_weapon_ent(index);
	
	// Let CS update weapon models
	ExecuteHamB(Ham_Item_Deploy, weaponEnt);
}
//----------------------------------------------------------------------------------------------
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}
//----------------------------------------------------------------------------------------------
stock fm_cs_get_current_weapon_ent(index)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(index) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(index, OFFSET_ACTIVE_ITEM);
}
#endif
//----------------------------------------------------------------------------------------------
@Task_DarthLoop()
{
	if (!sh_is_active())
		return;

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; i++) {
		player = players[i];

		if (gHasDarthMaul[player])
			sh_add_hp(player, CvarHealPoints);
	}
}
//----------------------------------------------------------------------------------------------