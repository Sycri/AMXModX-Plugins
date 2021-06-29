/*================================================================================
	
	-----------------------------
	-*- [ZP] Custom Buy Menus -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <zp50_core>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_colorchat>

#pragma semicolon 1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

// Buy Menu: Primary and Secondary Weapons
new const primaryItems[][] = { "weapon_galil", "weapon_famas", "weapon_m4a1", "weapon_ak47", "weapon_sg552", "weapon_aug", "weapon_scout",
				"weapon_m3", "weapon_xm1014", "weapon_tmp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_p90" };
new const secondaryItems[][] = { "weapon_glock18", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_fiveseven", "weapon_elite" };

// Buy Menu: Grenades
new const grenadesItems[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" };

#define WEAPONITEM_MAX_LENGTH 32

new Array:gPrimaryItems;
new Array:gSecondaryItems;
new Array:gGrenadesItems;

// Primary and Secondary Weapon Names
new const WEAPONNAMES[][] = { "", "P228 Compact", "", "Schmidt Scout", "HE Grenade", "XM1014 M4", "", "Ingram MAC-10", "Steyr AUG A1",
			"Smoke Grenade", "Dual Elite Berettas", "FiveseveN", "UMP 45", "SG-550 Auto-Sniper", "IMI Galil", "Famas",
			"USP .45 ACP Tactical", "Glock 18C", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun",
			"M3 Super 90", "M4A1 Carbine", "Schmidt TMP", "G3SG1 Auto-Sniper", "Flashbang", "Desert Eagle .50 AE",
			"SG-552 Commando", "AK-47 Kalashnikov", "", "ES P90" };

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 };

// Ammo IDs for weapons
new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 };

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" };

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1;

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = CSW_ALL_SHOTGUNS | CSW_ALL_SMGS | CSW_ALL_RIFLES | CSW_ALL_SNIPERRIFLES | CSW_ALL_MACHINEGUNS;

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define PRIMARY_AND_SECONDARY 3
#define GRENADES_ONLY 4

// For weapon buy menu handlers
#define WPN_STARTID		gMenuData[id][0]
#define WPN_MAXIDS		ArraySize(gPrimaryItems)
#define WPN_SELECTION	(gMenuData[id][0]+key)
#define WPN_AUTO_ON		gMenuData[id][1]
#define WPN_AUTO_PRI	gMenuData[id][2]
#define WPN_AUTO_SEC	gMenuData[id][3]
#define WPN_AUTO_GREN	gMenuData[id][4]

#define flag_get(%1,%2)			(%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2)	(flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2)			%1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2)		%1 &= ~(1 << (%2 & 31))

// Menu selections
const MENU_KEY_AUTOSELECT = 7;
const MENU_KEY_BACK = 7;
const MENU_KEY_NEXT = 8;
const MENU_KEY_EXIT = 9;

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0;

new gCanBuyPrimary;
new gCanBuySecondary;
new gCanBuyGrenades;
new gMenuData[MAX_PLAYERS + 1][5];
new Float:gBuyTimeStart[MAX_PLAYERS+1];

new CvarRandomPrimary, CvarRandomSecondary, CvarRandomGrenades;
new Float:CvarBuyCustomTime, CvarBuyCustomPrimary, CvarBuyCustomSecondary, CvarBuyCustomGrenades;
new CvarGiveAllGrenades;

public plugin_init()
{
	register_plugin("[ZP] Custom Buy Menus", ZP_VERSION_STRING, "ZP Dev Team");
	
	bind_pcvar_num(create_cvar("zp_random_primary", "0"), CvarRandomPrimary);
	bind_pcvar_num(create_cvar("zp_random_secondary", "0"), CvarRandomSecondary);
	bind_pcvar_num(create_cvar("zp_random_grenades", "0"), CvarRandomGrenades);
	
	bind_pcvar_float(create_cvar("zp_buy_custom_time", "15"), CvarBuyCustomTime);
	bind_pcvar_num(create_cvar("zp_buy_custom_primary", "1"), CvarBuyCustomPrimary);
	bind_pcvar_num(create_cvar("zp_buy_custom_secondary", "1"), CvarBuyCustomSecondary);
	bind_pcvar_num(create_cvar("zp_buy_custom_grenades", "0"), CvarBuyCustomGrenades);
	
	bind_pcvar_num(create_cvar("zp_give_all_grenades", "1"), CvarGiveAllGrenades);
	
	register_clcmd("say /buy", "@ClientCommand_Buy");
	register_clcmd("say buy", "@ClientCommand_Buy");
	register_clcmd("say /guns", "@ClientCommand_Buy");
	register_clcmd("say guns", "@ClientCommand_Buy");
	
	// Menus
	register_menu("Buy Menu Primary", KEYSMENU, "@Menu_BuyPrimary");
	register_menu("Buy Menu Secondary", KEYSMENU, "@Menu_BuySecondary");
	register_menu("Buy Menu Grenades", KEYSMENU, "@Menu_BuyGrenades");
}

public plugin_precache()
{
	// Initialize arrays
	gPrimaryItems = ArrayCreate(WEAPONITEM_MAX_LENGTH, 1);
	gSecondaryItems = ArrayCreate(WEAPONITEM_MAX_LENGTH, 1);
	gGrenadesItems = ArrayCreate(WEAPONITEM_MAX_LENGTH, 1);
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "PRIMARY", gPrimaryItems);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "SECONDARY", gSecondaryItems);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "GRENADES", gGrenadesItems);
	
	// If we couldn't load from file, use and save default ones
	new i;
	if (ArraySize(gPrimaryItems) == 0) {
		for (i = 0; i < sizeof primaryItems; ++i)
			ArrayPushString(gPrimaryItems, primaryItems[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "PRIMARY", gPrimaryItems);
	}
	if (ArraySize(gSecondaryItems) == 0) {
		for (i = 0; i < sizeof secondaryItems; ++i)
			ArrayPushString(gSecondaryItems, secondaryItems[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "SECONDARY", gSecondaryItems);
	}
	if (ArraySize(gGrenadesItems) == 0) {
		for (i = 0; i < sizeof grenadesItems; ++i)
			ArrayPushString(gGrenadesItems, grenadesItems[i]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Buy Menu Weapons", "GRENADES", gGrenadesItems);
	}
}

public plugin_natives()
{
	register_library("zp50_buy_menus");
	register_native("zp_buy_menus_show", "@Native_BuyMenusShow");
	
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

@Native_BuyMenusShow(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	@ClientCommand_Buy(id);
	return true;
}

@ClientCommand_Buy(id)
{
	if (WPN_AUTO_ON) {
		zp_colored_print(id, "%l", "BUY_ENABLED");
		WPN_AUTO_ON = 0;
	}
	
	// Player dead or zombie
	if (!is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	showAvailableBuyMenus(id);
}

public client_disconnected(id)
{
	WPN_AUTO_ON = 0;
	WPN_STARTID = 0;
}

public zp_fw_core_cure_post(id, attacker)
{
	// Buyzone time starts when player is set to human
	gBuyTimeStart[id] = get_gametime();
	
	// Task added so that previous weapons are dropped on spawn event (bugfix)
	remove_task(id);
	set_task(0.1, "@Task_HumanWeapons", id);
}

@Task_HumanWeapons(id)
{
	// Player dead or zombie
	if (!is_user_alive(id) || zp_core_is_zombie(id))
		return;
	
	// Survivor automatically gets his own weapon
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id)) {
		flag_unset(gCanBuyPrimary, id);
		flag_unset(gCanBuySecondary, id);
		flag_unset(gCanBuyGrenades, id);
		return;
	}
	
	// Random weapons settings
	if (CvarRandomPrimary)
		buyPrimaryWeapon(id, random_num(0, ArraySize(gPrimaryItems) - 1));
	if (CvarRandomSecondary)
		buySecondaryWeapon(id, random_num(0, ArraySize(gSecondaryItems) - 1));
	if (CvarRandomGrenades)
		buyGrenades(id, random_num(0, ArraySize(gGrenadesItems) - 1));
	
	// Custom buy menus
	if (CvarBuyCustomPrimary) {
		flag_set(gCanBuyPrimary, id);
		
		if (is_user_bot(id))
			buyPrimaryWeapon(id, random_num(0, ArraySize(gPrimaryItems) - 1));
		else if (WPN_AUTO_ON)
			buyPrimaryWeapon(id, WPN_AUTO_PRI);
	}
	if (CvarBuyCustomSecondary) {
		flag_set(gCanBuySecondary, id);
		
		if (is_user_bot(id))
			buySecondaryWeapon(id, random_num(0, ArraySize(gSecondaryItems) - 1));
		else if (WPN_AUTO_ON)
			buySecondaryWeapon(id, WPN_AUTO_SEC);
	}
	if (CvarBuyCustomGrenades) {
		flag_set(gCanBuyGrenades, id);
		
		if (is_user_bot(id))
			buyGrenades(id, random_num(0, ArraySize(gGrenadesItems) - 1));
		else if (WPN_AUTO_ON)
			buyGrenades(id, WPN_AUTO_GREN);
	}
	
	// Open available buy menus
	showAvailableBuyMenus(id);
	
	// Automatically give all grenades?
	if (CvarGiveAllGrenades) {
		// Strip first
		strip_weapons(id, GRENADES_ONLY);
		for (new i = 0; i < ArraySize(gGrenadesItems); ++i)
			buyGrenades(id, i);
	}
}

// Shows the next available buy menu
showAvailableBuyMenus(id)
{
	if (flag_get(gCanBuyPrimary, id))
		showMenuBuyPrimary(id);
	else if (flag_get(gCanBuySecondary, id))
		showMenuBuySecondary(id);
	else if (flag_get(gCanBuyGrenades, id))
		showMenuBuyGrenades(id);
}

// Buy Menu Primary
showMenuBuyPrimary(id)
{
	new menuTime = floatround(gBuyTimeStart[id] + CvarBuyCustomTime - get_gametime());
	if (menuTime <= 0) {
		zp_colored_print(id, "%l", "BUY_MENU_TIME_EXPIRED");
		return;
	}
	
	static menu[300], weaponName[32];
	new len, i, maxLoops = min(WPN_STARTID + 7, WPN_MAXIDS);
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%l \r[%d-%d]^n^n", "MENU_BUY1_TITLE", WPN_STARTID + 1, min(WPN_STARTID + 7, WPN_MAXIDS));
	
	// 1-7. Weapon List
	for (i = WPN_STARTID; i < maxLoops; ++i) {
		ArrayGetString(gPrimaryItems, i, weaponName, charsmax(weaponName));
		len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w %s^n", i - WPN_STARTID + 1, WEAPONNAMES[get_weaponid(weaponName)]);
	}
	
	// 8. Auto Select
	len += formatex(menu[len], charsmax(menu) - len, "^n\r8.\w %l \y[%l]", "MENU_AUTOSELECT", (WPN_AUTO_ON) ? "MOTD_ENABLED" : "MOTD_DISABLED");
	
	// 9. Next/Back - 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r9.\w %l/%l^n^n\r0.\w %l", "MENU_NEXT", "MENU_BACK", "MENU_EXIT");
	
	show_menu(id, KEYSMENU, menu, menuTime, "Buy Menu Primary");
}

// Buy Menu Secondary
showMenuBuySecondary(id)
{
	new menuTime = floatround(gBuyTimeStart[id] + CvarBuyCustomTime - get_gametime());
	if (menuTime <= 0) {
		zp_colored_print(id, "%l", "BUY_MENU_TIME_EXPIRED");
		return;
	}
	
	static menu[250], weaponName[32];
	new len, i, maxLoops = ArraySize(gSecondaryItems);
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%l^n", "MENU_BUY2_TITLE");
	
	// 1-6. Weapon List
	for (i = 0; i < maxLoops; ++i) {
		ArrayGetString(gSecondaryItems, i, weaponName, charsmax(weaponName));
		len += formatex(menu[len], charsmax(menu) - len, "^n\r%d.\w %s", i + 1, WEAPONNAMES[get_weaponid(weaponName)]);
	}
	
	// 8. Auto Select
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r8.\w %l \y[%l]", "MENU_AUTOSELECT", (WPN_AUTO_ON) ? "MOTD_ENABLED" : "MOTD_DISABLED");
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %l", "MENU_EXIT");
	
	show_menu(id, KEYSMENU, menu, menuTime, "Buy Menu Secondary");
}

// Buy Menu Grenades
showMenuBuyGrenades(id)
{
	new menuTime = floatround(gBuyTimeStart[id] + CvarBuyCustomTime - get_gametime());
	if (menuTime <= 0) {
		zp_colored_print(id, "%l", "BUY_MENU_TIME_EXPIRED");
		return;
	}
	
	static menu[250], weaponName[32];
	new len, i, maxLoops = ArraySize(gGrenadesItems);
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%l^n", "MENU_BUY3_TITLE");
	
	// 1-3. Item List
	for (i = 0; i < maxLoops; ++i) {
		ArrayGetString(gGrenadesItems, i, weaponName, charsmax(weaponName));
		len += formatex(menu[len], charsmax(menu) - len, "^n\r%d.\w %s", i + 1, WEAPONNAMES[get_weaponid(weaponName)]);
	}
	
	// 8. Auto Select
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r8.\w %l \y[%l]", "MENU_AUTOSELECT", (WPN_AUTO_ON) ? "MOTD_ENABLED" : "MOTD_DISABLED");
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %l", "MENU_EXIT");
	
	show_menu(id, KEYSMENU, menu, menuTime, "Buy Menu Grenades");
}

// Buy Menu Primary
@Menu_BuyPrimary(id, key)
{
	// Player dead or zombie or already bought primary
	if (!is_user_alive(id) || zp_core_is_zombie(id) || !flag_get(gCanBuyPrimary, id))
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= MENU_KEY_AUTOSELECT || WPN_SELECTION >= WPN_MAXIDS) {
		switch (key) {
			case MENU_KEY_AUTOSELECT: {// toggle auto select
				WPN_AUTO_ON = 1 - WPN_AUTO_ON;
			}
			case MENU_KEY_NEXT: {// next/back
				if (WPN_STARTID + 7 < WPN_MAXIDS)
					WPN_STARTID += 7;
				else
					WPN_STARTID = 0;
			}
			case MENU_KEY_EXIT: {// exit
				return PLUGIN_HANDLED;
			}
		}
		
		// Show buy menu again
		showMenuBuyPrimary(id);
		return PLUGIN_HANDLED;
	}
	
	// Store selected weapon id
	WPN_AUTO_PRI = WPN_SELECTION;
	
	// Buy primary weapon
	buyPrimaryWeapon(id, WPN_AUTO_PRI);
	
	// Show next buy menu
	showAvailableBuyMenus(id);
	
	return PLUGIN_HANDLED;
}

// Buy Primary Weapon
buyPrimaryWeapon(id, selection)
{
	// Drop previous primary weapon
	drop_weapons(id, PRIMARY_ONLY);
	
	// Get weapon's id
	static weaponName[32];
	ArrayGetString(gPrimaryItems, selection, weaponName, charsmax(weaponName));
	new weaponID = get_weaponid(weaponName);
	
	// Give the new weapon and full ammo
	give_item(id, weaponName);
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponID], AMMOTYPE[weaponID], MAXBPAMMO[weaponID]);
	
	// Primary bought
	flag_unset(gCanBuyPrimary, id);
}

// Buy Menu Secondary
@Menu_BuySecondary(id, key)
{
	// Player dead or zombie or already bought secondary
	if (!is_user_alive(id) || zp_core_is_zombie(id) || !flag_get(gCanBuySecondary, id))
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= ArraySize(gSecondaryItems)) {
		// Toggle autoselect
		if (key == MENU_KEY_AUTOSELECT)
			WPN_AUTO_ON = 1 - WPN_AUTO_ON;
		
		// Reshow menu unless user exited
		if (key != MENU_KEY_EXIT)
			showMenuBuySecondary(id);
		
		return PLUGIN_HANDLED;
	}
	
	// Store selected weapon id
	WPN_AUTO_SEC = key;
	
	// Buy secondary weapon
	buySecondaryWeapon(id, key);
	
	// Show next buy menu
	showAvailableBuyMenus(id);
	
	return PLUGIN_HANDLED;
}

// Buy Secondary Weapon
buySecondaryWeapon(id, selection)
{
	// Drop previous secondary weapon
	drop_weapons(id, SECONDARY_ONLY);
	
	// Get weapon's id
	static weaponName[32];
	ArrayGetString(gSecondaryItems, selection, weaponName, charsmax(weaponName));
	new weaponID = get_weaponid(weaponName);
	
	// Give the new weapon and full ammo
	give_item(id, weaponName);
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponID], AMMOTYPE[weaponID], MAXBPAMMO[weaponID]);
	
	// Secondary bought
	flag_unset(gCanBuySecondary, id);
}

// Buy Menu Grenades
@Menu_BuyGrenades(id, key)
{
	// Player dead or zombie or already bought grenades
	if (!is_user_alive(id) || zp_core_is_zombie(id) || !flag_get(gCanBuyGrenades, id))
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= ArraySize(gGrenadesItems)) {
		// Toggle autoselect
		if (key == MENU_KEY_AUTOSELECT)
			WPN_AUTO_ON = 1 - WPN_AUTO_ON;
		
		// Reshow menu unless user exited
		if (key != MENU_KEY_EXIT)
			showMenuBuyGrenades(id);
		
		return PLUGIN_HANDLED;
	}
	
	// Store selected grenade
	WPN_AUTO_GREN = key;
	
	// Buy selected grenade
	buyGrenades(id, key);
	
	return PLUGIN_HANDLED;
}

// Buy Grenades
buyGrenades(id, selection)
{
	// Give the new weapon
	static weaponName[32];
	ArrayGetString(gGrenadesItems, selection, weaponName, charsmax(weaponName));
	give_item(id, weaponName);
	
	// Grenades bought
	flag_unset(gCanBuyGrenades, id);
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	new weapons[32], weaponCount, i, x, weaponID, weaponID2, dropAmmo = true;
	get_user_weapons(id, weapons, weaponCount);
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < weaponCount; ++i) {
		// Prevent re-indexing the array
		weaponID = weapons[i];
		
		if ((dropwhat == PRIMARY_ONLY && ((1 << weaponID) & PRIMARY_WEAPONS_BIT_SUM))
		|| (dropwhat == SECONDARY_ONLY && ((1 << weaponID) & CSW_ALL_PISTOLS))) {
			// Get weapon entity
			new weaponName[32], weaponEnt;
			get_weaponname(weaponID, weaponName, charsmax(weaponName));
			weaponEnt = fm_find_ent_by_owner(-1, weaponName, id);
			
			// Check if another weapon uses same type of ammo first
			for (x = 0; x < weaponCount; ++x) {
				// Prevent re-indexing the array
				weaponID2 = weapons[x];
				
				// Only check weapons that we are not going to drop
				if ((dropwhat == PRIMARY_ONLY && ((1 << weaponID2) & CSW_ALL_PISTOLS))
				|| (dropwhat == SECONDARY_ONLY && ((1 << weaponID2) & PRIMARY_WEAPONS_BIT_SUM))) {
					if (AMMOID[weaponID2] == AMMOID[weaponID])
						dropAmmo = false;
				}
			}
			
			// Drop weapon's BP Ammo too?
			if (dropAmmo) {
				// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
				set_pev(weaponEnt, PEV_ADDITIONAL_AMMO, cs_get_user_bpammo(id, weaponID));
				cs_set_user_bpammo(id, weaponID, 0);
			}
			
			// Player drops the weapon
			engclient_cmd(id, "drop", weaponName);
		}
	}
}

// Strip primary/secondary/grenades
stock strip_weapons(id, stripwhat)
{
	// Get user weapons
	new weapons[32], weaponCount, i, weaponID;
	get_user_weapons(id, weapons, weaponCount);
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < weaponCount; ++i) {
		// Prevent re-indexing the array
		weaponID = weapons[i];
		
		if ((stripwhat == PRIMARY_ONLY && ((1 << weaponID) & PRIMARY_WEAPONS_BIT_SUM))
		|| (stripwhat == SECONDARY_ONLY && ((1 << weaponID) & CSW_ALL_PISTOLS))
		|| (stripwhat == GRENADES_ONLY && ((1 << weaponID) & CSW_ALL_GRENADES))) {
			// Get weapon name
			new weaponName[32];
			get_weaponname(weaponID, weaponName, charsmax(weaponName));
			
			// Strip weapon and remove bpammo
			ham_strip_weapon(id, weaponName);
			cs_set_user_bpammo(id, weaponID, 0);
		}
	}
}

stock ham_strip_weapon(index, const weapon[])
{
	// Get weapon id
	new weaponID = get_weaponid(weapon);
	if (!weaponID)
		return false;
	
	// Get weapon entity
	new weaponEnt = fm_find_ent_by_owner(-1, weapon, index);
	if (!weaponEnt)
		return false;
	
	// If it's the current weapon, retire first
	new currentWeaponEnt = cs_get_user_weapon_entity(index);
	new currentWeapon = pev_valid(currentWeaponEnt) ? cs_get_weapon_id(currentWeaponEnt) : -1;
	if (currentWeapon == weaponID)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weaponEnt);
	
	// Remove weapon from player
	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weaponEnt))
		return false;
	
	// Kill weapon entity and fix pev_weapons bitsum
	ExecuteHamB(Ham_Item_Kill, weaponEnt);
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1 << weaponID));
	return true;
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}
