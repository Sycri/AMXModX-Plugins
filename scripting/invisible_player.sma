
#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>

new const PLUGIN_VERSION[] = "1.8"

// Consts
new const REQUIRED_FLAG = ADMIN_MAP

// Cvars
new cvar_invisible_amount

// Pointers
new pointer_showactivity

// Bools
new bool:g_is_invisible[33]

public plugin_init() {
	register_plugin("Invisible Player", PLUGIN_VERSION, "Kristaps08")
	
	// CVARS - General
	cvar_invisible_amount = register_cvar("amx_invisible_amount","20")
	
	// CVARS - Other
	register_cvar("amx_invisible_version", PLUGIN_VERSION, FCVAR_SERVER)
	
	// CVARS - Pointers
	pointer_showactivity = get_cvar_pointer("amx_show_activity")
	
	// FM Forwards
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Admin Commands
	register_concmd("amx_invisible", "cmd_invisible", REQUIRED_FLAG, "<target> [0|1] - 0=OFF 1=ON")
	
	// Language File
	register_dictionary("invisible_player.txt")
}

public client_disconnect(id) {
	if(g_is_invisible[id])
		g_is_invisible[id] = false
}

public fw_PlayerPreThink(id) {
	if(!is_user_alive(id) || !g_is_invisible[id]) return PLUGIN_HANDLED
	
	fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, get_pcvar_num(cvar_invisible_amount))
	return PLUGIN_HANDLED
}

public cmd_invisible(id, level, cid) {
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new arg[32]
	new arg2[2]
	read_argv(1, arg, 31)
	read_argv(2, arg2, 1)
	
	new player = cmd_target(id, arg, 7)
	if(!player)
		return PLUGIN_HANDLED
	
	new name[32]
	new admin[32]
	get_user_name(player, name, 31)
	get_user_name(id, admin, 31)
	
	if(equal(arg2, "1")) {
		if(!g_is_invisible[player]) {
			switch(get_pcvar_num(pointer_showactivity)) {
				case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_INVISIBLE_ON_PLAYER_CASE1", name)
				case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_INVISIBLE_ON_PLAYER_CASE2", admin, name)
			}
			g_is_invisible[player] = true
		}
		else
			client_print(0, print_console, "%L", LANG_PLAYER, "ADMIN_ALREADY_IS")
	}
	else if(equal(arg2, "0")) {
		if(g_is_invisible[player]) {
			switch(get_pcvar_num(pointer_showactivity)) {
				case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_INVISIBLE_OFF_PLAYER_CASE1", name)
				case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_INVISIBLE_OFF_PLAYER_CASE2", admin, name)
			}
			g_is_invisible[player] = false
			fm_set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255)
		}
		else
			client_print(0, print_console, "%L", LANG_PLAYER, "ADMIN_DOESNT_HAVE")
	}
	return PLUGIN_HANDLED
}
