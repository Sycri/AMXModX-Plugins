
#if defined _sh_core_godmode_included
  #endinput
#endif
#define _sh_core_godmode_included

#pragma reqlib sh_core_godmode
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_godmode
#endif

/**************************
 *        NATIVES         *
 **************************/

 /**
 * Sets godmode on client for time specified.
 *
 * @note		Does not combine time, the highest time will override.
 *				Client will sh glow blue {0,0,128} to indicate godmode. (This may be removed in a future version)
 *
 * @param id		The index of the client.
 * @param howLong	The length of time in seconds godmode lasts.
 * @noreturn
 */
native sh_set_godmode(id, Float:howLong);
