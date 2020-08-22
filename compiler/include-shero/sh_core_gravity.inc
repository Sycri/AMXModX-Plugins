
#if defined _sh_core_gravity_included
  #endinput
#endif
#define _sh_core_gravity_included

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
 * weapons[] is an array of weapons this gravity is good for, check CSW_ constants for weapon values.
 * {29, 30} would equal the CSW_ weapon constants corresponding to {CSW_KNIFE, CSW_P90}, etc... (see cstrike_const.inc)
 *
 * @note		A Gravity value 0.0 or below is ignored, 1.0 is normal gravity (800).
 *				***Weapon based gravity is not implemented yet. Maybe in next version, undecided.***
 *
 * @param heroID	The index of the hero.
 * @param pcvarGravity	The pcvar value for minimum Gravity CVAR for the hero.
 * @param weapons	Array of weapon CSW_ constant values to set gravity for, 0 is for all weapons.
 * @param numofwpns	The size of the weapons array, this MUST be passed in CORRECTLY!
 * @noreturn
 */
native sh_set_hero_grav(heroID, pcvarGravity, const weapons[] = {0}, numofwpns = 1);

/**
 * Reset client's min gravity according to heroes they have.
 * Useful incase a temporary value was set.
 *
 * @param id		The index of the client.
 * @noreturn
 */
native sh_reset_min_gravity(id);
