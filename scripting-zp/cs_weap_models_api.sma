/*================================================================================
	
	----------------------------------
	-*- [CS] Weapon Models API 1.2 -*-
	----------------------------------
	
	- Allows easily replacing player's view models and weapon models in CS and CZ
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

#define CSW_FIRST_WEAPON CSW_P228
#define POSITION_NULL -1

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" };

new gCustomViewModelsPosition[MAX_PLAYERS + 1][CSW_LAST_WEAPON + 1];
new Array:gCustomViewModelsNames;
new gCustomViewModelsCount;
new gCustomWeaponModelsPosition[MAX_PLAYERS + 1][CSW_LAST_WEAPON + 1];
new Array:gCustomWeaponModelsNames;
new gCustomWeaponModelsCount;

public plugin_init()
{
	register_plugin("[CS] Weapon Models API", "1.2", "WiLS");

	for (new i = 1; i < sizeof WEAPONENTNAMES; i++) {
		if (WEAPONENTNAMES[i][0])
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "@Forward_Item_Deploy_Post", 1);
	}

	// Initialize dynamic arrays
	gCustomViewModelsNames = ArrayCreate(128, 1);
	gCustomWeaponModelsNames = ArrayCreate(128, 1);

	// Initialize array positions
	new id, weaponID;
	for (id = 1; id <= MaxClients; ++id) {
		for (weaponID = CSW_FIRST_WEAPON; weaponID <= CSW_LAST_WEAPON; ++weaponID) {
			gCustomViewModelsPosition[id][weaponID] = POSITION_NULL;
			gCustomWeaponModelsPosition[id][weaponID] = POSITION_NULL;
		}
	}
}

public plugin_natives()
{
	register_library("cs_weap_models_api");
	register_native("cs_set_player_view_model", "@Native_SetPlayerViewModel");
	register_native("cs_reset_player_view_model", "@Native_ResetPlayerViewModel");
	register_native("cs_set_player_weap_model", "@Native_SetPlayerWeapModel");
	register_native("cs_reset_player_weap_model", "@Native_ResetPlayerWeapModel");
}

@Native_SetPlayerViewModel(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	new weaponID = get_param(2);

	if (weaponID < CSW_FIRST_WEAPON || weaponID > CSW_LAST_WEAPON) {
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponID);
		return false;
	}

	new viewModel[128];
	get_string(3, viewModel, charsmax(viewModel));

	// Check whether player already has a custom view model set
	if (gCustomViewModelsPosition[id][weaponID] == POSITION_NULL)
		AddCustomViewModel(id, weaponID, viewModel);
	else
		ReplaceCustomViewModel(id, weaponID, viewModel);
	
	// Get current weapon's id
	new currentWeaponEnt = cs_get_user_weapon_entity(id);
	new currentWeaponID = pev_valid(currentWeaponEnt) ? cs_get_weapon_id(currentWeaponEnt) : -1;

	// Model was set for the current weapon?
	if (weaponID == currentWeaponID)
		// Update weapon models manually
		@Forward_Item_Deploy_Post(currentWeaponEnt);
	return true;
}

@Native_ResetPlayerViewModel(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}

	new weaponID = get_param(2);

	if (weaponID < CSW_FIRST_WEAPON || weaponID > CSW_LAST_WEAPON) {
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponID);
		return false;
	}

	// Player doesn't have a custom view model, no need to reset
	if (gCustomViewModelsPosition[id][weaponID] == POSITION_NULL)
		return true;

	RemoveCustomViewModel(id, weaponID);

	// Get current weapon's id
	new currentWeaponEnt = cs_get_user_weapon_entity(id);
	new currentWeaponID = pev_valid(currentWeaponEnt) ? cs_get_weapon_id(currentWeaponEnt) : -1;
	
	// Model was reset for the current weapon?
	if (weaponID == currentWeaponID)
		// Let CS update weapon models
		ExecuteHamB(Ham_Item_Deploy, currentWeaponEnt);
	return true;
}

@Native_SetPlayerWeapModel(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	new weaponID = get_param(2);
	
	if (weaponID < CSW_FIRST_WEAPON || weaponID > CSW_LAST_WEAPON) {
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponID);
		return false;
	}
	
	new weaponModel[128];
	get_string(3, weaponModel, charsmax(weaponModel));
	
	// Check whether player already has a custom view model set
	if (gCustomWeaponModelsPosition[id][weaponID] == POSITION_NULL)
		AddCustomWeaponModel(id, weaponID, weaponModel);
	else
		ReplaceCustomWeaponModel(id, weaponID, weaponModel);
	
	// Get current weapon's id
	new currentWeaponEnt = cs_get_user_weapon_entity(id);
	new currentWeaponID = pev_valid(currentWeaponEnt) ? cs_get_weapon_id(currentWeaponEnt) : -1;
	
	// Model was reset for the current weapon?
	if (weaponID == currentWeaponID)
		// Update weapon models manually
		@Forward_Item_Deploy_Post(currentWeaponEnt);
	return true;
}

@Native_ResetPlayerWeapModel(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	new weaponID = get_param(2);
	
	if (weaponID < CSW_FIRST_WEAPON || weaponID > CSW_LAST_WEAPON) {
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon id (%d)", weaponID);
		return false;
	}
	
	// Player doesn't have a custom weapon model, no need to reset
	if (gCustomWeaponModelsPosition[id][weaponID] == POSITION_NULL)
		return true;
	
	RemoveCustomWeaponModel(id, weaponID);
	
	// Get current weapon's id
	new currentWeaponEnt = cs_get_user_weapon_entity(id);
	new currentWeaponID = pev_valid(currentWeaponEnt) ? cs_get_weapon_id(currentWeaponEnt) : -1;
	
	// Model was reset for the current weapon?
	if (weaponID == currentWeaponID)
		// Let CS update weapon models
		ExecuteHamB(Ham_Item_Deploy, currentWeaponEnt);
	return true;
}

AddCustomViewModel(index, weaponID, const viewModel[])
{
	gCustomViewModelsPosition[index][weaponID] = gCustomViewModelsCount;
	ArrayPushString(gCustomViewModelsNames, viewModel);
	++gCustomViewModelsCount;
}

ReplaceCustomViewModel(index, weaponIndex, const viewModel[])
{
	ArraySetString(gCustomViewModelsNames, gCustomViewModelsPosition[index][weaponIndex], viewModel);
}

RemoveCustomViewModel(index, weaponIndex)
{
	new posDelete = gCustomViewModelsPosition[index][weaponIndex];
	
	ArrayDeleteItem(gCustomViewModelsNames, posDelete);
	gCustomViewModelsPosition[index][weaponIndex] = POSITION_NULL;
	--gCustomViewModelsCount;
	
	// Fix view models array positions
	for (index = 1; index <= MaxClients; ++index) {
		for (weaponIndex = CSW_FIRST_WEAPON; weaponIndex <= CSW_LAST_WEAPON; ++weaponIndex) {
			if (gCustomViewModelsPosition[index][weaponIndex] > posDelete)
				--gCustomViewModelsPosition[index][weaponIndex];
		}
	}
}

AddCustomWeaponModel(index, weaponIndex, const weaponModel[])
{
	ArrayPushString(gCustomWeaponModelsNames, weaponModel);
	gCustomWeaponModelsPosition[index][weaponIndex] = gCustomWeaponModelsCount;
	++gCustomWeaponModelsCount;
}

ReplaceCustomWeaponModel(index, weaponIndex, const weaponModel[])
{
	ArraySetString(gCustomWeaponModelsNames, gCustomWeaponModelsPosition[index][weaponIndex], weaponModel);
}

RemoveCustomWeaponModel(index, weaponIndex)
{
	new posDelete = gCustomWeaponModelsPosition[index][weaponIndex];
	
	ArrayDeleteItem(gCustomWeaponModelsNames, posDelete);
	gCustomWeaponModelsPosition[index][weaponIndex] = POSITION_NULL;
	--gCustomWeaponModelsCount;
	
	// Fix weapon models array positions
	for (index = 1; index <= MaxClients; ++index) {
		for (weaponIndex = CSW_FIRST_WEAPON; weaponIndex <= CSW_LAST_WEAPON; ++weaponIndex) {
			if (gCustomWeaponModelsPosition[index][weaponIndex] > posDelete)
				--gCustomWeaponModelsPosition[index][weaponIndex];
		}
	}
}

public client_disconnected(id)
{
	// Remove custom models for player after disconnecting
	for (new weaponID = CSW_FIRST_WEAPON; weaponID <= CSW_LAST_WEAPON; ++weaponID) {
		if (gCustomViewModelsPosition[id][weaponID] != POSITION_NULL)
			RemoveCustomViewModel(id, weaponID);
		if (gCustomWeaponModelsPosition[id][weaponID] != POSITION_NULL)
			RemoveCustomWeaponModel(id, weaponID);
	}
}

@Forward_Item_Deploy_Post(weaponEnt)
{
	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weaponEnt);
	
	// Owner not valid
	if (!is_user_alive(owner))
		return HAM_IGNORED;
	
	// Get weapon's id
	new weaponID = cs_get_weapon_id(weaponEnt);
	
	// Custom view model?
	if (gCustomViewModelsPosition[owner][weaponID] != POSITION_NULL) {
		new viewModel[128];
		ArrayGetString(gCustomViewModelsNames, gCustomViewModelsPosition[owner][weaponID], viewModel, charsmax(viewModel));
		set_pev(owner, pev_viewmodel2, viewModel);
	}
	
	// Custom weapon model?
	if (gCustomWeaponModelsPosition[owner][weaponID] != POSITION_NULL) {
		new weaponModel[128];
		ArrayGetString(gCustomWeaponModelsNames, gCustomWeaponModelsPosition[owner][weaponID], weaponModel, charsmax(weaponModel));
		set_pev(owner, pev_weaponmodel2, weaponModel);
	}
	return HAM_IGNORED;
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
}
