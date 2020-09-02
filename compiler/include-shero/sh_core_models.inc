
#if defined _sh_core_models_included
  #endinput
#endif
#define _sh_core_models_included

#include <cstrike_const>

#pragma reqlib sh_core_models
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib sh_core_models
#endif


/**************************
 *        NATIVES         *
 **************************/

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Sets hero's player model for the specified team.
 * Last selected hero by the client gets priority.
 *
 * @note		Max model name length is 32.
 *
 * @param heroID	The index of the hero.
 * @param model		Model name.
 * @param team		Either CS_TEAM_T (Terrorists) or CS_TEAM_CT (Counter-Terrorists). (see cstrike_const.inc)
 * @return		True, otherwise false if invalid hero or team.
 */
native sh_set_hero_playermodel(heroID, const model[], const any:team);

/**
 * Sets hero's view model for the specified cs/cz weapon.
 * Last selected hero by the client gets priority.
 *
 * @note		Max model path length is 128.
 *
 * @param heroID	The index of the hero.
 * @param viewModel	Model path.
 * @param weaponID	The CSW_ constant of the weapon to set model for. (see cstrike_const.inc)
 * @return		True, otherwise false if invalid hero.
 */
native sh_set_hero_viewmodel(heroID, const viewModel[], const weaponID);

/**
 * Sets hero's weapon model for the specified cs/cz weapon.
 * Last selected hero by the client gets priority.
 *
 * @note		Max model path length is 128.
 *
 * @param heroID	The index of the hero.
 * @param weaponModel	Model path.
 * @param weaponID	The CSW_ constant of the weapon to set model for. (see cstrike_const.inc)
 * @return		True, otherwise false if invalid hero.
 */
native sh_set_hero_weaponmodel(heroID, const weaponModel[], const weaponID);
