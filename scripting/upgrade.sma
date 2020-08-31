/* AMX Mod X script.
*
*   Upgrade (upgrade.sma)
*   Copyright (C) 2020 Sycri (Kristaps08)
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
*   In addition, as a special exception, the author gives permission to
*   link the code of this program with the Half-Life Game Engine ("HL
*   Engine") and Modified Game Libraries ("MODs") developed by Valve,
*   L.L.C ("Valve"). You must obey the GNU General Public License in all
*   respects for all of the code used other than the HL Engine and MODs
*   from Valve. If you modify this file, you may extend this exception
*   to your version of the file, but you are not obligated to do so. If
*   you do not wish to do so, delete this exception statement from your
*   version.
*
****************************************************************************
*
*				******** AMX Mod X 1.90 and above Only ********
*
*	Description:
*		The upgrade can be purchased or granted by an admin to gain additional health and armor, increased speed, and lowered gravity
*
*	CVARs:
*		upgrade_speed "300.0"	// The player's speed with an upgrade
*		upgrade_hp "150"		// The player's health with an upgrade
*		upgrade_ap "150"		// The player's armor with an upgrade
*		upgrade_gravity "0.75"	// The player's gravity with an upgrade
*		upgrade_cost "4000"		// The cost of an upgrade
*
*	Admin Commands:
*		amx_upgrade <target> [0|1] - 0=TAKE 1=GIVE
*
*	Credits:
*		None
*
*	Changelog:
*	v1.7 - Sycri - 08/31/2020
*	 - Added multilingual support to the description of the command amx_upgrade
*	 - Added FCVAR_SPONLY to cvar upgrade_version to make it unchangeable
*	 - Added Ham_AddPlayerItem since Ham_Player_ResetMaxSpeed does not catch weapon pickups or purchases
*	 - Changed from fakemeta to fun because the functions of the latter are native
*	 - Changed from get_pcvar_num to bind_pcvar_num so variables could be used directly
*	 - Changed the required admin level of the command amx_upgrade from ADMIN_SLAY to ADMIN_LEVEL_A
*	 - Forced usage of semicolons for better clarity
*	 - Replaced amx_show_activity checking with show_activity_key
*	 - Replaced FM_PlayerPreThink with Ham_Player_ResetMaxSpeed since the former gets called too frequently
*	 - Replaced RegisterHam with RegisterHamPlayer to add special bot support
*	 - Replaced read_argv with read_argv_int where appropriate
*	 - Replaced register_cvar with create_cvar
*	 - Replaced register_event with register_event_ex for better code readability
*	 - Revamped the entire plugin for better code style
*
*	v1.6 - Kristaps08 (Sycri) - 08/29/12
*	 - Optimized the code a little bit again
*
*	v1.5 - Kristaps08 (Sycri)
*	 - Fixed freezetime bug
*	 - Optimized a little bit of the code
*	 - Added description
*
*	v1.4 - Kristaps08 (Sycri)
*	 - Optimized code
*
*	v1.3 - Kristaps08 (Sycri)
*	 - Changed and cleaned up some code
*	 - Added fakemeta
*
*	v1.2 - Kristaps08 (Sycri)
*	 - Removed cmd_upgradehelp() because it was not needed
*	 - Added automatic message that will display after some time
*	 - Combined amx_give_upgrade and amx_take_upgrade commands together into amx_upgrade
*	 - Added support for amx_show_activity
*
*	v1.1 - Kristaps08 (Sycri)
*	 - Removed client_connect()
*	 - Changed from CurWeapon event to Ham_Item_PreFrame
*	 - Code changes and cleanup
*
*	v1.0 - Kristaps08 (Sycri) - 05/15/12
*	 - First public release
*
****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <hamsandwich>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.7";

new const UpgradeCommand[] = "amx_upgrade";

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

new bool:gHasUpgrade[MAX_PLAYERS + 1];
new bool:gIsFreezetime;

new CvarCost;
new CvarHealth, CvarArmor;
new Float:CvarGravity, Float:CvarSpeed;

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
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);

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
	if (!gHasUpgrade[id] || !is_user_alive(id))
		return HAM_IGNORED;

	if (gIsFreezetime || cs_get_user_zoom(id) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	set_user_maxspeed(id, CvarSpeed);
	return HAM_IGNORED;
}

@Forward_Player_ResetMaxSpeed_Post(id)
{
	if (!gHasUpgrade[id] || !is_user_alive(id))
		return HAM_IGNORED;

	if (gIsFreezetime || cs_get_user_zoom(id) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	set_user_maxspeed(id, CvarSpeed);
	return HAM_IGNORED;
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
	ExecuteHamB(Ham_Player_ResetMaxSpeed, index);
}
