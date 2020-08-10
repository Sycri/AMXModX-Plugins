
#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.9";

new const InvisibleCommand[] = "amx_invisible";

new CvarInvisibleAmount;

new bool:g_IsInvisible[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("Invisible Player", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("invisible_player.txt");
	
	register_concmd(InvisibleCommand, "@ConsoleCommand_Invisible", ADMIN_LEVEL_A, "INVISIBLE_CMD_INFO", .info_ml = true);

	RegisterHamPlayer(Ham_Spawn, "@Forward_PlayerSpawn_Post", 1);

	bind_pcvar_num(create_cvar("amx_invisible_amount", "20", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 255.0), CvarInvisibleAmount);

	create_cvar("amx_invisible_version", PLUGIN_VERSION, FCVAR_SERVER);
}

public client_disconnected(id)
{
	g_IsInvisible[id] = false;
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
		if (!g_IsInvisible[player]) {
			show_activity_key("ADMIN_INVISIBLE_ON_1", "ADMIN_INVISIBLE_ON_2", admin, name);
			g_IsInvisible[player] = true;

			set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, CvarInvisibleAmount);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS");
		}
	} else {
		if (g_IsInvisible[player]) {
			show_activity_key("ADMIN_INVISIBLE_OFF_1", "ADMIN_INVISIBLE_OFF_2", admin, name);
			g_IsInvisible[player] = false;

			set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS_NOT");
		}
	}
	return PLUGIN_HANDLED;
}

@Forward_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_IsInvisible[id])
		return HAM_IGNORED;
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, CvarInvisibleAmount);
	return HAM_HANDLED;
}
