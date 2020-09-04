/* AMX Mod X script.
*
*   Reset Player (reset_player.sma)
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
*		An admin can reset players' money, weapons, health, armor, deaths, and/or frags
*
*	CVARs:
*		None
*
*	Admin Commands:
*		amx_reset_player <target> <flags> - Reset stats
*		a - money
*		b - weapons
*		c - health
*		d - armor
*		e - frags
*		f - deaths
*
*	Credits:
*		- ConnorMcLeod: For his suggestions
*
*	Changelog:
*	v1.9 - Sycri - 09/04/20
*	 - Added multilingual support to the description of the command amx_reset_player
*	 - Added FCVAR_SPONLY to cvar rp_version to make it unchangeable
*	 - Changed the required admin level of the command amx_reset_player from ADMIN_BAN to ADMIN_SLAY
*	 - Changed to use a flag-based system for checking what to reset
*	 - Fixed frags not updating immediately on the scoreboard if deaths are also not reset
*	 - Fixed the command amx_reset_player only checking the first toggle
*	 - Forced usage of semicolons for better clarity
*	 - Replaced amx_show_activity checking with show_activity_key
*	 - Replaced read_argv with read_argv_int where appropriate
*	 - Replaced register_cvar with create_cvar
*	 - Revamped the entire plugin for better code style
*
*	v1.8 - Kristaps08 (Sycri) - 05/08/13
*	 - Added pev_max_health
*	 - Removed all the cvars except rp_version
*	 - Changed the command amx_reset_player so the player could reset different parts of the player's stats
*
*	v1.7 - Kristaps08 (Sycri) - 08/29/12
*	 - Removed rp_again so admins could reset player all the time
*	 - Optimized code again
*
*	v1.6 - Kristaps08 (Sycri) - 08/28/12
*	 - Added description
*	 - Optimized a little bit of the code
*
*	v1.5 - Kristaps08 (Sycri) - 08/24/12
*	 - Optimized code
*	 - Added get_cvar_pointer
*
*	v1.4 - Kristaps08 (Sycri) - 05/16/12
*	 - Added support for amx_show_activity
*	 - Changed and cleaned up some code
*
*	v1.3 - Kristaps08 (Sycri) - 05/16/12
*	 - Code changes and cleanup
*	 - Changed cvars from reset_player_ to rp_
*
*	v1.2 - Kristaps08 (Sycri) - 05/16/12
*	 - Changed from set_user_armor to cs_set_user_armor
*	 - Changed from give_item to cs_set_user_bpammo
*
*	v1.1 - Kristaps08 (Sycri) - 05/16/12
*	 - Added reset_player_frags to reset frags for player
*	 - Added reset_player_deaths to reset deaths for player
*	 - Added reset_player_again to reset again the player in the same round
*
*	v1.0 - Kristaps08 (Sycri) - 05/16/12
*	 - First public release
*
****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.9";

new const ResetPlayerCommand[] = "amx_reset_player";

new gmsgScoreInfo;

new CvarStartMoney;

public plugin_init()
{
	register_plugin("Reset Player", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("reset_player.txt");
	
	register_concmd(ResetPlayerCommand, "@ConsoleCommand_ResetPlayer", ADMIN_SLAY, "RESET_PLAYER_CMD_INFO", .info_ml = true);

	gmsgScoreInfo = get_user_msgid("ScoreInfo");

	bind_pcvar_num(get_cvar_pointer("mp_startmoney"), CvarStartMoney);
	
	create_cvar("rp_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
}

@ConsoleCommand_ResetPlayer(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	
	new arg1[32];
	read_argv(1, arg1, charsmax(arg1));
	
	new player = cmd_target(id, arg1, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
	if (!player)
		return PLUGIN_HANDLED;

	new arg2[7];
	read_argv(2, arg2, charsmax(arg2));
	new flags = read_flags(arg2);
	
	if (flags & 1) // Money
		cs_set_user_money(player, CvarStartMoney);
	
	if (is_user_alive(player)) {
		if (flags & 2) { // Weapons
			strip_user_weapons(player);
			give_item(player, "weapon_knife");

			switch (cs_get_user_team(player)) {
				case CS_TEAM_T: {
					give_item(player, "weapon_glock18");
					cs_set_user_bpammo(player, CSW_GLOCK18, 40);
				}
				case CS_TEAM_CT: {
					give_item(player, "weapon_usp");
					cs_set_user_bpammo(player, CSW_USP, 24);
				}
			}
		}
	
		if (flags & 4) // Health
			set_user_health(player, pev(player, pev_max_health));
	
		if (flags & 8) // Armor
			cs_set_user_armor(player, 0, CS_ARMOR_NONE);
	}
	
	if (flags & 16) { // Frags
		set_user_frags(player, 0);

		if (!(flags & 32)) { // Update scoreboard only if deaths are not reset
			emessage_begin(MSG_BROADCAST, gmsgScoreInfo);
			ewrite_byte(player); // id
			ewrite_short(0); // frags
			ewrite_short(cs_get_user_deaths(player)); // deaths
			ewrite_short(0); // class?
			ewrite_short(_:cs_get_user_team(player)); // team
			emessage_end();
		}
	}
	
	if (flags & 32) // Deaths
		cs_set_user_deaths(player, 0);

	new name[32], admin[32];
	get_user_name(player, name, charsmax(name));
	get_user_name(id, admin, charsmax(admin));
	show_activity_key("ADMIN_RESET_PLAYER_1", "ADMIN_RESET_PLAYER_2", admin, name);
	return PLUGIN_HANDLED;
}
