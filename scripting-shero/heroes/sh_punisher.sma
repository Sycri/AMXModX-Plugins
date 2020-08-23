// PUNISHER! - Unlimited Ammo

/* CVARS - copy and paste to shconfig.cfg

//Punisher
punisher_level 0
punisher_rldmode 0		// Endless Ammo mode: 0-server default, 1-no reload, 2-reload, 3-drop wpn (Default 1)

*/

#include <amxmodx>
#include <sh_core_main>
#include <sh_core_weapons>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Punisher";

new bool:gHasPunisher[MAX_PLAYERS + 1];

new CvarReloadMode;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Punisher", SH_VERSION_STR, "{HOJ} Batman");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("punisher_level", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("punisher_rldmode", "0"), CvarReloadMode);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Unlimited Ammo", "Endless Bullets. No Reload! Keep Shooting");

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	// new clip = read_data(3) == 0
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "3=0");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	gHasPunisher[id] = mode ? true : false;

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasPunisher[id])
		return;

	//new wpnid = read_data(2)
	new wpnslot = sh_get_weapon_slot(read_data(2));

	if (wpnslot != 1 && wpnslot != 2)
		return;

	sh_reload_ammo(id, CvarReloadMode);
}
//----------------------------------------------------------------------------------------------
