/* AMX Mod X script.
*
*	[SH] Core: Models (sh_core_models.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <sh_core_main>

#pragma semicolon 1

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" };

new gSuperHeroCount;

new gPlayerModelCount;
new Array:gPlayerModelHeroID;
new Array:gPlayerModelTeam;
new Array:gPlayerModel;
new bool:gPlayerModelSet[MAX_PLAYERS + 1];

new gViewModelCount;
new Array:gViewModelHeroID;
new Array:gViewModelWeapon;
new Array:gViewModel;

new gWeaponModelCount;
new Array:gWeaponModelHeroID;
new Array:gWeaponModelWeapon;
new Array:gWeaponModel;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Weapons", SH_VERSION_STR, SH_AUTHOR_STR);

	for (new i = 1; i < sizeof WEAPONENTNAMES; i++) {
		if (WEAPONENTNAMES[i][0])
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "@Forward_Item_Deploy_Post", 1);
	}
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_models");
	
	register_native("sh_set_hero_playermodel", "@Native_SetHeroPlayerModel");
	register_native("sh_set_hero_viewmodel", "@Native_SetHeroViewModel");
	register_native("sh_set_hero_weaponmodel", "@Native_SetHeroWeaponModel");

	gPlayerModelHeroID = ArrayCreate(1, 1);
	gPlayerModelTeam = ArrayCreate(1, 1);
	gPlayerModel = ArrayCreate(32, 1);

	gViewModelHeroID = ArrayCreate(1, 1);
	gViewModelWeapon = ArrayCreate(1, 1);
	gViewModel = ArrayCreate(128, 1);

	gWeaponModelHeroID = ArrayCreate(1, 1);
	gWeaponModelWeapon = ArrayCreate(1, 1);
	gWeaponModel = ArrayCreate(128, 1);
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
}
//----------------------------------------------------------------------------------------------
public plugin_end()
{
	ArrayDestroy(gPlayerModelHeroID);
	ArrayDestroy(gPlayerModelTeam);
	ArrayDestroy(gPlayerModel);

	ArrayDestroy(gViewModelHeroID);
	ArrayDestroy(gViewModelWeapon);
	ArrayDestroy(gViewModel);

	ArrayDestroy(gWeaponModelHeroID);
	ArrayDestroy(gWeaponModelWeapon);
	ArrayDestroy(gWeaponModel);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_playermodel(heroID, const model[], const any:team)
@Native_SetHeroPlayerModel(plugin_id, num_params)
{
	new heroID = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroID < 0 || heroID >= sh_get_num_heroes()) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Hero ID (%d)", heroID);
		return false;
	}

	new CsTeams:team = CsTeams:get_param(3);

	if (team < CS_TEAM_T || team > CS_TEAM_CT) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Team (%d)", team);
		return false;
	}

	new playerModel[32];
	get_array(2, playerModel, charsmax(playerModel));

	sh_debug_message(0, 3, "Set Player Model -> HeroID: %d - Player Model: %s - Team: %d", heroID, playerModel, _:team);

	ArrayPushCell(gPlayerModelHeroID, heroID);
	ArrayPushCell(gPlayerModelTeam, team);
	ArrayPushString(gPlayerModel, playerModel);
	++gPlayerModelCount;
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_viewmodel(heroID, const viewModel[], const weaponID)
@Native_SetHeroViewModel(plugin_id, num_params)
{
	new heroID = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroID < 0 || heroID >= sh_get_num_heroes()) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Hero ID (%d)", heroID);
		return false;
	}

	new weaponID = get_param(3);

	new viewModel[128];
	get_array(2, viewModel, charsmax(viewModel));

	sh_debug_message(0, 3, "Set View Model -> HeroID: %d - View Model: %s - Weapon: %d", heroID, viewModel, weaponID);

	ArrayPushCell(gViewModelHeroID, heroID);
	ArrayPushCell(gViewModelWeapon, weaponID);
	ArrayPushString(gViewModel, viewModel);
	++gViewModelCount;
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_weaponmodel(heroID, const weaponModel[], const weaponID)
@Native_SetHeroWeaponModel(plugin_id, num_params)
{
	new heroID = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroID < 0 || heroID >= sh_get_num_heroes()) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Hero ID (%d)", heroID);
		return false;
	}

	new weaponID = get_param(3);

	new weaponModel[128];
	get_array(2, weaponModel, charsmax(weaponModel));

	sh_debug_message(0, 3, "Set Weapon Model -> HeroID: %d - Weapon Model: %s - Weapon %d", heroID, weaponModel, weaponID);

	ArrayPushCell(gWeaponModelHeroID, heroID);
	ArrayPushCell(gWeaponModelWeapon, weaponID);
	ArrayPushString(gWeaponModel, weaponModel);
	++gWeaponModelCount;
	return true;
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (!is_user_alive(id))
		return;

	if (ArrayFindValue(gPlayerModelHeroID, heroID) != -1)
		setPlayerModel(id, true);

	static vModelID, wModelID, wpnID;
	vModelID = ArrayFindValue(gViewModelHeroID, heroID);
	wModelID = ArrayFindValue(gWeaponModelHeroID, heroID);
	wpnID = cs_get_user_weapon(id);

	if ((vModelID != -1 && ArrayGetCell(gViewModelWeapon, vModelID) == wpnID) || (wModelID != -1 && ArrayGetCell(gWeaponModelWeapon, wModelID) == wpnID))
		resetModel(id, wpnID);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (gPlayerModelSet[id])
		return;
	
	setPlayerModel(id, false);
}
//----------------------------------------------------------------------------------------------
public sh_round_new()
{
	static CsTeams:playerTeam[MAX_PLAYERS + 1];

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		if (playerTeam[player] != (playerTeam[player] = cs_get_user_team(player)))
			gPlayerModelSet[player] = false;
	}
}
//----------------------------------------------------------------------------------------------
setPlayerModel(id, bool:resetIfNoHero)
{
	static playerModel[32];
	playerModel[0] = '^0';
	getPlayerModel(id, cs_get_user_team(id), playerModel, charsmax(playerModel));

	if (playerModel[0] != '^0') {
		cs_set_user_model(id, playerModel);
		gPlayerModelSet[id] = true;
	} else if (resetIfNoHero) {
		cs_reset_user_model(id);
		gPlayerModelSet[id] = false;
	}
}
//----------------------------------------------------------------------------------------------
@Forward_Item_Deploy_Post(weaponEnt)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	// Get weapon's owner
	new owner = get_ent_data_entity(weaponEnt, "CBasePlayerItem", "m_pPlayer");

	if (is_user_alive(owner))
		switchModel(owner, cs_get_weapon_id(weaponEnt));
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
switchModel(id, weaponID)
{
	if (cs_get_user_shield(id) && (CSW_ALL_PISTOLS & (1 << weaponID)))
		return;

	static viewModel[128], weaponModel[128];
	viewModel[0] = '^0';
	weaponModel[0] = '^0';
	getViewModel(id, weaponID, viewModel, charsmax(viewModel));
	getWeaponModel(id, weaponID, weaponModel, charsmax(weaponModel));

	if (viewModel[0] != '^0')
		set_pev(id, pev_viewmodel2, viewModel);

	if (weaponModel[0] != '^0')
		set_pev(id, pev_weaponmodel2, weaponModel);
}
//----------------------------------------------------------------------------------------------
resetModel(id, weaponID)
{
	if (cs_get_user_shield(id) && (CSW_ALL_PISTOLS & (1 << weaponID)))
		return;
	
	new weaponEnt = cs_get_user_weapon_entity(id);
	
	// Let CS update weapon models
	ExecuteHamB(Ham_Item_Deploy, weaponEnt);
}
//----------------------------------------------------------------------------------------------
getPlayerModel(id, CsTeams:team, playerModel[], len)
{
	if (team == CS_TEAM_UNASSIGNED || team == CS_TEAM_SPECTATOR)
		return;

	static i, playerPowerCount, heroID, modelID, lastUsableID;
	lastUsableID = -1;
	playerPowerCount = sh_get_user_powers(id);

	//Supports both CTs and TERRORISTs from the same hero while at the same time
	//allowing users to select their favourite hero's model by adding it the last
	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);

		if (-1 < heroID < gSuperHeroCount) {
			modelID = ArrayFindValue(gPlayerModelHeroID, heroID);

			if (modelID == -1)
				continue;
			
			if (ArrayGetCell(gPlayerModelTeam, modelID) == team)
				lastUsableID = modelID;
			else if (++modelID != gPlayerModelCount && ArrayGetCell(gPlayerModelHeroID, modelID) == heroID)
				lastUsableID = modelID;
		}
	}

	if (lastUsableID == -1)
		return;

	ArrayGetString(gPlayerModel, lastUsableID, playerModel, len);
}
//----------------------------------------------------------------------------------------------
getViewModel(id, weaponID, viewModel[], len)
{
	static i, playerPowerCount, heroID, modelID, lastUsableID;
	lastUsableID = -1;
	playerPowerCount = sh_get_user_powers(id);

	//Supports multiple weapons from the same hero while at the same time allowing
	//users to select their favourite hero's model by adding it the last
	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);

		if (-1 < heroID < gSuperHeroCount) {
			modelID = ArrayFindValue(gViewModelHeroID, heroID);

			if (modelID == -1)
				continue;
			
			do {
				if (ArrayGetCell(gViewModelWeapon, modelID) == weaponID)
					lastUsableID = modelID;

				if (++modelID == gViewModelCount)
					break;
			} while (ArrayGetCell(gViewModelHeroID, modelID) == heroID);
		}
	}

	if (lastUsableID == -1)
		return;

	ArrayGetString(gViewModel, lastUsableID, viewModel, len);
}
//----------------------------------------------------------------------------------------------
getWeaponModel(id, weaponID, weaponModel[], len)
{
	static i, playerPowerCount, heroID, modelID, lastUsableID;
	lastUsableID = -1;
	playerPowerCount = sh_get_user_powers(id);

	//Supports multiple weapons from the same hero while at the same time allowing
	//users to select their favourite hero's model by adding it the last
	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);

		if (-1 < heroID < gSuperHeroCount) {
			modelID = ArrayFindValue(gWeaponModelHeroID, heroID);

			if (modelID == -1)
				continue;
			
			do {
				if (ArrayGetCell(gWeaponModelWeapon, modelID) == weaponID)
					lastUsableID = modelID;

				if (++modelID == gWeaponModelCount)
					break;
			} while (ArrayGetCell(gWeaponModelHeroID, modelID) == heroID);
		}
	}

	if (lastUsableID == -1)
		return;

	ArrayGetString(gWeaponModel, lastUsableID, weaponModel, len);
}
//----------------------------------------------------------------------------------------------
