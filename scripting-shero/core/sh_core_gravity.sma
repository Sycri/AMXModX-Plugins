/* AMX Mod X script.
*
*   [SH] Core: Gravity (sh_core_gravity.sma)
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_objectives>

#pragma semicolon 1

new gSuperHeroCount;

new Float:gHeroMinGravity[SH_MAXHEROS];
new gHeroGravityWeapons[SH_MAXHEROS][31]; // array weapons of weapon's i.e. {4,30} Note:{0}=all

new CvarDebugMessages;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Gravity", SH_VERSION_STR, SH_AUTHOR_STR);
	
	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	
	new weaponName[32];
	for (new id = CSW_P228; id <= CSW_P90; id++) {
		if (get_weaponname(id, weaponName, charsmax(weaponName)))
			RegisterHam(Ham_Item_Deploy, weaponName, "@Forward_Item_Deploy_Post", 1);
	}
	
	bind_pcvar_num(get_cvar_pointer("sh_debug_messages"), CvarDebugMessages);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_gravity");
	
	register_native("sh_set_hero_grav", "@Native_SetHeroGravity");
	register_native("sh_reset_min_gravity", "@Native_ResetMinGravity");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroMinGravity[heroID] > 0.0)
		resetMinGravity(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	setGravityPowers(id);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_grav(heroID, pcvarGravity, const weapons[] = {0}, numofwpns = 1)
@Native_SetHeroGravity()
{
	new heroIndex = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroIndex < 0 || heroIndex >= sh_get_num_heroes())
		return;

	new pcvarGravity = get_param(2);
	new numWpns = get_param(4);

	new weaponList[40];
	get_array(3, weaponList, numWpns);

	//Avoid running this unless debug is high enough
	if (CvarDebugMessages > 2) {
		//Set up the weapon string for the debug message
		new weapons[32], number[3], x;
		for (x = 0; x < numWpns; x++) {
			formatex(number, charsmax(number), "%d", weaponList[x]);
			add(weapons, charsmax(weapons), number);

			if (weaponList[x + 1] != '^0')
				add(weapons, charsmax(weapons), ",");
			else
				break;
		}

		sh_debug_message(0, 3, "Set Min Gravity -> HeroID: %d - Gravity: %.3f - Weapon(s): %s", heroIndex, get_pcvar_float(pcvarGravity), weapons);
	}

	bind_pcvar_float(pcvarGravity, gHeroMinGravity[heroIndex]);
	copy(gHeroGravityWeapons[heroIndex], charsmax(gHeroGravityWeapons[]), weaponList); // Array expected!
}
//----------------------------------------------------------------------------------------------
//native sh_reset_min_gravity(id)
@Native_ResetMinGravity()
{
	resetMinGravity(get_param(1));
}
//----------------------------------------------------------------------------------------------
@Forward_AddPlayerItem_Post(id)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	if (!is_user_alive(id) || !sh_user_is_loaded(id))
		return HAM_IGNORED;

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_GRAVITY)
		return HAM_IGNORED;

	static Float:heroGravity;
	heroGravity = getMinGravity(id, cs_get_user_weapon(id));

	set_user_gravity(id, heroGravity);
	sh_debug_message(id, 5, "Setting Gravity To %f", heroGravity);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_Item_Deploy_Post(weapon)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	static owner;
	owner = pev(weapon, pev_owner);

	if (!is_user_alive(owner) || !sh_user_is_loaded(owner))
		return HAM_IGNORED;

	if (owner == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_GRAVITY)
		return HAM_IGNORED;

	static Float:heroGravity;
	heroGravity = getMinGravity(owner, cs_get_weapon_id(weapon));

	set_user_gravity(owner, heroGravity);
	sh_debug_message(owner, 5, "Setting Gravity To %f", heroGravity);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
resetMinGravity(id)
{
	if (!sh_is_active())
		return;
		
	if (!is_user_alive(id))
		return;
		
	new Float:newGravity = getMinGravity(id, cs_get_user_weapon(id));
	if (get_user_gravity(id) != newGravity)
		// Set to 1.0 or the next lowest Gravity
		set_user_gravity(id, newGravity);
}
//----------------------------------------------------------------------------------------------
setGravityPowers(id)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(id) || !sh_user_is_loaded(id))
		return;

	new Float:oldGravity = 1.0;
	new Float:newGravity = getMinGravity(id, cs_get_user_weapon(id));

	if (oldGravity != newGravity) {
		sh_debug_message(id, 5, "Setting Gravity to %f", newGravity);
		set_user_gravity(id, newGravity);
	}
}
//----------------------------------------------------------------------------------------------
Float:getMinGravity(id, weapon)
{
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_GRAVITY)
		return 1.0;
		
	static heroName[25];
	static Float:returnGravity, Float:heroMinGravity, x, i;
	static playerPowerCount, heroIndex, heroWeapon;
	returnGravity = 1.0;
	playerPowerCount = sh_get_user_powers(id);
	
	for (x = 1; x <= playerPowerCount; x++) {
		heroIndex = sh_get_user_hero(id, x);
		
		if (-1 < heroIndex < gSuperHeroCount) {
			heroMinGravity = gHeroMinGravity[heroIndex];
			if (heroMinGravity <= 0.0)
				continue;
				
			for (i = CSW_NONE; i <= CSW_LAST_WEAPON; i++) {
				heroWeapon = gHeroGravityWeapons[heroIndex][i];

				//Stop checking, end of list
				if (i != CSW_NONE && heroWeapon == CSW_NONE)
					break;

				sh_get_hero_name(heroIndex, heroName, charsmax(heroName));
				sh_debug_message(id, 5, "Looking for Gravity Functions - %s, %d, %d", heroName, heroWeapon, weapon);

				//If 0 or current weapon check max
				if (heroWeapon == CSW_NONE || heroWeapon == weapon) {
					returnGravity = floatmin(returnGravity, heroMinGravity);
					break;
				}
			}
		}
	}
	
	return returnGravity;
}
//----------------------------------------------------------------------------------------------
