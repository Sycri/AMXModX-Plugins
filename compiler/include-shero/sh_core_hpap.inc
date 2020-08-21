
#if defined _sh_core_hpap_included
  #endinput
#endif
#define _sh_core_hpap_included

#pragma reqlib sh_core_hpap
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_hpap
#endif

/**************************
 *        NATIVES         *
 **************************/

/**
 * Gets the client's max health based on the heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero HP of the client, else 0 if invalid client.
 */
native sh_get_max_hp(id);

/**
 * Gets the client's max armor based on the heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero AP of the client, else 0 if invalid client.
 */
native sh_get_max_ap(id);

/**
 * Updates the client's max health internally based on the heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero HP of the client, else 0 if invalid client.
 */
native sh_update_max_hp(id);

/**
 * Updates the client's max health internally based on the heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero AP of the client, else 0 if invalid client.
 */
native sh_update_max_ap(id);

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Sets hero's max Health and Armor. (Optional)
 * Health and Armor do not stack, values from heroes are compared and greatest is applied.
 *
 * @note		If you only want to set one of the values, set the other to 0 or underscore "_" to use the default set value of 0.
 *
 * @param heroID	The index of the hero.
 * @param pcvarHealth	The pcvar value for maximum Health CVAR for the hero, CVAR values below 100 are ignored.
 * @param pcvarArmor	The pcvar value for maximum Armor CVAR for the hero.
 * @noreturn
 */
native sh_set_hero_hpap(heroID, pcvarHealth = 0, pcvarArmor = 0);
