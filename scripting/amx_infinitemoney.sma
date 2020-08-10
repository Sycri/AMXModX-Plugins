/*=================================================================================
						AMX Infinite Money
					by Sycri (Kristaps08)

	Description:
		With this plugin you can make a player have infinite money

	Cvars:
		None

	Admin Commands:
		amx_infinitemoney <target> [0|1] - 0=OFF 1=ON

	Credits:
		None

	Changelog:
		- v1.0
		* First release

		- v1.1
		* Added support to give infinite money while the target is dead
		* Changed and cleaned up some code

		- v1.2 (29th August 2012)
		* Added description
		* Optimized the code a little bit
		* First public release

		- v1.3 (10th August 2020)
		* Added multilingual support to the description of the command amx_infinitemoney
		* Added FCVAR_SPONLY to cvar amx_infinitemoney_version to make it unchangeable
		* Changed from fakemeta to cstrike because the functions of the latter are native
		* Changed the required admin level of the command amx_infinitemoney from ADMIN_MAP to ADMIN_LEVEL_A
		* Forced usage of semicolons for better clarity
		* Replaced amx_show_activity checking with show_activity_key
		* Replaced FM_PlayerPreThink with Money event since the former gets called too frequently
		* Replaced read_argv with read_argv_int where appropriate
		* Replaced register_cvar with create_cvar
		* Replaced register_event with register_event_ex for better code readability
		* Revamped the entire plugin for better code style

=================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.3";

new const InfiniteMoneyCommand[] = "amx_infinitemoney";

new CvarStartmoney;

new bool:g_HasInfiniteMoney[MAX_PLAYERS + 1];

public plugin_init()
{ 
	register_plugin("AMX Infinite Money", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("amx_infinitemoney.txt");
	
	register_concmd(InfiniteMoneyCommand, "@ConsoleCommand_InfiniteMoney", ADMIN_LEVEL_A, "INFINITE_MONEY_CMD_INFO", .info_ml = true);

	register_event_ex("Money", "@Forward_MoneyChange", RegisterEvent_Single, "1!99999");

	create_cvar("amx_infinitemoney_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY);
} 

public OnConfigsExecuted()
{
	bind_pcvar_num(get_cvar_pointer("mp_startmoney"), CvarStartmoney);
}

public client_disconnected(id)
{
	g_HasInfiniteMoney[id] = false;
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
		if (!g_HasInfiniteMoney[player]) {
			show_activity_key("ADMIN_INFINITE_MONEY_ON_1", "ADMIN_INFINITE_MONEY_ON_2", admin, name);

			g_HasInfiniteMoney[player] = true;
			cs_set_user_money(id, 99999, 0);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS");
		}
	} else {
		if (g_HasInfiniteMoney[player]) {
			show_activity_key("ADMIN_INFINITE_MONEY_OFF_1", "ADMIN_INFINITE_MONEY_OFF_2", admin, name);

			g_HasInfiniteMoney[player] = false;
			cs_set_user_money(player, CvarStartmoney, 0);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS_NOT");
		}
	}
	return PLUGIN_HANDLED;
}

@Forward_MoneyChange(id)
{
	if (!g_HasInfiniteMoney[id])
		return PLUGIN_HANDLED;

	cs_set_user_money(id, 99999, 0);
	return PLUGIN_HANDLED;
}
