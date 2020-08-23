
#if defined _sh_core_weapons_included
  #endinput
#endif
#define _sh_core_weapons_included

#pragma reqlib sh_core_weapons
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_weapons
#endif

#include <cstrike_const>
#include <sh_core_weapons_const>

/**************************
 *        NATIVES         *
 **************************/

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Sets hero's damage multiplier for the specified cs/cz weapon. (Optional)
 * Multipliers do not stack, values from user's heroes are compared and greatest is applied.
 * If multiple weapons required, native must be called separately for each weapon.
 *
 * @note		A Multiplier value of 1.0 or below is ignored.
 *				Multiplier is applied before armor reduces damage.
 *
 * @param heroID	The index of the hero.
 * @param pcvarWpnMult	The pcvar value of the damage multiplier CVAR for the specified weaponID.
 * @param weaponID	The CSW_ constant of the weapon to set damage multiplier for, 0 is for all weapons. (see cstrike_const.inc)
 * @noreturn
 */
native sh_set_hero_dmgmult(heroID, pcvarWpnMult, const weaponID = 0);

//------------

/**
 * Forces client to drop weapon if they have it in inventory.
 *
 * @param id		The index of the client.
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @param remove	Set True to remove the weapon from world on drop, otherwise False to drop it like normal.
 * @noreturn
 */
native sh_drop_weapon(id, weaponID, bool:remove = false);

/**
 * Gives client a weapon.
 *
 * @note		This can be overridden by server using shweapon.cfg.
 *				If giving a primary weapon set sh_set_hero_shield() in hero to avoid invisible shield bug.
 *
 * @param id		The index of the client.
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @param switchTo	Set True to force client to switch to given weapon, otherwise False.
 * @noreturn
 */
native sh_give_weapon(id, weaponID, bool:switchTo = false);

/**
 * Gives client an item. (Use sh_give_weapon for better weapon_ handling)
 *
 * @note		Weapons can be overridden by server using shweapon.cfg.
 *				If giving a primary weapon set sh_set_hero_shield() in hero to avoid invisible shield bug.
 *
 * @param id		The index of the client.
 * @param itemName	The "item_*", "ammo_*", or "weapon_*" name of the desired item.
 * @param switchTo	Set True to force client to switch to given item if it's a weapon, otherwise False.
 * @noreturn
 */
native sh_give_item(id, const itemName[], bool:switchTo = false);

/**
 * Sets ammo reload method.
 *
 * @note		You are responsible for when this is called, usually when clip is empty.
 *
 * @param id		The index of the client.
 * @param mode		The mode	0 - follow server sh_reloadmode CVAR
 *					1 - continuous shooting, no reload
 *					2 - fill the backpack (must reload)
 *					3 - drop the gun and get a new one with full clip
 * @noreturn
 */
native sh_reload_ammo(id, mode = 0);


/**************************
 *         STOCKS         *
 **************************/

/**
 * Forces client to switch to specified weapon if they have the weapon.
 *
 * @param id		The index of the client.
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @noreturn
 */
stock sh_switch_weapon(id, weaponID)
{
	if (weaponID < CSW_P228 || weaponID > CSW_P90)
		return;

	if (user_has_weapon(id, weaponID)) {
		static weaponName[32];
		get_weaponname(weaponID, weaponName, charsmax(weaponName));
		engclient_cmd(id, weaponName);
	}
}

//------------
// Weapon Look Up Tables, faster than switch statements.
//------------

/**
 * Returns max backpack ammo of weapon.
 *
 * @note		Stock created in superheroconst.inc, explained here for usage reference.
 *
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @return		The weapon's max backpack ammo.
 */
//sh_get_max_bpammo(weaponID)

/**
 * Returns max clip ammo of weapon.
 *
 * @note		Stock created in superheroconst.inc, explained here for usage reference.
 *
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @return		The weapon's max clip ammo.
 */
//sh_get_max_clipammo(weaponID)

/**
 * Returns weapon slot of weapon.
 * Useful to run code only on guns not on grenades, etc.
 *
 * @note		Stock created in superheroconst.inc, explained here for usage reference.
 *
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @return		The weapon slot.
 */
//sh_get_weapon_slot(weaponID)
