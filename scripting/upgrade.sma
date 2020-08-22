/*=================================================================================
						Upgrade
					by Sycri (Kristaps08)

	Description:
		With this plugin you can make a player have infinite money

	Cvars:
		upgrade_speed "300.0"	// The player's speed with an upgrade
		upgrade_hp "150"		// The player's health with an upgrade
		upgrade_ap "150"		// The player's armor with an upgrade
		upgrade_gravity "0.75"	// The player's gravity with an upgrade
		upgrade_cost "4000"		// The cost of an upgrade

	Admin Commands:
		amx_upgrade <target> [0|1] - 0=TAKE 1=GIVE

	Credits:
		None

	Changelog:
		- v1.0
		* First public release

		- v1.1
		* Removed client_connect()
		* Changed from CurWeapon event to Ham_Item_PreFrame
		* Code changes and cleanup

		- v1.2
		* Removed cmd_upgradehelp() because it was not needed
		* Added automatic message that will display after some time
		* Combined amx_give_upgrade and amx_take_upgrade commands together into amx_upgrade
		* Added support for amx_show_activity

		- v1.3
		* Changed and cleaned up some code
		* Added fakemeta

		- v1.4
		* Optimized code

		- v1.5
		* Fixed freezetime bug
		* Optimized a little bit of the code
		* Added description

		- v1.6 (29th August 2012)
		* Optimized the code a little bit again

		- v1.7 (21th August 2020)
		* Added multilingual support to the description of the command amx_upgrade
		* Added FCVAR_SPONLY to cvar upgrade_version to make it unchangeable
		* Added Ham_AddPlayerItem since Ham_CS_Item_GetMaxSpeed does not catch weapon pickups or purchases
		* Changed from fakemeta to fun because the functions of the latter are native
		* Changed from get_pcvar_num to bind_pcvar_num so variables could be used directly
		* Changed the required admin level of the command amx_upgrade from ADMIN_SLAY to ADMIN_LEVEL_A
		* Forced usage of semicolons for better clarity
		* Replaced amx_show_activity checking with show_activity_key
		* Replaced FM_PlayerPreThink with Ham_CS_Item_GetMaxSpeed since the former gets called too frequently
		* Replaced RegisterHam with RegisterHamPlayer to add special bot support
		* Replaced read_argv with read_argv_int where appropriate
		* Replaced register_cvar with create_cvar
		* Replaced register_event with register_event_ex for better code readability
		* Revamped the entire plugin for better code style

=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.7";

new const UpgradeCommand[] = "amx_upgrade";

new CvarCost;
new CvarHealth, CvarArmor;
new Float:CvarGravity, Float:CvarSpeed;

new bool:gHasUpgrade[MAX_PLAYERS + 1];
new bool:gIsFreezetime;

new Float:gWeaponSpeed[] = {
	0.0,
	250.0,	// CSW_P228
	0.0,
	260.0,	// CSW_SCOUT
	250.0,	// CSW_HEGRENADE
	240.0,	// CSW_XM1014
	250.0,	// CSW_C4
	250.0,	// CSW_MAC10
	240.0,	// CSW_AUG
	250.0,	// CSW_SMOKEGRENADE
	250.0,	// CSW_ELITE
	250.0,	// CSW_FIVESEVEN
	250.0,	// CSW_UMP45
	210.0,	// CSW_SG550
	240.0,	// CSW_GALI
	240.0,	// CSW_FAMAS
	250.0,	// CSW_USP
	250.0,	// CSW_GLOCK18
	210.0,	// CSW_AWP
	250.0,	// CSW_MP5NAVY
	220.0,	// CSW_M249
	230.0,	// CSW_M3
	230.0,	// CSW_M4A1
	250.0,	// CSW_TMP
	210.0,	// CSW_G3SG1
	250.0,	// CSW_FLASHBANG
	250.0,	// CSW_DEAGLE
	235.0,	// CSW_SG552
	221.0,	// CSW_AK47
	250.0,	// CSW_KNIFE
	245.0	// CSW_P90
};

public plugin_init()
{
	register_plugin("Upgrade", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("upgrade.txt");
	
	register_clcmd("say /upgrade", "@ClientCommand_BuyUpgrade");
	register_clcmd("say_team /upgrade", "@ClientCommand_BuyUpgrade");
	
	register_concmd(UpgradeCommand, "@ConsoleCommand_Upgrade", ADMIN_LEVEL_A, "UPGRADE_CMD_INFO", .info_ml = true);
	
	RegisterHamPlayer(Ham_Killed, "@Forward_PlayerKilled_Post", 1);
	RegisterHamPlayer(Ham_Spawn, "@Forward_PlayerSpawn_Post", 1);
	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);

	new weaponName[32];
	for (new id = CSW_P228; id <= CSW_P90; id++) {
		if (get_weaponname(id, weaponName, charsmax(weaponName)))
			RegisterHam(Ham_CS_Item_GetMaxSpeed, weaponName, "@Forward_CS_Item_GetMaxSpeed_Pre", 0);
	}

	register_event_ex("HLTV", "@Event_NewRound", RegisterEvent_Global, "1=0", "2=0");
	register_logevent("@LogEvent_RoundStart", 2, "1=Round_Start");
	
	bind_pcvar_num(create_cvar("upgrade_cost", "4000", .has_min = true, .min_val = 0.0), CvarCost);
	bind_pcvar_num(create_cvar("upgrade_hp", "150", .has_min = true, .min_val = 1.0), CvarHealth);
	bind_pcvar_num(create_cvar("upgrade_ap", "150", .has_min = true, .min_val = 0.0), CvarArmor);
	bind_pcvar_float(create_cvar("upgrade_gravity", "0.75", .has_min = true, .min_val = 0.0), CvarGravity);
	bind_pcvar_float(create_cvar("upgrade_speed", "300.0", .has_min = true, .min_val = 0.0), CvarSpeed);
	
	create_cvar("upgrade_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
}

public client_disconnected(id)
{
	gHasUpgrade[id] = false;
}

@ClientCommand_BuyUpgrade(id)
{
	if (!is_user_alive(id)) {
		client_print(id, print_chat, "%l", "NOT_ALIVE");
		return PLUGIN_HANDLED;
	}
	
	if (gHasUpgrade[id]) {
		client_print(id, print_chat, "%l", "ALREADY_IS");
		return PLUGIN_HANDLED;
	}
	
	if (cs_get_user_money(id) < CvarCost) {
		client_print(id, print_chat, "%l", "NOT_ENOUGH", CvarCost);
		return PLUGIN_HANDLED;
	}
	
	cs_set_user_money(id, cs_get_user_money(id) - CvarCost);
	gHasUpgrade[id] = true;
	client_print(id, print_chat, "%l", "GAIN_UPGRADE");

	upgradePlayer(id);
	return PLUGIN_HANDLED;
}

@ConsoleCommand_Upgrade(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[32];
	read_argv(1, arg, charsmax(arg));
	
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	if (!player) 
		return PLUGIN_HANDLED;
	
	new name[32];
	new admin[32];
	get_user_name(player, name, charsmax(name));
	get_user_name(id, admin, charsmax(admin));
	
	if (read_argv_int(2) == 1) {
		if (!gHasUpgrade[player]) {
			show_activity_key("ADMIN_GIVE_UPGRADE_1", "ADMIN_GIVE_UPGRADE_2", admin, name);
			gHasUpgrade[player] = true;
			client_print(player, print_chat, "%l", "GAIN_UPGRADE");

			upgradePlayer(player);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS");
		}
	} else {
		if (gHasUpgrade[player]) {
			show_activity_key("ADMIN_TOOK_UPGRADE_1", "ADMIN_TOOK_UPGRADE_2", admin, name);
			gHasUpgrade[player] = false;
			client_print(player, print_chat, "%l", "LOST_UPGRADE");

			deupgradePlayer(player);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS_NOT");
		}
	}
	return PLUGIN_HANDLED;
}

@Forward_PlayerKilled_Post(id)
{
	if (!gHasUpgrade[id])
		return HAM_IGNORED;
	
	client_print(id, print_chat, "%l", "LOST_UPGRADE");
	gHasUpgrade[id] = false;
	return HAM_IGNORED;
}

@Forward_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
		return HAM_IGNORED;

	if (!gHasUpgrade[id])
		return HAM_IGNORED;
	
	upgradePlayer(id);
	return HAM_IGNORED;
}

@Forward_AddPlayerItem_Post(id)
{
	if (!is_user_alive(id) || !gHasUpgrade[id])
		return HAM_IGNORED;

	if (gIsFreezetime || cs_get_user_zoom(id) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	set_user_maxspeed(id, CvarSpeed);
	return HAM_IGNORED;
}

@Forward_CS_Item_GetMaxSpeed_Pre(weapon)
{
	static owner;
	owner = pev(weapon, pev_owner);

	if (!is_user_alive(owner) || !gHasUpgrade[owner])
		return HAM_IGNORED;

	if (cs_get_user_zoom(owner) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	SetHamReturnFloat(CvarSpeed);
	return HAM_SUPERCEDE;
}

@Event_NewRound()
{
	gIsFreezetime = true;
}

@LogEvent_RoundStart()
{
	gIsFreezetime = false;
}

upgradePlayer(index)
{
	set_user_health(index, CvarHealth);
	cs_set_user_armor(index, CvarArmor, CS_ARMOR_VESTHELM);
	set_user_gravity(index, CvarGravity);

	if (!gIsFreezetime)
		set_user_maxspeed(index, CvarSpeed);
}

deupgradePlayer(index)
{
	if (get_user_health(index) > 100)
		set_user_health(index, 100);
	
	if (get_user_armor(index) > 100)
		set_user_armor(index, 100);

	set_user_gravity(index, 1.0);
	cs_reset_user_maxspeed(index);
}

cs_reset_user_maxspeed(index)
{
	new Float:maxSpeed;
	new weaponID = cs_get_user_weapon(index);
	
	if (cs_get_user_vip(index)) {
		maxSpeed = 227.0;
	} else if (cs_get_user_zoom(index) == CS_SET_NO_ZOOM) {
		maxSpeed = gWeaponSpeed[weaponID];
	} else {
		switch (weaponID) {
			case CSW_SCOUT: maxSpeed = 220.0;
			case CSW_SG550, CSW_AWP, CSW_G3SG1: maxSpeed = 150.0;
		}
	}
    
	set_user_maxspeed(index, maxSpeed);
}
