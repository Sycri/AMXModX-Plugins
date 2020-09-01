#if defined _zp50_gamemodes_included
  #endinput
#endif
#define _zp50_gamemodes_included

#include <zp50_core>
#include <zp50_gamemodes_const>

#pragma reqlib zp50_gamemodes
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib zp50_gamemodes
#endif


/**
 * Registers a new game mode.
 *
 * @param name		Game mode name.
 * @return			An internal game mode ID, or ZP_INVALID_GAME_MODE on failure.
 */
native zp_gamemodes_register(const name[]);

/**
 * Sets a default game mode (to start if no other game mode can been started).
 *
 * @param gamemodeID		A valid game mode ID.
 * @return					True on success, false otherwise.
 */
native zp_gamemodes_set_default(gamemodeID);

/**
 * Returns default game mode.
 *
 * @return					A valid game mode ID.
 */
native zp_gamemodes_get_default();

/**
 * Returns game mode that was chosen for the current round.
 *
 * @return			An internal game mode ID, or ZP_NO_GAME_MODE.
 */
native zp_gamemodes_get_chosen();

/**
 * Returns game mode that is currently in progress.
 *
 * @return			An internal game mode ID, or ZP_NO_GAME_MODE.
 */
native zp_gamemodes_get_current();

/**
 * Returns a game mode's ID.
 *
 * @param name		Game mode name to look for.
 * @return			Internal game mode ID, or ZP_INVALID_GAME_MODE if not found.
 */
native zp_gamemodes_get_id(const name[]);

/**
 * Returns a game mode's name.
 *
 * @param gamemodeID	A valid game mode ID.
 * @param name			The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native zp_gamemodes_get_name(gamemodeID, name[], len);

/**
 * Forces a game mode to start.
 *
 * @param gamemodeID		A valid game mode ID.
 * @param targetPlayer		Player ID to be passed to game mode (optional).
 * @return					True on success, false if game mode can't start.
 */
native zp_gamemodes_start(gamemodeID, targetPlayer = RANDOM_TARGET_PLAYER);

/**
 * Returns number of registered game modes.
 *
 * @return			Game mode count.
 */
native zp_gamemodes_get_count();

/**
 * Sets whether zombies can infect humans for the current game mode.
 *
 * @param allow			True to allow, false otherwise.
 */
native zp_gamemodes_set_allow_infect(allow = true);

/**
 * Returns whether zombies are allowed to infect humans for the current game mode.
 *
 * @return			True if allowed, false otherwise.
 */
native zp_gamemodes_get_allow_infect();

/**
 * Called when ZP tries to choose a game mode for the current
 * round. Returning PLUGIN_HANDLED here will tell the game modes
 * manager that your mode can't be chosen (useful to set custom
 * conditions, like a min amount of players, etc.)
 *
 * @param gamemodeID		Internal game mode ID.
 * @param skipChecks		True when mode is being started by an admin.
 */
forward zp_fw_gamemodes_choose_pre(gamemodeID, skipChecks);

/**
 * Called when a game mode is chosen for the current round.
 *
 * @param gamemodeID		Internal ID for the game mode that was chosen.
 * @param targetPlayer		Player ID passed to game mode (can be RANDOM_TARGET_PLAYER).
 */
forward zp_fw_gamemodes_choose_post(gamemodeID, targetPlayer);

/**
 * Called when a game mode starts.
 *
 * @param gamemodeID		Internal ID for the game mode that was started.
 */
forward zp_fw_gamemodes_start(gamemodeID);

/**
 * Called when a game mode ends.
 *
 * Note: this can pass ZP_NO_GAME_MODE (if no game mode was in progress).
 *
 * @param gamemodeID		Internal ID for the game mode that ended.
 */
forward zp_fw_gamemodes_end(gamemodeID);
