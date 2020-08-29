
#if defined _sh_core_extradamage_included
  #endinput
#endif
#define _sh_core_extradamage_included

#pragma reqlib sh_core_extradamage
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_extradamage
#endif

#include <sh_core_extradamage_const>

/**************************
 *        FORWARDS        *
 **************************/

 /**
 * Called whenever a client receives damage from another client.
 *
 * @note		Use this instead of client_damage() to avoid problems with recursion when using sh_extra_damage().
 * 				Extra damage from sh_extra_damage() will not be catched with this unlike client_damage().
 *
 * @param victim		The index of the victim.
 * @param attacker		The index of the attacker.
 * @param damage		The amount of damage received after CS armor/friendlyfire calculations.
 * @param damagebits	The type of damage done. (see hlsdk_const.inc for DMG_ constants)
 * @noreturn
 */
forward sh_client_damage(victim, attacker, damage, damagebits);


/**************************
 *        NATIVES         *
 **************************/

 /**
 * Cause non-default extra damage.
 * Use this for non-default damage to correctly send damage messages and handle XP.
 *
 * @note		Set dmgFFmsg to false for looping extra damage, to avoid team attack chat spam.
 * 				The default dmgOrigin of {0,0,0} will use attacker as the damage direction.
 * 				Victim is unaffected if victim has godmode (this includes insta kill dmgMode).
 *
 * @param victim		The index of the victim.
 * @param attacker		The index of the attacker.
 * @param damage		Value of damage to cause, see dmgMode for effect on victim.
 * @param wpnDescription	Name of the weapon that causes the damage.
 * @param headshot		Set 1 if damage is a headshot else 0.
 * @param dmgMode		Type of damage, how victim is effected by damage value. See sh_core_main_const.inc for types and explanations.
 * @param dmgStun		Set True to do damage stun on victim, otherwise False.
 * @param dmgFFmsg		Set True to show friendly fire chat message "John Doe attacked a teammate", otherwise False.
 * @param dmgOrigin		Origin of damage bits direction (red flash indicators).
 * @noreturn
 */
native sh_extra_damage(victim, attacker, damage, const wpnDescription[], headshot = 0, dmgMode = SH_DMG_MULT, bool:dmgStun = false, bool:dmgFFmsg = true, const Float:dmgOrigin[3] = {0.0,0.0,0.0});
