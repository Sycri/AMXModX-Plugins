#if defined _zp50_item_madness_included
  #endinput
#endif
#define _zp50_item_madness_included

#include <zp50_core>

#pragma reqlib zp50_item_zombie_madness
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib zp50_item_zombie_madness
#endif


/**
 * Returns whether a player is in zombie madness.
 *
 * @param id		Player index.
 */
native zp_item_zombie_madness_get(id)
