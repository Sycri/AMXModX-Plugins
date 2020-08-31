
#if defined _sh_core_objectives_included
  #endinput
#endif
#define _sh_core_objectives_included

#include <sh_core_objectives_const>

#pragma reqlib sh_core_objectives
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_objectives
#endif


/**************************
 *        NATIVES         *
 **************************/

 /**
 * Returns the index of the latest C4 which spawned at new round.
 *
 * @return		The index of the C4 weapon, else -1 if this C4 has already been planted.
 */
native sh_get_c4_id();

 /**
 * Returns the index of the latest client which spawned as a VIP at new round.
 *
 * @return		The index of the client, else 0 if no VIP has been spawned since map change.
 */
native sh_get_vip_id();

/**
 * Returns server flags for sh_blockvip cvar, can be used in heroes for custom VIP blocks.
 * (see sh_core_objectives_const.inc for flag types)
 *
 * @note	You are still responsible to check if user is vip, use id == sh_get_vip_id().
 * 			example usage: if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_CUSTOM) {//do something}
 *
 * @return	The flags currently set.
 */
native sh_vip_flags();
