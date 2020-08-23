
#if defined _sh_core_hpap_included
  #endinput
#endif
#define _sh_core_hpap_included

#pragma reqlib sh_core_hpap
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_hpap
#endif

#include <amxmodx>
#include <fun>
#include <cstrike>

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
 * @noreturn
 */
native sh_set_hero_hpap(heroID, pcvarHealth = 0, pcvarArmor = 0);

//------------

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


/**************************
 *         STOCKS         *
 **************************/

/**
 * Add to client's current health, up to a max limit.
 *
 * @param id		The index of the client.
 * @param hitPoints	The amount of health to add.
 * @param maxHealth	The maxium possible health to add up to, set 0 to use max from client's heroes.
 * @return		The amount of health added, 0 on failure.
 */
stock sh_add_hp(id, hitPoints, maxHealth = 0)
{
	if (hitPoints == 0)
		return 0;

	if (maxHealth == 0)
		maxHealth = sh_get_max_hp(id);

	new currentHealth = get_user_health(id);

	if (currentHealth < maxHealth) {
		new newHealth = min((currentHealth + hitPoints), maxHealth);
		set_user_health(id, newHealth);
		return newHealth - currentHealth;
	}

	return 0;
}

/**
 * Add to client's current armor, up to a max limit.
 *
 * @note	Armor power does not set til approx 0.6 seconds after spawn,
 *			do not regen armor during that time to allow sh to properly set AP.
 *
 * @param id		The index of the client.
 * @param armorPoints	The amount of armor to add.
 * @param maxArmor	The maxium possible armor to add up to, set 0 to use max from client's heroes.
 * @return		The amount of health added, 0 on failure.
 */
stock sh_add_ap(id, armorPoints, maxArmor = 0)
{
	if (armorPoints == 0)
		return 0;

	if (maxArmor == 0)
		maxArmor = sh_get_max_ap(id);

	new CsArmorType:armorType;
	new currentArmor = cs_get_user_armor(id, armorType);

	if (currentArmor < maxArmor) {
		if (!currentArmor)
			armorType = CS_ARMOR_VESTHELM;

		new newArmor = min((currentArmor + armorPoints), maxArmor);
		cs_set_user_armor(id, newArmor, armorType);
		return newArmor - currentArmor;
	}

	return 0;
}
