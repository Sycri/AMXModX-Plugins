/*================================================================================
	
	-------------------------
	-*- [ZP] Admin Models -*-
	-------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

#pragma semicolon 1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

// Default models
new const modelsAdminHumanPlayer[][] = { "vip" };
new const modelsAdminHumanKnife[][] = { "models/v_knife.mdl" };
new const modelsAdminZombiePlayer[][] = { "zombie_source" };
new const modelsAdminZombieClaw[][] = { "models/zombie_plague/v_knife_zombie.mdl" };

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64
#define ACCESSFLAG_MAX_LENGTH 2

// Access flags
new gAccessAdminModels[ACCESSFLAG_MAX_LENGTH] = "d";

// Custom models
new Array:gModelsAdminHumanPlayer;
new Array:gModelsAdminHumanKnife;
new Array:gModelsAdminZombiePlayer;
new Array:gModelsAdminZombieClaw;

new CvarAdminModelsHumanPlayer, CvarAdminModelsHumanKnife;
new CvarAdminModelsZombiePlayer, CvarAdminModelsZombieKnife;

public plugin_init()
{
	register_plugin("[ZP] Admin Models", ZP_VERSION_STRING, "ZP Dev Team");
	
	bind_pcvar_num(create_cvar("zp_admin_models_human_player", "1"), CvarAdminModelsHumanPlayer);
	bind_pcvar_num(create_cvar("zp_admin_models_human_knife", "1"), CvarAdminModelsHumanKnife);
	bind_pcvar_num(create_cvar("zp_admin_models_zombie_player", "1"), CvarAdminModelsZombiePlayer);
	bind_pcvar_num(create_cvar("zp_admin_models_zombie_knife", "1"), CvarAdminModelsZombieKnife);
}

public plugin_precache()
{
	// Initialize arrays
	gModelsAdminHumanPlayer = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1);
	gModelsAdminHumanKnife = ArrayCreate(MODEL_MAX_LENGTH, 1);
	gModelsAdminZombiePlayer = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1);
	gModelsAdminZombieClaw = ArrayCreate(MODEL_MAX_LENGTH, 1);
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN HUMAN", gModelsAdminHumanPlayer);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN HUMAN", gModelsAdminHumanKnife);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN ZOMBIE", gModelsAdminZombiePlayer);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN ZOMBIE", gModelsAdminZombieClaw);
	
	// If we couldn't load from file, use and save default ones
	new i;
	if (ArraySize(gModelsAdminHumanPlayer) == 0) {
		for (i = 0; i < sizeof modelsAdminHumanPlayer; ++i)
			ArrayPushString(gModelsAdminHumanPlayer, modelsAdminHumanPlayer[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN HUMAN", gModelsAdminHumanPlayer);
	}
	if (ArraySize(gModelsAdminHumanKnife) == 0) {
		for (i = 0; i < sizeof modelsAdminHumanKnife; ++i)
			ArrayPushString(gModelsAdminHumanKnife, modelsAdminHumanKnife[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN HUMAN", gModelsAdminHumanKnife);
	}
	if (ArraySize(gModelsAdminZombiePlayer) == 0) {
		for (i = 0; i < sizeof modelsAdminZombiePlayer; ++i)
			ArrayPushString(gModelsAdminZombiePlayer, modelsAdminZombiePlayer[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "ADMIN ZOMBIE", gModelsAdminZombiePlayer);
	}
	if (ArraySize(gModelsAdminZombieClaw) == 0) {
		for (i = 0; i < sizeof modelsAdminZombieClaw; ++i)
			ArrayPushString(gModelsAdminZombieClaw, modelsAdminZombieClaw[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE ADMIN ZOMBIE", gModelsAdminZombieClaw);
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "ADMIN MODELS", gAccessAdminModels, charsmax(gAccessAdminModels)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "ADMIN MODELS", gAccessAdminModels);
	
	// Precache models
	new playerModel[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], modelPath[128];
	for (i = 0; i < ArraySize(gModelsAdminHumanPlayer); ++i) {
		ArrayGetString(gModelsAdminHumanPlayer, i, playerModel, charsmax(playerModel));
		formatex(modelPath, charsmax(modelPath), "models/player/%s/%s.mdl", playerModel, playerModel);
		precache_model(modelPath);
		// Support modelT.mdl files
		formatex(modelPath, charsmax(modelPath), "models/player/%s/%sT.mdl", playerModel, playerModel);
		if (file_exists(modelPath))
			precache_model(modelPath);
	}
	for (i = 0; i < ArraySize(gModelsAdminHumanKnife); ++i) {
		ArrayGetString(gModelsAdminHumanKnife, i, model, charsmax(model));
		precache_model(model);
	}
	for (i = 0; i < ArraySize(gModelsAdminZombiePlayer); ++i) {
		ArrayGetString(gModelsAdminZombiePlayer, i, playerModel, charsmax(playerModel));
		formatex(modelPath, charsmax(modelPath), "models/player/%s/%s.mdl", playerModel, playerModel);
		precache_model(modelPath);
		// Support modelT.mdl files
		formatex(modelPath, charsmax(modelPath), "models/player/%s/%sT.mdl", playerModel, playerModel);
		if (file_exists(modelPath))
			precache_model(modelPath);
	}
	for (i = 0; i < ArraySize(gModelsAdminZombieClaw); ++i) {
		ArrayGetString(gModelsAdminZombieClaw, i, model, charsmax(model));
		precache_model(model);
	}
}

public plugin_natives()
{
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Skip if player doesn't have required admin flags
	if (!(get_user_flags(id) & read_flags(gAccessAdminModels)))
		return;
	
	// Skip for Nemesis
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
		return;
	
	// Apply admin zombie player model?
	if (CvarAdminModelsZombiePlayer) {
		new playerModel[PLAYERMODEL_MAX_LENGTH];
		ArrayGetString(gModelsAdminZombiePlayer, random_num(0, ArraySize(gModelsAdminZombiePlayer) - 1), playerModel, charsmax(playerModel));
		cs_set_user_model(id, playerModel);
	}
	
	// Apply admin zombie claw model?
	if (CvarAdminModelsZombieKnife) {
		new model[MODEL_MAX_LENGTH];
		ArrayGetString(gModelsAdminZombieClaw, random_num(0, ArraySize(gModelsAdminZombieClaw) - 1), model, charsmax(model));
		cs_set_player_view_model(id, CSW_KNIFE, model);
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Skip if player doesn't have required admin flags
	if (!(get_user_flags(id) & read_flags(gAccessAdminModels)))
		return;
	
	// Skip for Survivor
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
		return;
	
	// Apply admin human player model?
	if (CvarAdminModelsHumanPlayer) {
		new playerModel[PLAYERMODEL_MAX_LENGTH];
		ArrayGetString(gModelsAdminHumanPlayer, random_num(0, ArraySize(gModelsAdminHumanPlayer) - 1), playerModel, charsmax(playerModel));
		cs_set_user_model(id, playerModel);
	}
	
	// Apply admin human knife model?
	if (CvarAdminModelsHumanKnife) {
		new model[MODEL_MAX_LENGTH];
		ArrayGetString(gModelsAdminHumanKnife, random_num(0, ArraySize(gModelsAdminHumanKnife) - 1), model, charsmax(model));
		cs_set_player_view_model(id, CSW_KNIFE, model);
	}
}
