#if defined _cs_teams_api_included
	#endinput
#endif
#define _cs_teams_api_included

#include <cstrike_const>

#pragma reqlib cs_teams_api
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib cs_teams_api
#endif


/**
 * Sets a player's team.
 *
 * @param id			Player index.
 * @param team			CS_TEAM_ constant.
 * @param update		Whether to update team on scoreboard.
 * @noreturn
 */
native cs_set_player_team(id, any:team, bool:update = true);
