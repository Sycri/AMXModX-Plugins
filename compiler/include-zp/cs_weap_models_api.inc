#if defined _cs_weap_models_api_included
	#endinput
#endif
#define _cs_weap_models_api_included

#pragma reqlib cs_weap_models_api
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib cs_weap_models_api
#endif


/**
 * Sets a custom view model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param id					Player index.
 * @param weaponID				Weapon to replace model for. (in CSW_ format)
 * @param viewModel				Full path to model. (e.g. "models/v_knife_custom.mdl")
 */
native cs_set_player_view_model(id, weaponID, const viewModel[]);

/**
 * Restores a custom view model for a specific weapon for a player.
 *
 * @param id					Player index.
 * @param weaponID				Weapon to restore model for. (in CSW_ format)
 */
native cs_reset_player_view_model(id, weaponID);

/**
 * Sets a custom weapon model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param id					Player index.
 * @param weaponID				Weapon to replace model for. (in CSW_ format)
 * @param viewModel				Full path to model. (e.g. "models/p_knife_custom.mdl")
 */
native cs_set_player_weap_model(id, weaponID, const weaponModel[]);

/**
 * Restores a custom weapon model for a specific weapon for a player.
 *
 * @param id					Player index.
 * @param weaponID				Weapon to restore model for. (in CSW_ format)
 */
native cs_reset_player_weap_model(id, weaponID);
