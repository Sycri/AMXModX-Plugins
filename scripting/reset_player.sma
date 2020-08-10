/*=================================================================================
						Reset Player
					by Sycri (Kristaps08)

	Description:
		With this plugin you can reset players items, money, health, armor, deaths, and/or frags.

	Cvars:
		None.

	Admin Commands:
		amx_reset_player <target> <money> <weapons> <health> <armor> <frags> <deaths> - Reset player's stats

	Credits:
		ConnorMcLeod: For his suggestions.

	Changelog:
		- v1.0
		* First public release.

		- v1.1
		* Added reset_player_frags to reset frags for player.
		* Added reset_player_deaths to reset deaths for player.
		* Added reset_player_again to reset again the player in the same round.

		- v1.2
		* Changed from set_user_armor to cs_set_user_armor
		* Changed from give_item to cs_set_user_bpammo

		- v1.3
		* Code changes and cleanup.
		* Changed cvars from reset_player_ to rp_

		- v1.4
		* Added support for amx_show_activity.
		* Changed and cleaned up some code.

		- v1.5
		* Optimized code.
		* Added get_cvar_pointer.

		- v1.6
		* Added description.
		* Optimized a little bit of the code.

		- v1.7
		* Removed rp_again so admins could reset player all the time.
		* Optimized code again.

		- v1.8 (8th May 2013)
		* Added pev_max_health.
		* Removed all the cvars except rp_version.
		* Changed the command amx_reset_player so the player could reset different parts of the player's stats.

		- v1.9 (10th August 2020)
		* Added multilingual support to the description of the command amx_reset_player
		* Added FCVAR_SPONLY to cvar rp_version to make it unchangeable.
		* Changed the required admin level of the command amx_reset_player from ADMIN_BAN to ADMIN_SLAY
		* Fixed the command amx_reset_player only checking the first toggle.
		* Forced usage of semicolons for better clarity.
		* Replaced amx_show_activity checking with show_activity_key
		* Replaced read_argv with read_argv_int where appropriate.
		* Replaced register_cvar with create_cvar
		* Revamped the entire plugin for better code style.

=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.9";

new const ResetPlayerCommand[] = "amx_reset_player";

new CvarStartmoney;

public plugin_init()
{
	register_plugin("Reset Player", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("reset_player.txt");
	
	register_concmd(ResetPlayerCommand, "@ConsoleCommand_ResetPlayer", ADMIN_SLAY, "RESET_PLAYER_CMD_INFO", .info_ml = true);
	
	create_cvar("rp_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
}

public OnConfigsExecuted()
{
	bind_pcvar_num(get_cvar_pointer("mp_startmoney"), CvarStartmoney);
}

@ConsoleCommand_ResetPlayer(id, level, cid)
{
	if (!cmd_access(id, level, cid, 7))
		return PLUGIN_HANDLED;
	
	new arg[32];
	read_argv(1, arg, charsmax(arg));
	
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
	if (!player) 
		return PLUGIN_HANDLED;
	
	new name[32], admin[32];
	get_user_name(player, name, charsmax(name));
	get_user_name(id, admin, charsmax(admin));

	show_activity_key("ADMIN_RESET_PLAYER_1", "ADMIN_RESET_PLAYER_2", admin, name);
	
	if (read_argv_int(2) == 1) // Money
		cs_set_user_money(player, CvarStartmoney);
	
	if (is_user_alive(player)) {
		if (read_argv_int(3) == 1) { // Weapons
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
	
		if (read_argv_int(4) == 1) // Health
			set_user_health(player, pev(player, pev_max_health));
	
		if (read_argv_int(5) == 1) // Armor
			cs_set_user_armor(player, 0, CS_ARMOR_NONE);
	}
	
	if (read_argv_int(6) == 1) // Frags
		set_user_frags(player, 0);
	
	if (read_argv_int(7) == 1) // Deaths
		cs_set_user_deaths(player, 0);
	return PLUGIN_HANDLED;
}
