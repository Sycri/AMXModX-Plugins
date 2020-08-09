
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

	create_cvar("amx_infinitemoney_version", PLUGIN_VERSION, FCVAR_SERVER);
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
