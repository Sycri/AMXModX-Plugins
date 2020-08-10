// MADNESS! - The animated flash characters, from http://www.madnesscombat.com/

/* CVARS - copy and paste to shconfig.cfg

//Madness
madness_level 9
madness_health 200		//How much health madness has
madness_armor 100		//How much armor madness has
madness_m3mult 2.0		//Damage multiplier for his M3

*/

/*
* v1.3 - vittu - 6/21/05
*      - Minor code clean up.
*
*  Ripped from the hero - Morpheus (by RadidEskimo & Freecode).
*  Weapon model by Eichler69 & Biohazard
*/

//---------- User Changeable Defines --------//

// 0-follow server sh_reloadmode cvar setting [Default]
// 1-no reload, continuous shooting
// 2-reload, but backpack ammo never depletes
// 3-drop weapon and get a new one with full clip
// 4-normal cs, reload and backpack ammo depletes
#define AMMO_MODE 0

// Comment out to force not using the model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
#define USE_WEAPON_MODEL

// Comment out to not give a free M3
#define GIVE_WEAPON

//------- Do not edit below this point ------//

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Madness"
new bool:gHasMadness[SH_MAXSLOTS+1]

#if defined USE_WEAPON_MODEL
	new const gModel_V_M3[] = "models/shmod/madness_m3.mdl"
	new bool:gModelLoaded
#endif
//----------------------------------------------------------------------------------------------
public plugin_init() {
	// Plugin Info
	register_plugin("SUPERHERO Madness", "1.4", "Assassin")
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("madness_level", "9")
	new pcvarHealth = register_cvar("madness_health", "200")
	new pcvarArmor = register_cvar("madness_armor", "100")
	new pcvarM3Mult = register_cvar("madness_m3mult", "2.0")
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Dual M3's", "Dual M3's/Extra Damage/Unlimited Ammo. Extra HP and AP.")
	sh_set_hero_hpap(gHeroID, pcvarHealth, pcvarArmor)
	sh_set_hero_dmgmult(gHeroID, pcvarM3Mult, CSW_M3)
	
#if defined GIVE_WEAPON
	sh_set_hero_shield(gHeroID, true)
#endif
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
#if AMMO_MODE < 4 || defined USE_WEAPON_MODEL
	register_event("CurWeapon", "weapon_change", "be", "1=1")
#endif
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
public plugin_precache() {
	if(file_exists(gModel_V_M3)) {
		precache_model(gModel_V_M3)
		gModelLoaded = true
	}
	else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_M3)
		gModelLoaded = false
	}
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode) {
	if(gHeroID != heroID) return
	
	if(is_user_alive(id)) {
		switch(mode) {
			case SH_HERO_ADD: {
#if defined GIVE_WEAPON
				sh_give_weapon(id, CSW_M3)
#endif
#if defined USE_WEAPON_MODEL
				if(gModelLoaded && get_user_weapon(id) == CSW_M3) switch_model(id)
#endif
			}
#if defined GIVE_WEAPON
			case SH_HERO_DROP: sh_drop_weapon(id, CSW_M3, true)
#endif
		}
	}
	
	gHasMadness[id] = mode ? true : false
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
#if defined GIVE_WEAPON
public sh_client_spawn(id) {
	if(!gHasMadness[id]) return
	
	sh_give_weapon(id, CSW_M3)
}
#endif
//----------------------------------------------------------------------------------------------
#if AMMO_MODE < 4 || defined USE_WEAPON_MODEL
public weapon_change(id) {
	if(!sh_is_active() || !gHasMadness[id]) return
	
	if(read_data(2) != CSW_M3) return
	
#if defined USE_WEAPON_MODEL
	if(gModelLoaded ) switch_model(id)
#endif
	
#if AMMO_MODE < 4
	if(read_data(3) == 0 ) sh_reload_ammo(id, AMMO_MODE)
#endif
}
#endif
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
switch_model(id) {
	if(!sh_is_active() || !is_user_alive(id)) return
	
	set_pev(id, pev_viewmodel2, gModel_V_M3)
}
#endif
//----------------------------------------------------------------------------------------------