
#if defined _sh_core_speed_included
  #endinput
#endif
#define _sh_core_speed_included

#pragma reqlib sh_core_speed
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_speed
#endif

#include <cstrike_const>
#include <sh_core_speed_const>

/**************************
 *        NATIVES         *
 **************************/

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Sets hero's max speed dependent on currently held weapon. (Optional)
 * Speeds do not stack, values from heroes are compared and greatest is applied.
 * weapons is a bit-field of weapons this speed is good for, check CSW_ constants for weapon values.
 * (1 << 29) | (1 << 30) would equal the CSW_ weapon constants corresponding to (1 << CSW_KNIFE) | (1 << CSW_P90), etc... (see cstrike_const.inc)
 *
 * @note		This setting does not effect speed of sniper rifles when scoped.
 *				Max possible running speed is 2000, limited by half-life.
 *				Clients are also limited by cl_***speed client cvars defaulted to 400.
 *				Scout is the fastest default weapon at 260 and the other 3 snipers slowest at 150 when scoped.
 *
 * @param heroID	The index of the hero.
 * @param pcvarSpeed	The pcvar value for maximum Speed CVAR for the hero.
 * @param weapons	Bit-field of weapon CSW_ constant values to set speed for, CSW_ALL_WEAPONS is for all weapons.
 * @noreturn
 */
native sh_set_hero_speed(heroID, pcvarSpeed, weapons = CSW_ALL_WEAPONS);

//------------

/**
 * Speed stuns client for time specified. Bind powers are not usable when stunned.
 *
 * @note		Does not combine time, the highest time will override.
 *
 * @param id		The index of the client.
 * @param howLong	The length of time in seconds the stun lasts.
 * @param speed		The speed of the client when stunned.
 * @noreturn
 */
native sh_set_stun(id, Float:howLong, Float:speed = 1.0);

/**
 * Returns a client's speed stun status.
 *
 * @param id		The index of the client.
 * @return		True if client is stunned, otherwise false.
 */
native bool:sh_get_stun(id);

/**
 * Reset client's max speed according to heroes they have.
 * Useful incase a temporary value was set.
 *
 * @param id		    The index of the client.
 * @noreturn
 */
native sh_reset_max_speed(id);


/**************************
 *         STOCKS         *
 **************************/

//------------
// Weapon Look Up Tables, faster than switch statements.
//------------

/**
 * Gets the default speed of a weapon.
 *
 * @param weaponID	The CSW_ index of the weapon. (see cstrike_const.inc)
 * @param zoomed	Set True if weapon speed while zoomed is wanted, otherwise False.
 * @return		The speed of the weapon.
 */
stock Float:sh_get_weapon_speed(weaponID, bool:zoomed = false)
{
	if (zoomed) {
		// Only the 4 sniper rifles actually have different speeds when zoomed
		// And 3 of those have the same speed so lets just use a switch for them.
		switch (weaponID) {
			case CSW_SCOUT: return 220.0;
			case CSW_SG550, CSW_AWP, CSW_G3SG1: return 150.0;
		}
	}

	return gWeaponSpeed[weaponID];
}
