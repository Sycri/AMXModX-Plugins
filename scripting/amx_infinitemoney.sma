/* AMX Mod X script.
*
*   AMX Infinite Money (amx_infinitemoney.sma)
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
*		An admin can make a player have infinite money
*
*	CVARs:
*		None
*
*	Admin Commands:
*		amx_infinitemoney <target> [0|1] - 0=OFF 1=ON
*
*	Credits:
*		None
*
*	Changelog:
*	v1.3 - Sycri - 08/20/2020
*	 - Added multilingual support to the description of the command amx_infinitemoney
*	 - Added FCVAR_SPONLY to cvar amx_infinitemoney_version to make it unchangeable
*	 - Changed from fakemeta to cstrike because the functions of the latter are native
*	 - Changed the required admin level of the command amx_infinitemoney from ADMIN_MAP to ADMIN_LEVEL_A
*	 - Forced usage of semicolons for better clarity
*	 - Replaced amx_show_activity checking with show_activity_key
*	 - Replaced FM_PlayerPreThink with Money event since the former gets called too frequently
*	 - Replaced read_argv with read_argv_int where appropriate
*	 - Replaced register_cvar with create_cvar
*	 - Replaced register_event with register_event_ex for better code readability
*	 - Revamped the entire plugin for better code style
*
*	v1.2 - Kristaps08 (Sycri) - 08/29/2012
*	 - Added description
*	 - Optimized the code a little bit
*	 - First public release
*
*	v1.1 - Kristaps08 (Sycri)
*	 - Added support to give infinite money while the target is dead
*	 - Changed and cleaned up some code
*
*	v1.0 - Kristaps08 (Sycri)
*	 - First release
*
****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.3";

new const InfiniteMoneyCommand[] = "amx_infinitemoney";

new bool:gHasInfiniteMoney[MAX_PLAYERS + 1];

new CvarStartMoney;

public plugin_init()
{
	register_plugin("AMX Infinite Money", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("amx_infinitemoney.txt");
	
	register_concmd(InfiniteMoneyCommand, "@ConsoleCommand_InfiniteMoney", ADMIN_LEVEL_A, "INFINITE_MONEY_CMD_INFO", .info_ml = true);

	register_event_ex("Money", "@Event_Money", RegisterEvent_Single, "1!99999");

	bind_pcvar_num(get_cvar_pointer("mp_startmoney"), CvarStartMoney);

	create_cvar("amx_infinitemoney_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
}

public client_disconnected(id)
{
	gHasInfiniteMoney[id] = false;
}

@ConsoleCommand_InfiniteMoney(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[32];
	read_argv(1, arg, charsmax(arg));
	
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
	if (!player) 
		return PLUGIN_HANDLED;
	
	new name[32];
	new admin[32];
	get_user_name(player, name, charsmax(name));
	get_user_name(id, admin, charsmax(admin));
	
	if (read_argv_int(2) == 1) {
		if (!gHasInfiniteMoney[player]) {
			show_activity_key("ADMIN_INFINITE_MONEY_ON_1", "ADMIN_INFINITE_MONEY_ON_2", admin, name);

			gHasInfiniteMoney[player] = true;
			cs_set_user_money(id, 99999, 0);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS");
		}
	} else {
		if (gHasInfiniteMoney[player]) {
			show_activity_key("ADMIN_INFINITE_MONEY_OFF_1", "ADMIN_INFINITE_MONEY_OFF_2", admin, name);

			gHasInfiniteMoney[player] = false;
			cs_set_user_money(player, CvarStartMoney, 0);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS_NOT");
		}
	}
	return PLUGIN_HANDLED;
}

@Event_Money(id)
{
	if (!gHasInfiniteMoney[id])
		return PLUGIN_HANDLED;

	cs_set_user_money(id, 99999, 0);
	return PLUGIN_HANDLED;
}
