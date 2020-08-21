
#if defined _sh_core_shieldrestrict_included
  #endinput
#endif
#define _sh_core_shieldrestrict_included

#pragma reqlib sh_core_shieldrestrict
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_shieldrestrict
#endif

/**************************
 *        NATIVES         *
 **************************/

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Sets hero's shield restriction status. (Optional)
 *
 * @note		Set this on heroes that give weapons to avoid invisible shield bug.
 *
 * @param heroID	The index of the hero.
 * @param restricted	Set true to restict hero from allowing shield use, otherwise false.
 * @noreturn
 */
native sh_set_hero_shield(heroID, bool:restricted = false);
