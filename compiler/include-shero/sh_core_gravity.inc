
#if defined _sh_core_gravity_included
  #endinput
#endif
#define _sh_core_gravity_included

#include <cstrike_const>

#pragma reqlib sh_core_gravity
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_gravity
#endif


/**************************
 *        NATIVES         *
 **************************/

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Sets hero's min gravity dependent on currently held weapon. (Optional)
 * Gravities do not stack, values from heroes are compared and lowest is applied.
 * weapons is a bit-field of weapons this gravity is good for, check CSW_ constants for weapon values.
 * (1 << 29) | (1 << 30) would equal the CSW_ weapon constants corresponding to (1 << CSW_KNIFE) | (1 << CSW_P90), etc... (see cstrike_const.inc)
 *
 * @note		A Gravity value 0.0 or below is ignored, 1.0 is normal gravity (800).
 *
 * @param heroID	The index of the hero.
 * @param pcvarGravity	The pcvar value for minimum Gravity CVAR for the hero.
 * @param weapons	Bit-field of weapon CSW_ constant values to set gravity for, CSW_ALL_WEAPONS is for all weapons.
 * @return		True, otherwise false if invalid hero.
 */
native sh_set_hero_grav(heroID, pcvarGravity, const weapons = CSW_ALL_WEAPONS);

//------------

/**
 * Blocks the client's gravity powers.
 *
 * @param id		The index of the client.
 * @param block		Whether to set or remove the block.
 * @return		True, otherwise false if invalid client.
 */
native sh_block_hero_grav(id, bool:block = true);

/**
 * Resets client's min gravity according to heroes they have.
 * Useful incase a temporary value was set.
 *
 * @param id		The index of the client.
 * @return		True, otherwise false if invalid client or SH not active.
 */
native sh_reset_min_gravity(id);
