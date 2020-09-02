
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
 * @return		True, otherwise false if invalid hero.
 */
native sh_set_hero_hpap(heroID, pcvarHealth = 0, pcvarArmor = 0);

//------------

/**
 * Adds to client's current health, up to a max limit.
 *
 * @param id		The index of the client.
 * @param hitPoints	The amount of health to add.
 * @param maxHealth	The maxium possible health to add up to, set 0 to use max from client's heroes.
 * @return		The amount of health added, 0 on failure.
 */
native sh_add_hp(id, hitPoints, maxHealth = 0);

/**
 * Adds to client's current armor, up to a max limit.
 *
 * @param id		The index of the client.
 * @param armorPoints	The amount of armor to add.
 * @param maxArmor	The maxium possible armor to add up to, set 0 to use max from client's heroes.
 * @return		The amount of health added, 0 on failure.
 */
native sh_add_ap(id, armorPoints, maxArmor = 0);

/**
 * Blocks the client from being able to gain health from sh_add_hp().
 *
 * @param id		The index of the client.
 * @param block		Whether to set or remove the block.
 * @return		True, otherwise false if invalid client.
 */
native sh_block_add_hp(id, bool:block = true);

/**
 * Blocks the client from being able to gain health from sh_add_ap().
 *
 * @param id		The index of the client.
 * @param block		Whether to set or remove the block.
 * @return		True, otherwise false if invalid client.
 */
native sh_block_add_ap(id, bool:block = true);

/**
 * Blocks the client's health powers and sets max health.
 *
 * @param id		The index of the client.
 * @param block		Whether to set or remove the block.
 * @param maxHealth	Max health to set if a value above zero is provided.
 * @return		True, otherwise false if invalid client.
 */
native sh_block_hero_hp(id, bool:block = true, maxHealth = 0);

/**
 * Blocks the client's armor powers and sets max armor.
 *
 * @param id		The index of the client.
 * @param block		Whether to set or remove the block.
 * @param maxArmor	Max armor to set if a value above zero is provided.
 * @return		True, otherwise false if invalid client.
 */
native sh_block_hero_ap(id, bool:block = true, maxArmor = 0);

/**
 * Gets the client's max health based on the heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero HP of the client, otherwise 0 if invalid client.
 */
native sh_get_max_hp(id);

/**
 * Gets the client's max armor based on the heroes client has.
 *
 * @param id		The index of the client.
 * @return		The max hero AP of the client, otherwise 0 if invalid client.
 */
native sh_get_max_ap(id);
