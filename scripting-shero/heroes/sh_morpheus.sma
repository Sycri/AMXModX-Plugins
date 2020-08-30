// Morpheus! - The Main Man of the Matrix

/* CVARS - copy and paste to shconfig.cfg

//Morpheus
morpheus_level 8
morpheus_gravity 0.35	//Gravity Morpheus has
morpheus_mp5mult 2.0	//Damage multiplier for his MP5
morpheus_rldmode 0		//Endless ammo mode: 0-server default, 1-no reload, 2-reload, 3-drop wpn

*/

//---------- User Changeable Defines --------//


// Comment out to force not using the model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
#define USE_WEAPON_MODEL

// Comment out to not give a free MP5
#define GIVE_WEAPON


//------- Do not edit below this point ------//

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_gravity>
#include <sh_core_weapons>

#if defined USE_WEAPON_MODEL
	#include <cstrike>
#endif

#if defined GIVE_WEAPON
	#include <sh_core_shieldrestrict>
#endif

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Morpheus";

new bool:gHasMorpheus[MAX_PLAYERS + 1];

new CvarReloadMode;

#if defined USE_WEAPON_MODEL
	new const gModel_V_MP5[] = "models/shmod/morpheus_mp5.mdl";
	new bool:gModelLoaded;
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Morpheus", SH_VERSION_STR, "RadidEskimo/Freecode");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("morpheus_level", "8", .has_min = true, .min_val = 0.0);
	new pcvarGravity = create_cvar("morpheus_gravity", "0.35");
	new pcvarMP5Mult = create_cvar("morpheus_mp5mult", "2.0");
	bind_pcvar_num(create_cvar("morpheus_rldmode", "0"), CvarReloadMode);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Dual MP5's", "Lower Gravity/Dual MP5's/Unlimited Ammo");
	sh_set_hero_grav(gHeroID, pcvarGravity);
	sh_set_hero_dmgmult(gHeroID, pcvarMP5Mult, CSW_MP5NAVY);
#if defined GIVE_WEAPON
	sh_set_hero_shield(gHeroID, true);
#endif

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	// read_data(2) == CSW_MP5NAVY = 2=19
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "2=19", "3=0");
#if defined USE_WEAPON_MODEL
	if (gModelLoaded)
		RegisterHam(Ham_Item_Deploy, "weapon_mp5navy", "@Forward_MP5Navy_Deploy_Post", 1);
#endif
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
public plugin_precache()
{
	// Method servers 2 purposes, moron check and optional way to not use the model
	if (file_exists(gModel_V_MP5)) {
		precache_model(gModel_V_MP5);
		gModelLoaded = true;
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_MP5);
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
			gHasMorpheus[id] = true;
#if defined GIVE_WEAPON
			sh_give_weapon(id, CSW_MP5NAVY);
#endif
#if defined USE_WEAPON_MODEL
			if (gModelLoaded && get_user_weapon(id) == CSW_MP5NAVY)
				switch_model(id);
#endif
		}

		case SH_HERO_DROP: {
			gHasMorpheus[id] = false;
#if defined GIVE_WEAPON
			sh_drop_weapon(id, CSW_MP5NAVY, true);
#endif
#if !defined GIVE_WEAPON && defined USE_WEAPON_MODEL
			if (gModelLoaded && get_user_weapon(id) == CSW_MP5NAVY)
				reset_model(id);
#endif
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
#if defined GIVE_WEAPON
public sh_client_spawn(id)
{
	if (!gHasMorpheus[id])
		return;

	sh_give_weapon(id, CSW_MP5NAVY);
}
#endif
//----------------------------------------------------------------------------------------------
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasMorpheus[id])
		return;
	
	sh_reload_ammo(id, CvarReloadMode);
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
@Forward_MP5Navy_Deploy_Post(weapon_ent)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	// Get weapon's owner
	new owner = get_ent_data_entity(weapon_ent, "CBasePlayerItem", "m_pPlayer");
	
	switch_model(owner);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
switch_model(index)
{
	if (!is_user_alive(index) || !gHasMorpheus[index])
		return;
	
	set_pev(index, pev_viewmodel2, gModel_V_MP5);
}
//----------------------------------------------------------------------------------------------
#if !defined GIVE_WEAPON
reset_model(index)
{
	if (!is_user_alive(index))
		return;
	
	new weaponEnt = cs_get_user_weapon_entity(index);
	
	// Let CS update weapon models
	ExecuteHamB(Ham_Item_Deploy, weaponEnt);
}
#endif
#endif
//----------------------------------------------------------------------------------------------
