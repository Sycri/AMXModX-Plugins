
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new const PLUGIN_VERSION[] = "1.2"

// Consts
const OFFSET_CSMONEY = 115
const OFFSET_LINUX = 5
const REQUIRED_FLAG = ADMIN_MAP

// Bools
new bool:g_has_infinitemoney[33]

// Pointers
new pointer_showactivity

public plugin_init() { 
	register_plugin("AMX Infinite Money", PLUGIN_VERSION, "Kristaps08")
	
	// CVARS - Pointers
	pointer_showactivity = get_cvar_pointer("amx_show_activity")
	
	// CVARS - Other
	register_cvar("amx_infinitemoney_version", PLUGIN_VERSION, FCVAR_SERVER)
	
	// FM Forwards
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Admin Commands
	register_concmd("amx_infinitemoney", "cmd_infinitemoney", REQUIRED_FLAG, "<target> [0|1] - 0=OFF 1=ON")
} 

public client_disconnect(id)
	g_has_infinitemoney[id] = false

public cmd_infinitemoney(id, level, cid) {
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED
	
	new arg[32]
	new arg2[2]
	read_argv(1, arg, 31)
	read_argv(2, arg2, 1)
	
	new player = cmd_target(id, arg, 3)
	if(!player) 
		return PLUGIN_HANDLED
	
	new name[32]
	new admin[32]
	get_user_name(player, name, 31)
	get_user_name(id, admin, 31)
	
	if(equal(arg2, "1")) {
		if(!g_has_infinitemoney[player]) {
			switch(get_pcvar_num(pointer_showactivity)) {
				case 1: client_print(0, print_chat, "ADMIN: turned on infinite money for player %s", name)
				case 2: client_print(0, print_chat, "ADMIN %s: turned on infinite money for player %s", admin, name)
			}
			g_has_infinitemoney[player] = true
		}
		else
			client_print(id, print_console, "This target already has infinite money.")
	}
	else if(equal(arg2, "0")) {
		if(g_has_infinitemoney[player]) {
			switch(get_pcvar_num(pointer_showactivity)) {
				case 1: client_print(0, print_chat, "ADMIN: turned off infinite money for player %s", name)
				case 2: client_print(0, print_chat, "ADMIN %s: turned off infinite money for player %s", admin, name)
			}
			g_has_infinitemoney[player] = false
			fm_set_user_money(player, get_cvar_num("mp_startmoney"), 0)
		}
		else
			client_print(id, print_console, "This target doesn't have infinite money.")
	}
	return PLUGIN_HANDLED
}

public fw_PlayerPreThink(id) {
	if(!g_has_infinitemoney[id]) return PLUGIN_HANDLED

	fm_set_user_money(id, 999999, 0)
	return PLUGIN_HANDLED
}

stock fm_set_user_money(id, money, flash = 1) {
	set_pdata_int(id, OFFSET_CSMONEY, money, OFFSET_LINUX)
	
	message_begin(MSG_ONE, get_user_msgid("Money"), {0, 0, 0}, id)
	write_long(money)
	write_byte(flash)
	message_end()
}
