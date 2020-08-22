// MADNESS! - The animated flash characters, from http://www.madnesscombat.com/

/* CVARS - copy and paste to shconfig.cfg

//Madness
madness_level 9
madness_health 200		//How much health madness has
madness_armor 100		//How much armor madness has
madness_m3mult 2.0		//Damage multiplier for his M3
madness_rldmode 0		//Endless ammo mode: 0-server default, 1-no reload, 2-reload, 3-drop wpn

*/

/*
* v1.3 - vittu - 6/21/05
*      - Minor code clean up.
*
*  Ripped from the hero - Morpheus (by RadidEskimo & Freecode).
*  Weapon model by Eichler69 & Biohazard
*/

//---------- User Changeable Defines --------//


// Comment out to force not using the model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
#define USE_WEAPON_MODEL

// Comment out to not give a free M3
#define GIVE_WEAPON


//------- Do not edit below this point ------//

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_hpap>
#include <sh_core_shieldrestrict>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Madness";

new bool:gHasMadness[MAX_PLAYERS + 1];

new CvarReloadMode;

#if defined USE_WEAPON_MODEL
	new const gModel_V_M3[] = "models/shmod/madness_m3.mdl";
	new bool:gModelLoaded;
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Madness", "1.4", "Assassin");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("madness_level", "9", .has_min = true, .min_val = 0.0);
	new pcvarHealth = create_cvar("madness_health", "200");
	new pcvarArmor = create_cvar("madness_armor", "100");
	new pcvarM3Mult = create_cvar("madness_m3mult", "2.0");
	bind_pcvar_num(create_cvar("madness_rldmode", "0"), CvarReloadMode);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Dual M3's", "Dual M3's/Extra Damage/Unlimited Ammo. Extra HP and AP");
	sh_set_hero_hpap(gHeroID, pcvarHealth, pcvarArmor);
	sh_set_hero_dmgmult(gHeroID, pcvarM3Mult, CSW_M3);
	
#if defined GIVE_WEAPON
	sh_set_hero_shield(gHeroID, true);
#endif
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	// read_data(2) == CSW_M3 = 2=21
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "2=21", "3=0");
#if defined USE_WEAPON_MODEL
	if (gModelLoaded)
		RegisterHam(Ham_Item_Deploy, "weapon_m3", "@Forward_M3_Deploy_Post", 1);
#endif
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
public plugin_precache()
{
	if(file_exists(gModel_V_M3)) {
		precache_model(gModel_V_M3);
		gModelLoaded = true;
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_M3);
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
			gHasMadness[id] = true;
#if defined GIVE_WEAPON
			sh_give_weapon(id, CSW_M3);
#endif
#if defined USE_WEAPON_MODEL
			if (gModelLoaded && get_user_weapon(id) == CSW_M3)
				switch_model(id);
#endif
		}
		case SH_HERO_DROP: {
			gHasMadness[id] = false;
#if defined GIVE_WEAPON
			sh_drop_weapon(id, CSW_M3, true);
#endif
		}
	}
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
#if defined GIVE_WEAPON
public sh_client_spawn(id)
{
	if (!gHasMadness[id])
		return;
	
	sh_give_weapon(id, CSW_M3);
}
#endif
//----------------------------------------------------------------------------------------------
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasMadness[id])
		return;
	
	sh_reload_ammo(id, CvarReloadMode);
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
@Forward_M3_Deploy_Post(weapon_ent)
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
	if (!is_user_alive(index) || !gHasMadness[index])
		return;

	if (cs_get_user_shield(index))
		return;
	
	set_pev(index, pev_viewmodel2, gModel_V_M3);
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
