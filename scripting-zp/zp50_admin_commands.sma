/*================================================================================
	
	---------------------------
	-*- [ZP] Admin Commands -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <amx_settings_api>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_colorchat>
#include <zp50_log>

#pragma semicolon 1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

#define ACCESSFLAG_MAX_LENGTH 2

// Access flags
new gAccessMakeZombie[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessMakeHuman[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessRespawnPlayers[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessMakeNemesis[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessMakeSurvivor[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessStartGameMode[ACCESSFLAG_MAX_LENGTH] = "d";

new gGameModeInfectionID, gGameModeNemesisID, gGameModeSurvivorID;

new CvarLogAdminCommands;
new amx_show_activity;
new zp_deathmatch;

public plugin_init()
{
	register_plugin("[ZP] Admin Commands", ZP_VERSION_STRING, "ZP Dev Team");
	
	// Admin commands
	register_concmd("zp_zombie", "@ConsoleCommand_Zombie", _, "<target> - Turn someone into a Zombie", 0);
	register_concmd("zp_human", "@ConsoleCommand_Human", _, "<target> - Turn someone back to Human", 0);
	register_concmd("zp_respawn", "@ConsoleCommand_Respawn", _, "<target> - Respawn someone", 0);
	register_concmd("zp_start_game_mode", "@ConsoleCommand_StartGameMode", _, "<game mode id> - Start specific game mode", 0);
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		register_concmd("zp_nemesis", "@ConsoleCommand_Nemesis", _, "<target> - Turn someone into a Nemesis", 0);
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		register_concmd("zp_survivor", "@ConsoleCommand_Survivor", _, "<target> - Turn someone into a Survivor", 0);
	
	bind_pcvar_num(create_cvar("zp_log_admin_commands", "1"), CvarLogAdminCommands);
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", gAccessMakeZombie, charsmax(gAccessMakeZombie)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", gAccessMakeZombie);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE HUMAN", gAccessMakeHuman, charsmax(gAccessMakeHuman)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE HUMAN", gAccessMakeHuman);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE NEMESIS", gAccessMakeNemesis, charsmax(gAccessMakeNemesis)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE NEMESIS", gAccessMakeNemesis);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE SURVIVOR", gAccessMakeSurvivor, charsmax(gAccessMakeSurvivor)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE SURVIVOR", gAccessMakeSurvivor);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "RESPAWN PLAYERS", gAccessRespawnPlayers, charsmax(gAccessRespawnPlayers)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "RESPAWN PLAYERS", gAccessRespawnPlayers);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "START GAME MODE", gAccessStartGameMode, charsmax(gAccessStartGameMode)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "START GAME MODE", gAccessStartGameMode);
}

public plugin_natives()
{
	register_library("zp50_admin_commands");
	register_native("zp_admin_commands_zombie", "@Native_AdminCommandsZombie");
	register_native("zp_admin_commands_human", "@Native_AdminCommandsHuman");
	register_native("zp_admin_commands_nemesis", "@Native_AdminCommandsNemesis");
	register_native("zp_admin_commands_survivor", "@Native_AdminCommandsSurvivor");
	register_native("zp_admin_commands_respawn", "@Native_AdminCommandsRespawn");
	register_native("zp_admin_commands_start_mode", "@Native_AdminCommandsStartGameMode");
	
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

public plugin_cfg()
{
	amx_show_activity = get_cvar_pointer("amx_show_activity");
	zp_deathmatch = get_cvar_pointer("zp_deathmatch");
	gGameModeInfectionID = zp_gamemodes_get_id("Infection Mode");
	gGameModeNemesisID = zp_gamemodes_get_id("Nemesis Mode");
	gGameModeSurvivorID = zp_gamemodes_get_id("Survivor Mode");
}

@Native_AdminCommandsZombie(plugin_id, num_params)
{
	new adminID = get_param(1);
	
	if (!is_user_connected(adminID)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", adminID);
		return false;
	}
	
	new player = get_param(2);
	
	if (!is_user_alive(player)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", player);
		return false;
	}
	
	commandZombie(adminID, player);
	return true;
}

@Native_AdminCommandsHuman(plugin_id, num_params)
{
	new adminID = get_param(1);
	
	if (!is_user_connected(adminID)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", adminID);
		return false;
	}
	
	new player = get_param(2);
	
	if (!is_user_alive(player)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", player);
		return false;
	}
	
	commandHuman(adminID, player);
	return true;
}

@Native_AdminCommandsNemesis(plugin_id, num_params)
{
	new adminID = get_param(1);
	
	if (!is_user_connected(adminID)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", adminID);
		return false;
	}
	
	new player = get_param(2);
	
	if (!is_user_alive(player)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", player);
		return false;
	}
	
	// Nemesis class not present
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		return false;
	
	commandNemesis(adminID, player);
	return true;
}

@Native_AdminCommandsSurvivor(plugin_id, num_params)
{
	new adminID = get_param(1);
	
	if (!is_user_connected(adminID)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", adminID);
		return false;
	}
	
	new player = get_param(2);
	
	if (!is_user_alive(player)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", player);
		return false;
	}
	
	// Survivor class not present
	if (!LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		return false;
	
	commandSurvivor(adminID, player);
	return true;
}

@Native_AdminCommandsRespawn(plugin_id, num_params)
{
	new adminID = get_param(1);
	
	if (!is_user_connected(adminID)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", adminID);
		return false;
	}
	
	new player = get_param(2);
	
	if (!is_user_connected(player)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", player);
		return false;
	}
	
	// Respawn allowed for player?
	if (!allowedToRespawn(player))
		return false;
	
	commandRespawn(adminID, player);
	return true;
}

@Native_AdminCommandsStartGameMode(plugin_id, num_params)
{
	new adminID = get_param(1);
	
	if (!is_user_connected(adminID)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", adminID);
		return false;
	}
	
	new gamemodeID = get_param(2);
	
	// Invalid game mode id
	if (!(0 <= gamemodeID < zp_gamemodes_get_count())) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d).", gamemodeID);
		return false;
	}
	
	commandStartGameMode(adminID, gamemodeID);
	return true;
}

// zp_zombie [target]
@ConsoleCommand_Zombie(id, level, cid)
{
	// Check for access flag - Make Zombie
	if (!cmd_access(id, read_flags(gAccessMakeZombie), cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[32], player;
	read_argv(1, arg, charsmax(arg));
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));
	
	// Invalid target
	if (!player)
		return PLUGIN_HANDLED;
	
	// Target not allowed to be zombie
	if (zp_core_is_zombie(player)) {
		new playerName[32];
		get_user_name(player, playerName, charsmax(playerName));
		client_print(id, print_console, "[ZP] %l (%s).", "ALREADY_ZOMBIE", playerName);
		return PLUGIN_HANDLED;
	}
	
	commandZombie(id, player);
	return PLUGIN_HANDLED;
}

// zp_human [target]
@ConsoleCommand_Human(id, level, cid)
{
	// Check for access flag - Make Human
	if (!cmd_access(id, read_flags(gAccessMakeHuman), cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[32], player;
	read_argv(1, arg, charsmax(arg));
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));
	
	// Invalid target
	if (!player)
		return PLUGIN_HANDLED;
	
	// Target not allowed to be human
	if (!zp_core_is_zombie(player)) {
		new playerName[32];
		get_user_name(player, playerName, charsmax(playerName));
		client_print(id, print_console, "[ZP] %l (%s).", "ALREADY_HUMAN", playerName);
		return PLUGIN_HANDLED;
	}
	
	commandHuman(id, player);
	return PLUGIN_HANDLED;
}

// zp_nemesis [target]
@ConsoleCommand_Nemesis(id, level, cid)
{
	// Check for access flag - Make Nemesis
	if (!cmd_access(id, read_flags(gAccessMakeNemesis), cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[32], player;
	read_argv(1, arg, charsmax(arg));
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));
	
	// Invalid target
	if (!player)
		return PLUGIN_HANDLED;
	
	// Target not allowed to be nemesis
	if (zp_class_nemesis_get(player)) {
		new playerName[32];
		get_user_name(player, playerName, charsmax(playerName));
		client_print(id, print_console, "[ZP] %l (%s).", "ALREADY_NEMESIS", playerName);
		return PLUGIN_HANDLED;
	}
	
	commandNemesis(id, player);
	return PLUGIN_HANDLED;
}

// zp_survivor [target]
@ConsoleCommand_Survivor(id, level, cid)
{
	// Check for access flag - Make Survivor
	if (!cmd_access(id, read_flags(gAccessMakeSurvivor), cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[32], player;
	read_argv(1, arg, charsmax(arg));
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));
	
	// Invalid target
	if (!player)
		return PLUGIN_HANDLED;
	
	// Target not allowed to be survivor
	if (zp_class_survivor_get(player)) {
		new playerName[32];
		get_user_name(player, playerName, charsmax(playerName));
		client_print(id, print_console, "[ZP] %l (%s).", "ALREADY_SURVIVOR", playerName);
		return PLUGIN_HANDLED;
	}
	
	commandSurvivor(id, player);
	return PLUGIN_HANDLED;
}

// zp_respawn [target]
@ConsoleCommand_Respawn(id, level, cid)
{
	// Check for access flag - Respawn
	if (!cmd_access(id, read_flags(gAccessRespawnPlayers), cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[32], player;
	read_argv(1, arg, charsmax(arg));
	player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);
	
	// Invalid target
	if (!player)
		return PLUGIN_HANDLED;
	
	// Target not allowed to be respawned
	if (!allowedToRespawn(id)) {
		new playerName[32];
		get_user_name(player, playerName, charsmax(playerName));
		client_print(id, print_console, "[ZP] %l (%s).", "CANT_RESPAWN", playerName);
		return PLUGIN_HANDLED;
	}
	
	commandRespawn(id, player);
	return PLUGIN_HANDLED;
}

// zp_gamemodes_start [game mode id]
@ConsoleCommand_StartGameMode(id, level, cid)
{
	// Check for access flag - Start Game Mode
	if (!cmd_access(id, read_flags(gAccessStartGameMode), cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new gamemodeID;
	read_argv_int(gamemodeID);
	
	// Invalid game mode id
	if (!(0 <= gamemodeID < zp_gamemodes_get_count())) {
		client_print(id, print_console, "[ZP] %l (%d).", "INVALID_GAME_MODE", gamemodeID);
		return PLUGIN_HANDLED;
	}
	
	commandStartGameMode(id, gamemodeID);
	return PLUGIN_HANDLED;
}

// Checks if a player is allowed to respawn
allowedToRespawn(id)
{
	if (is_user_alive(id))
		return false;
	
	new CsTeams:team = cs_get_user_team(id);
	
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return false;
	
	return true;
}

// Admin Command. zp_zombie
commandZombie(id, player)
{
	// Prevent infecting last human
	if (zp_core_is_last_human(player)) {
		zp_colored_print(id, "%l", "CMD_CANT_LAST_HUMAN");
		return;
	}
	
	// Check if a game mode is in progress
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE) {
		// Infection mode disabled
		if (gGameModeInfectionID == ZP_INVALID_GAME_MODE) {
			zp_colored_print(id, "%l", "CMD_ONLY_AFTER_GAME_MODE");
			return;
		}
		
		// Start infection game mode with this target player
		if (!zp_gamemodes_start(gGameModeInfectionID, player)) {
			zp_colored_print(id, "%l", "GAME_MODE_CANT_START");
			return;
		}
	} else {
		// Make player infect himself
		zp_core_infect(player, player);
	}

	showActivity(id, player, "CMD_INFECT");
}

// Admin Command. zp_human
commandHuman(id, player)
{
	// Prevent infecting last zombie
	if (zp_core_is_last_zombie(player)) {
		zp_colored_print(id, "%l", "CMD_CANT_LAST_ZOMBIE");
		return;
	}
	
	// No game mode currently in progress
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE) {
		zp_colored_print(id, "%l", "CMD_ONLY_AFTER_GAME_MODE");
		return;
	}
	
	// Make player cure himself
	zp_core_cure(player, player);

	showActivity(id, player, "CMD_DISINFECT");
}

// Admin Command. zp_nemesis
commandNemesis(id, player)
{
	// Prevent infecting last human
	if (zp_core_is_last_human(player)) {
		zp_colored_print(id, "%l", "CMD_CANT_LAST_HUMAN");
		return;
	}
	
	// Check if a game mode is in progress
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE) {
		// Nemesis mode disabled
		if (gGameModeNemesisID == ZP_INVALID_GAME_MODE) {
			zp_colored_print(id, "%l", "CMD_ONLY_AFTER_GAME_MODE");
			return;
		}
		
		// Start nemesis game mode with this target player
		if (!zp_gamemodes_start(gGameModeNemesisID, player)) {
			zp_colored_print(id, "%l", "GAME_MODE_CANT_START");
			return;
		}
	} else {
		// Make player nemesis
		zp_class_nemesis_set(player);
	}
	
	showActivity(id, player, "CMD_NEMESIS");
}

// Admin Command. zp_survivor
commandSurvivor(id, player)
{
	// Prevent infecting last zombie
	if (zp_core_is_last_zombie(player)) {
		zp_colored_print(id, "%l", "CMD_CANT_LAST_ZOMBIE");
		return;
	}
	
	// Check if a game mode is in progress
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE) {
		// Survivor mode disabled
		if (gGameModeSurvivorID == ZP_INVALID_GAME_MODE) {
			zp_colored_print(id, "%l", "CMD_ONLY_AFTER_GAME_MODE");
			return;
		}
		
		// Start survivor game mode with this target player
		if (!zp_gamemodes_start(gGameModeSurvivorID, player)) {
			zp_colored_print(id, "%l", "GAME_MODE_CANT_START");
			return;
		}
	} else {
		// Make player survivor
		zp_class_survivor_set(player);
	}
	
	showActivity(id, player, "CMD_SURVIVAL");
}

// Admin Command. zp_respawn
commandRespawn(id, player)
{
	// Deathmatch module active?
	if (zp_deathmatch) {
		// Respawn as zombie?
		switch (get_pcvar_num(zp_deathmatch)) {
			case 2: {
				respawnAsZombieDuringGameMode(player);
			}
			case 3: {
				if (random_num(0, 1))
					respawnAsZombieDuringGameMode(player);
			}
			case 4: {
				if (zp_core_get_zombie_count() < getAliveCount() / 2)
					respawnAsZombieDuringGameMode(player);
			}
		}
	}
	
	// Respawn player!
	ExecuteHamB(Ham_CS_RoundRespawn, player);

	showActivity(id, player, "CMD_RESPAWN");
}

respawnAsZombieDuringGameMode(id)
{
	// Only allow respawning as zombie after a game mode started
	if (zp_gamemodes_get_current() != ZP_NO_GAME_MODE)
		zp_core_respawn_as_zombie(id, true);
}

// Admin Command. zp_start_game_mode
commandStartGameMode(id, gamemodeID)
{
	// Attempt to start game mode
	if (!zp_gamemodes_start(gamemodeID)) {
		zp_colored_print(id, "%l", "GAME_MODE_CANT_START");
		return;
	}
	
	// Get user names
	new adminName[32], modeName[32];
	get_user_name(id, adminName, charsmax(adminName));
	zp_gamemodes_get_name(gamemodeID, modeName, charsmax(modeName));
	
	// Show activity?
	if (amx_show_activity) {
		switch (get_pcvar_num(amx_show_activity)) {
			case 1: { // hide name from all users
				zp_colored_print(0, "ADMIN - %l: %s", "CMD_START_GAME_MODE", modeName);
			}
			case 2: { // show name to all users
				zp_colored_print(0, "ADMIN %s - %l: %s", adminName, "CMD_START_GAME_MODE", modeName);
			}
			case 3: { // show name only to admins, hide name from normal users
				for (new i = 1; i <= MaxClients; ++i) {
					if (!is_user_connected(i))
						continue;
					
					if (is_user_admin(i))
						zp_colored_print(i, "ADMIN %s - %l: %s", adminName, "CMD_START_GAME_MODE", modeName);
					else
						zp_colored_print(i, "ADMIN - %l: %s", "CMD_START_GAME_MODE", modeName);
				}
			}
			case 4: { // show name only to admins, display nothing to normal players
				for (new i = 1; i <= MaxClients; ++i) {
					if (is_user_connected(i) && is_user_admin(i))
						zp_colored_print(i, "ADMIN %s - %l: %s", adminName, "CMD_START_GAME_MODE", modeName);
				}
			}
			case 5: { // hide name to admins, display nothing to normal players
				for (new i = 1; i <= MaxClients; ++i) {
					if (is_user_connected(i) && is_user_admin(i))
						zp_colored_print(i, "ADMIN - %l: %s", "CMD_START_GAME_MODE", modeName);
				}
			}
		}
	}
	
	// Log to Zombie Plague log file?
	if (CvarLogAdminCommands) {
		new authid[32], ip[16];
		get_user_authid(id, authid, charsmax(authid));
		get_user_ip(id, ip, charsmax(ip), 1);
		zp_log("ADMIN %s <%s><%s> - %L: %s (Players: %d)", adminName, authid, ip, LANG_SERVER, "CMD_START_GAME_MODE", modeName, getPlayingCount());
	}
}

showActivity(admin, player, const LANG_KEY[])
{
	// Get user names
	new adminName[32], playerName[32];
	get_user_name(admin, adminName, charsmax(adminName));
	get_user_name(player, playerName, charsmax(playerName));
	
	// Show activity?
	if (amx_show_activity) {
		switch (get_pcvar_num(amx_show_activity)) {
			case 1: { // hide name from all users
				zp_colored_print(0, "ADMIN - %s %l", playerName, LANG_KEY);
			}
			case 2: { // show name to all users
				zp_colored_print(0, "ADMIN %s - %s %l", adminName, playerName, LANG_KEY);
			}
			case 3: { // show name only to admins, hide name from normal users
				for (new i = 1; i <= MaxClients; ++i) {
					if (!is_user_connected(i))
						continue;
					
					if (is_user_admin(i))
						zp_colored_print(i, "ADMIN %s - %s %l", adminName, playerName, LANG_KEY);
					else
						zp_colored_print(i, "ADMIN - %s %l", playerName, LANG_KEY);
				}
			}
			case 4: { // show name only to admins, display nothing to normal players
				for (new i = 1; i <= MaxClients; ++i) {
					if (is_user_connected(i) && is_user_admin(i))
						zp_colored_print(i, "ADMIN %s - %s %l", adminName, playerName, LANG_KEY);
				}
			}
			case 5: { // hide name to admins, display nothing to normal players
				for (new i = 1; i <= MaxClients; ++i) {
					if (is_user_connected(i) && is_user_admin(i))
						zp_colored_print(i, "ADMIN - %s %l", playerName, LANG_KEY);
				}
			}
		}
	}

	// Log to Zombie Plague log file?
	if (CvarLogAdminCommands) {
		new authid[32], ip[16];
		get_user_authid(admin, authid, charsmax(authid));
		get_user_ip(admin, ip, charsmax(ip), 1);
		zp_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", adminName, authid, ip, playerName, LANG_SERVER, LANG_KEY, getPlayingCount());
	}
}

// Get Playing Count -returns number of users playing-
getPlayingCount()
{
	new CsTeams:team, playing;
	new players[MAX_PLAYERS], playerCount, player;
	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);
	
	for (new i = 0; i < playerCount; ++i) {
		player = players[i];
		
		team = cs_get_user_team(player);
		
		if (team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED)
			++playing;
	}
	
	return playing;
}

// Get Alive Count -returns alive players number-
getAliveCount()
{
	return get_playersnum_ex(GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);
}
