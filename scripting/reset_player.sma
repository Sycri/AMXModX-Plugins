/*=================================================================================
						Reset Player
					by Sycri

	Description:
		With this plugin you can reset players items/money/health/armor/deaths and frags.

	Cvars:
		None.

	Admin Commands:
		amx_reset_player <target> <reset money> <reset weapons> <reset health> <reset armor> <reset frags> <reset deaths>

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

		- v1.8 (8 May 2013)
		* Added pev_max_health.
		* Removed all the cvars except rp_version.
		* Changed the command amx_reset_player so the player could reset different parts of the player's stats.

=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>

new const PLUGIN_VERSION[] = "1.8"

const REQUIRED_FLAG = ADMIN_BAN

new pointer_startmoney, pointer_showactivity

public plugin_init() {
	register_plugin("Reset Player", PLUGIN_VERSION, "Sycri (Kristaps08)")
	
	register_dictionary("reset_player.txt")
	
	register_concmd("amx_reset_player", "cmd_reset_player", REQUIRED_FLAG, "<target> <reset money> <reset weapons> <reset health> <reset armor> <reset frags> <reset deaths>")
	
	register_cvar("rp_version", PLUGIN_VERSION, FCVAR_SERVER)
}

public plugin_cfg() {
	pointer_startmoney = get_cvar_pointer("mp_startmoney")
	pointer_showactivity = get_cvar_pointer("amx_show_activity")
}

public cmd_reset_player(id, level, cid) {
	if(!cmd_access(id, level, cid, 7))
		return PLUGIN_HANDLED
	
	new arg[32]
	read_argv(1, arg, 31)
	
	new player = cmd_target(id, arg, 7)
	if(!player) 
		return PLUGIN_HANDLED
	
	new name[32]
	new admin[32]
	get_user_name(player, name, 31)
	get_user_name(id, admin, 31)
	
	switch(get_pcvar_num(pointer_showactivity)) {
		case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_RESETED_PLAYER_CASE1", name)
		case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_RESETED_PLAYER_CASE2", admin, name)
	}
	
	new arg2[2]
	read_argv(2, arg2, 1)
	
	if(equal(arg2, "1")) {
		cs_set_user_money(player, get_pcvar_num(pointer_startmoney))
	}
	
	new arg3[2]
	read_argv(2, arg3, 1)
	
	if(equal(arg3, "1")) {
		strip_user_weapons(player)
		give_item(player, "weapon_knife")
		new team = get_user_team(player)
		switch(team) {
			case 1: {
				give_item(player, "weapon_glock18")
				cs_set_user_bpammo(player, CSW_GLOCK18, 40)
			}
			case 2: {
				give_item(player, "weapon_usp")
				cs_set_user_bpammo(player, CSW_USP, 24)
			}
		}
	}
	
	new arg4[2]
	read_argv(2, arg4, 1)
	
	if(equal(arg4, "1"))
		set_user_health(player, pev(player, pev_max_health))
	
	new arg5[2]
	read_argv(2, arg5, 1)
	
	if(equal(arg5, "1"))
		cs_set_user_armor(player, 0, CS_ARMOR_NONE)
	
	new arg6[2]
	read_argv(2, arg6, 1)
	
	if(equal(arg6, "1"))
		set_user_frags(player, 0)
	
	new arg7[2]
	read_argv(2, arg7, 1)
	
	if(equal(arg7, "1"))
		cs_set_user_deaths(player, 0)
	return PLUGIN_HANDLED
}
