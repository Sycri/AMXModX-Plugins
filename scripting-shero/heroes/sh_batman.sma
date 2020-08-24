//BATMAN! - Yeah - well not all of his powers or it'd be unfair...

/* CVARS - copy and paste to shconfig.cfg

//Batman
batman_level 0
batman_health 125		//default 125
batman_armor 125		//defualt 125

*/

/*
* v1.17 - JTP10181 - 07/23/04
*       - Fixed issue where you could get zoomed in on other primaries if combined with punisher
*
* 5/17 - Took out ammo give to test for a bug
*        + Punisher gets unlimited ammo - so this is desired not to make
*        batman so powerful.  Batman is split between Batman and Punisher
*/

#include <amxmodx>
#include <cstrike>
#include <sh_core_main>
#include <sh_core_hpap>
#include <sh_core_weapons>
#include <sh_core_shieldrestrict>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Batman";

new bool:gHasBatman[MAX_PLAYERS + 1];
new gCurrentWeapon[MAX_PLAYERS + 1];
new gmsgSetFOV;

const giveTotal = 8;
new weapArray[giveTotal] = {
	CSW_FLASHBANG,
	CSW_SMOKEGRENADE,
	CSW_DEAGLE,
	CSW_MP5NAVY,
	CSW_XM1014,
	CSW_SG552,
	CSW_AWP,
	CSW_M4A1
};
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Batman", SH_VERSION_STR, "{HOJ} Batman/JTP10181");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("batman_level", "0", .has_min = true, .min_val = 0.0);
	new pcvarHealth = create_cvar("batman_health", "125");
	new pcvarArmor = create_cvar("batman_armor", "125");

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Utility Belt", "Extra Weapons and HP/AP - Buy the Ammo or Use with Punisher");
	sh_set_hero_hpap(gHeroID, pcvarHealth, pcvarArmor);
	sh_set_hero_shield(gHeroID, true);

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1");

	gmsgSetFOV = get_user_msgid("SetFOV");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	switch (mode) {
		case SH_HERO_ADD: {
			gHasBatman[id] = true;
			give_weapons(id);
		}
		case SH_HERO_DROP: {
			gHasBatman[id] = false;
			drop_weapons(id);
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (gHasBatman[id])
		give_weapons(id);
}
//----------------------------------------------------------------------------------------------
give_weapons(index)
{
	if (!is_user_alive(index))
		return;

	for (new i = 0; i < giveTotal; ++i)
		sh_give_weapon(index, weapArray[i]);

	// Give CTs a Defuse Kit
	if (cs_get_user_team(index) == CS_TEAM_CT)
		sh_give_item(index, "item_thighpack");
}
//----------------------------------------------------------------------------------------------
drop_weapons(index)
{
	if (!is_user_alive(index))
		return;

	// Start at 2 since 0 and 1 are nades that can not be dropped
	for (new i = 2; i < giveTotal; ++i)
		sh_drop_weapon(index, weapArray[i], true);
}
//----------------------------------------------------------------------------------------------
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasBatman[id])
		return;

	new weaponid = read_data(2);

	if (gCurrentWeapon[id] != weaponid) {
		gCurrentWeapon[id] = weaponid;
		// This avoids some issues with shotguns being zoomed, and maybe other weapons
		weapon_zoomout(id);
	}
}
//----------------------------------------------------------------------------------------------
weapon_zoomout(index)
{
	if (!is_user_alive(index))
		return;

	message_begin(MSG_ONE, gmsgSetFOV, _, index);
	write_byte(90); // Not zooming
	message_end();
}
//----------------------------------------------------------------------------------------------
