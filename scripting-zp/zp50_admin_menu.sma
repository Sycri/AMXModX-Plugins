/*================================================================================
	
	-----------------------
	-*- [ZP] Admin Menu -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <zp50_core>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_admin_commands>
#include <zp50_colorchat>

#pragma semicolon 1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

#define ACCESSFLAG_MAX_LENGTH 2

// Access flags
new gAccessMakeZombie[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessMakeHuman[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessMakeNemesis[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessMakeSurvivor[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessRespawnPlayers[ACCESSFLAG_MAX_LENGTH] = "d";
new gAccessStartGameMode[ACCESSFLAG_MAX_LENGTH] = "d";

// Admin menu actions
enum
{
	ACTION_INFECT_CURE = 0,
	ACTION_MAKE_NEMESIS,
	ACTION_MAKE_SURVIVOR,
	ACTION_RESPAWN_PLAYER,
	ACTION_START_GAME_MODE
}

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0;

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205;

// For player/mode list menu handlers
#define PL_ACTION gMenuData[id][0]
#define MENU_PAGE_PLAYERS gMenuData[id][1]
#define MENU_PAGE_GAME_MODES gMenuData[id][2]
new gMenuData[MAX_PLAYERS + 1][3];

public plugin_init()
{
	register_plugin("[ZP] Admin Menu", ZP_VERSION_STRING, "ZP Dev Team");
	
	register_menu("Admin Menu", KEYSMENU, "@Menu_Admin");
	register_clcmd("say /adminmenu", "@ClientCommand_AdminMenu");
	register_clcmd("say adminmenu", "@ClientCommand_AdminMenu");
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", gAccessMakeZombie, charsmax(gAccessMakeZombie)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", gAccessMakeZombie);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE HUMAN", gAccessMakeHuman, charsmax(gAccessMakeHuman)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", gAccessMakeHuman);
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
	register_library("zp50_admin_menu");
	register_native("zp_admin_menu_show", "@Native_AdminMenuShow");
	
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

@Native_AdminMenuShow(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	showMenuAdmin(id);
	return true;
}

public client_disconnected(id)
{
	// Reset remembered menu pages
	MENU_PAGE_GAME_MODES = 0;
	MENU_PAGE_PLAYERS = 0;
}

@ClientCommand_AdminMenu(id)
{
	showMenuAdmin(id);
}

// Admin Menu
showMenuAdmin(id)
{
	static menu[250];
	new len, userFlags = get_user_flags(id);
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%l:^n^n", "MENU_ADMIN_TITLE");
	
	// 1. Infect/Cure command
	if (userFlags & (read_flags(gAccessMakeZombie) | read_flags(gAccessMakeHuman)))
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %l^n", "MENU_ADMIN1");
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %l^n", "MENU_ADMIN1");
	
	// 2. Nemesis command
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userFlags & read_flags(gAccessMakeNemesis)))
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %l^n", "MENU_ADMIN2");
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %l^n", "MENU_ADMIN2");
	
	// 3. Survivor command
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userFlags & read_flags(gAccessMakeSurvivor)))
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %l^n", "MENU_ADMIN3");
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %l^n", "MENU_ADMIN3");
	
	// 4. Respawn command
	if (userFlags & read_flags(gAccessRespawnPlayers))
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %l^n", "MENU_ADMIN4");
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %l^n", "MENU_ADMIN4");
	
	// 5. Start Game Mode command
	if (userFlags & read_flags(gAccessStartGameMode))
		len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %l^n", "MENU_ADMIN_START_GAME_MODE");
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d5. %l^n", "MENU_ADMIN_START_GAME_MODE");
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n\r0.\w %l", "MENU_EXIT");
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, KEYSMENU, menu, -1, "Admin Menu");
}

// Player List Menu
showMenuPlayerList(id)
{
	static menu[128], playerName[32];
	new menuid, player, buffer[2], userFlags = get_user_flags(id);
	
	// Title
	switch (PL_ACTION) {
		case ACTION_INFECT_CURE: formatex(menu, charsmax(menu), "%l\r", "MENU_ADMIN1");
		case ACTION_MAKE_NEMESIS: formatex(menu, charsmax(menu), "%l\r", "MENU_ADMIN2");
		case ACTION_MAKE_SURVIVOR: formatex(menu, charsmax(menu), "%l\r", "MENU_ADMIN3");
		case ACTION_RESPAWN_PLAYER: formatex(menu, charsmax(menu), "%l\r", "MENU_ADMIN4");
	}
	menuid = menu_create(menu, "@Menu_PlayerList");
	
	// Player List
	for (player = 1; player <= MaxClients; ++player) {
		// Skip if not connected
		if (!is_user_connected(player))
			continue;
		
		// Get player's name
		get_user_name(player, playerName, charsmax(playerName));
		
		// Format text depending on the action to take
		switch (PL_ACTION) {
			case ACTION_INFECT_CURE: { // Infect/Cure command
				if (zp_core_is_zombie(player)) {
					if ((userFlags & read_flags(gAccessMakeHuman)) && is_user_alive(player))
						formatex(menu, charsmax(menu), "%s \r[%l]", playerName, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE");
					else
						formatex(menu, charsmax(menu), "\d%s [%l]", playerName, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE");
				} else {
					if ((userFlags & read_flags(gAccessMakeZombie)) && is_user_alive(player))
						formatex(menu, charsmax(menu), "%s \y[%l]", playerName, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN");
					else
						formatex(menu, charsmax(menu), "\d%s [%l]", playerName, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN");
				}
			}
			case ACTION_MAKE_NEMESIS: { // Nemesis command
				if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userFlags & read_flags(gAccessMakeNemesis)) && is_user_alive(player) && !zp_class_nemesis_get(player)) {
					if (zp_core_is_zombie(player))
						formatex(menu, charsmax(menu), "%s \r[%l]", playerName, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE");
					else
						formatex(menu, charsmax(menu), "%s \y[%l]", playerName, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN");
				} else {
					formatex(menu, charsmax(menu), "\d%s [%l]", playerName, zp_core_is_zombie(player) ? (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN");
				}
			}
			case ACTION_MAKE_SURVIVOR: { // Survivor command
				if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userFlags & read_flags(gAccessMakeSurvivor)) && is_user_alive(player) && !zp_class_survivor_get(player)) {
					if (zp_core_is_zombie(player))
						formatex(menu, charsmax(menu), "%s \r[%l]", playerName, (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE");
					else
						formatex(menu, charsmax(menu), "%s \y[%l]", playerName, (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN");
				} else {
					formatex(menu, charsmax(menu), "\d%s [%l]", playerName, zp_core_is_zombie(player) ? (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player)) ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player)) ? "CLASS_SURVIVOR" : "CLASS_HUMAN");
				}
			}
			case ACTION_RESPAWN_PLAYER: { // Respawn command
				if ((userFlags & read_flags(gAccessRespawnPlayers)) && allowedToRespawn(player))
					formatex(menu, charsmax(menu), "%s", playerName);
				else
					formatex(menu, charsmax(menu), "\d%s", playerName);
			}
		}
		
		// Add player
		buffer[0] = player;
		buffer[1] = 0;
		menu_additem(menuid, menu, buffer);
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%l", "MENU_BACK");
	menu_setprop(menuid, MPROP_BACKNAME, menu);
	formatex(menu, charsmax(menu), "%l", "MENU_NEXT");
	menu_setprop(menuid, MPROP_NEXTNAME, menu);
	formatex(menu, charsmax(menu), "%l", "MENU_EXIT");
	menu_setprop(menuid, MPROP_EXITNAME, menu);
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_PLAYERS = min(MENU_PAGE_PLAYERS, menu_pages(menuid) - 1);
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	menu_display(id, menuid, MENU_PAGE_PLAYERS);
}

// Game Mode List Menu
showMenuGameModeList(id)
{
	static menu[128], transkey[64];
	new menuid, i, itemData[2], gamemodeCount = zp_gamemodes_get_count();
	
	// Title
	formatex(menu, charsmax(menu), "%l:\r", "MENU_INFO4");
	menuid = menu_create(menu, "@Menu_GameModeList");
	
	// Item List
	for (i = 0; i < gamemodeCount; ++i) {
		// Add Game Mode Name
		zp_gamemodes_get_name(i, menu, charsmax(menu));
		
		// ML support for mode name
		formatex(transkey, charsmax(transkey), "MODENAME %s", menu);
		if (GetLangTransKey(transkey) != TransKey_Bad)
			formatex(menu, charsmax(menu), "%l", transkey);
		
		itemData[0] = i;
		itemData[1] = 0;
		menu_additem(menuid, menu, itemData);
	}
	
	// No game modes to display?
	if (menu_items(menuid) <= 0) {
		menu_destroy(menuid);
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%l", "MENU_BACK");
	menu_setprop(menuid, MPROP_BACKNAME, menu);
	formatex(menu, charsmax(menu), "%l", "MENU_NEXT");
	menu_setprop(menuid, MPROP_NEXTNAME, menu);
	formatex(menu, charsmax(menu), "%l", "MENU_EXIT");
	menu_setprop(menuid, MPROP_EXITNAME, menu);
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_GAME_MODES = min(MENU_PAGE_GAME_MODES, menu_pages(menuid) - 1);
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	menu_display(id, menuid, MENU_PAGE_GAME_MODES);
}

// Admin Menu
@Menu_Admin(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	new userFlags = get_user_flags(id);
	
	switch (key) {
		case ACTION_INFECT_CURE: { // Infect/Cure command
			if (userFlags & (read_flags(gAccessMakeZombie) | read_flags(gAccessMakeHuman))) {
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_INFECT_CURE;
				showMenuPlayerList(id);
			} else {
				zp_colored_print(id, "%l", "CMD_NOT_ACCESS");
				showMenuAdmin(id);
			}
		}
		case ACTION_MAKE_NEMESIS: { // Nemesis command
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userFlags & read_flags(gAccessMakeNemesis))) {
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_MAKE_NEMESIS;
				showMenuPlayerList(id);
			} else {
				zp_colored_print(id, "%l", "CMD_NOT_ACCESS");
				showMenuAdmin(id);
			}
		}
		case ACTION_MAKE_SURVIVOR: { // Survivor command
			if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userFlags & read_flags(gAccessMakeSurvivor))) {
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_MAKE_SURVIVOR;
				showMenuPlayerList(id);
			} else {
				zp_colored_print(id, "%l", "CMD_NOT_ACCESS");
				showMenuAdmin(id);
			}
		}
		case ACTION_RESPAWN_PLAYER: { // Respawn command
			if (userFlags & read_flags(gAccessRespawnPlayers)) {
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_RESPAWN_PLAYER;
				showMenuPlayerList(id);
			} else {
				zp_colored_print(id, "%l", "CMD_NOT_ACCESS");
				showMenuAdmin(id);
			}
		}
		case ACTION_START_GAME_MODE: { // Start Game Mode command
			if (userFlags & read_flags(gAccessStartGameMode)) {
				showMenuGameModeList(id);
			} else {
				zp_colored_print(id, "%l", "CMD_NOT_ACCESS");
				showMenuAdmin(id);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

// Player List Menu
@Menu_PlayerList(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT) {
		MENU_PAGE_PLAYERS = 0;
		menu_destroy(menuid);
		showMenuAdmin(id);
		return PLUGIN_HANDLED;
	}
	
	// Remember player's menu page
	MENU_PAGE_PLAYERS = item / 7;
	
	// Retrieve player id
	new buffer[2], player;
	menu_item_getinfo(menuid, item, _, buffer, charsmax(buffer));
	player = buffer[0];
	
	// Perform action on player
	
	// Get admin flags
	new userFlags = get_user_flags(id);
	
	// Make sure it's still connected
	if (is_user_connected(player)) {
		// Perform the right action if allowed
		switch (PL_ACTION) {
			case ACTION_INFECT_CURE: { // Infect/Cure command
				if (zp_core_is_zombie(player)) {
					if ((userFlags & read_flags(gAccessMakeHuman)) && is_user_alive(player))
						zp_admin_commands_human(id, player);
					else
						zp_colored_print(id, "%l", "CMD_NOT");
				} else {
					if ((userFlags & read_flags(gAccessMakeZombie)) && is_user_alive(player))
						zp_admin_commands_zombie(id, player);
					else
						zp_colored_print(id, "%l", "CMD_NOT");
				}
			}
			case ACTION_MAKE_NEMESIS: { // Nemesis command
				if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && (userFlags & read_flags(gAccessMakeNemesis)) && is_user_alive(player) && !zp_class_nemesis_get(player))
					zp_admin_commands_nemesis(id, player);
				else
					zp_colored_print(id, "%l", "CMD_NOT");
			}
			case ACTION_MAKE_SURVIVOR: { // Survivor command
				if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && (userFlags & read_flags(gAccessMakeSurvivor)) && is_user_alive(player) && !zp_class_survivor_get(player))
					zp_admin_commands_survivor(id, player);
				else
					zp_colored_print(id, "%l", "CMD_NOT");
			}
			case ACTION_RESPAWN_PLAYER: { // Respawn command
				if ((userFlags & read_flags(gAccessRespawnPlayers)) && allowedToRespawn(player))
					zp_admin_commands_respawn(id, player);
				else
					zp_colored_print(id, "%l", "CMD_NOT");
			}
		}
	} else {
		zp_colored_print(id, "%l", "CMD_NOT");
	}
	
	menu_destroy(menuid);
	showMenuPlayerList(id);
	return PLUGIN_HANDLED;
}

// Game Mode List Menu
@Menu_GameModeList(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT) {
		MENU_PAGE_GAME_MODES = 0;
		menu_destroy(menuid);
		showMenuAdmin(id);
		return PLUGIN_HANDLED;
	}
	
	// Remember game modes menu page
	MENU_PAGE_GAME_MODES = item / 7;
	
	// Retrieve game mode id
	new itemData[2], gamemodeID;
	menu_item_getinfo(menuid, item, _, itemData, charsmax(itemData));
	gamemodeID = itemData[0];
	
	// Attempt to start game mode
	zp_admin_commands_start_mode(id, gamemodeID);

	menu_destroy(menuid);
	showMenuGameModeList(id);
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
