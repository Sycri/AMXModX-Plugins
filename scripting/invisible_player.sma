/*=================================================================================
						Invisible Player
					by Sycri (Kristaps08)

	Description:
		With this plugin you can make a player invisible

	Cvars:
		amx_invisible_amount "20" // Alpha level of an invisible player (0-255)

	Admin Commands:
		amx_invisible_player <target> [0|1] - 0=OFF 1=ON

	Credits:
		None

	Changelog:
		- v1.0
		* First release

		- v1.1
		* First public release
		* Code cleanup
		* Command amx_invisible is changed to command amx_give_invisibility and command amx_remove_invisibility
		* Added hamsandwich module
		* Command amx_invisible is working again

		- v1.2
		* Changed from (g_is_invisible[player]==false) to (!g_is_invisible[player])
		
		- v1.3
		* Changed engine module to fun module
		* Added command amx_check_invisibility to check if the player is invisible
		* Added cvar to control how much will be invisible
		* Changed from set_entity_visibility to set_user_rendering
		* Commands amx_give_invisibility and command amx_remove_invisibility is changed to command amx_invisible
		* Cleaned up some code

		- v1.4
		* Code changes and cleanup
		* Added support for amx_show_activity
		* Changed from hamsandwich to fakemeta

		- v1.5
		* Optimized code

		- v1.6
		* Removed fun module
		* Optimized a little bit the code
		* Added description

		- v1.7
		* Optimized code a tiny little bit

		- v1.8 (26th September 2012)
		* Addded a new translation
		* Changed a tiny little bit of code

		- v1.9 (10th August 2020)
		* Added multilingual support to the description of the command amx_invisible
		* Added FCVAR_SPONLY to cvar amx_invisible_version to make it unchangeable
		* Changed from fakemeta to fun because the functions of the latter are native
		* Changed from get_pcvar_num to bind_pcvar_num so variables could be used directly
		* Changed the required admin level of the command amx_invisible from ADMIN_MAP to ADMIN_LEVEL_A
		* Forced usage of semicolons for better clarity
		* Replaced amx_show_activity checking with show_activity_key
		* Replaced FM_PlayerPreThink with Ham_Spawn since the former gets called too frequently
		* Replaced read_argv with read_argv_int where appropriate
		* Replaced register_cvar with create_cvar
		* Revamped the entire plugin for better code style

=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.9";

new const InvisibleCommand[] = "amx_invisible";

new CvarInvisibleAmount;

new bool:gIsInvisible[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Invisible Player", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("invisible_player.txt");
	
	register_concmd(InvisibleCommand, "@ConsoleCommand_Invisible", ADMIN_LEVEL_A, "INVISIBLE_CMD_INFO", .info_ml = true);

	RegisterHamPlayer(Ham_Spawn, "@Forward_PlayerSpawn_Post", 1);

	bind_pcvar_num(create_cvar("amx_invisible_amount", "20", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0), CvarInvisibleAmount);

	create_cvar("amx_invisible_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
}

public client_disconnected(id)
{
	gIsInvisible[id] = false;
}

@ConsoleCommand_Invisible(id, level, cid)
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
		if (!gIsInvisible[player]) {
			show_activity_key("ADMIN_INVISIBLE_ON_1", "ADMIN_INVISIBLE_ON_2", admin, name);
			gIsInvisible[player] = true;

			set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, CvarInvisibleAmount);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS");
		}
	} else {
		if (gIsInvisible[player]) {
			show_activity_key("ADMIN_INVISIBLE_OFF_1", "ADMIN_INVISIBLE_OFF_2", admin, name);
			gIsInvisible[player] = false;

			set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS_NOT");
		}
	}
	return PLUGIN_HANDLED;
}

@Forward_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || get_user_team(id) == 0)
		return HAM_IGNORED;

	if (!gIsInvisible[id])
		return HAM_IGNORED;
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, CvarInvisibleAmount);
	return HAM_IGNORED;
}
