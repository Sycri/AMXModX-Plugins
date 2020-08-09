
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>

new const PLUGIN_VERSION[] = "1.6"

// Consts
const REQUIRED_FLAG = ADMIN_SLAY

// Cvars
new cvar_cost, cvar_hp, cvar_ap,
cvar_gravity, cvar_speed

// Pointers
new pointer_showactivity

// Bools
new bool:g_has_upgrade[33]

// Vars
new g_freezetime

public plugin_init() {
	register_plugin("Upgrade", PLUGIN_VERSION, "Kristaps08")
	
	// Client Commands
	register_clcmd("say /upgrade","cmd_buyupgrade")
	register_clcmd("say_team /upgrade","cmd_buyupgrade")
	
	// Admin Commands
	register_concmd("amx_upgrade", "cmd_upgrade", REQUIRED_FLAG, "<target> [0|1] - 0=TAKE 1=GIVE")
	
	// Ham Forwards
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	
	// FM Forwards
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Events
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	
	// Logevents
	register_logevent("logevent_roundstart", 2, "1=Round_Start")  
	
	// Language File
	register_dictionary("upgrade.txt")
	
	// CVARS - General
	cvar_cost = register_cvar("upgrade_cost", "4000")
	cvar_hp = register_cvar("upgrade_hp", "150")
	cvar_ap = register_cvar("upgrade_ap", "150")
	cvar_gravity = register_cvar("upgrade_gravity", "0.75")
	cvar_speed = register_cvar("upgrade_speed", "300.0")
	
	// CVARS - Other
	register_cvar("upgrade_version", PLUGIN_VERSION, FCVAR_SERVER)
	
	// CVARS - Pointers
	pointer_showactivity = get_cvar_pointer("amx_show_activity")
}

public client_disconnect(id)
	g_has_upgrade[id] = false

public event_newround()
	g_freezetime = true

public logevent_roundstart()
	g_freezetime = false

public cmd_buyupgrade(id) {
	if(!is_user_alive(id))
		client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "NOT_ALIVE")
	else if(g_has_upgrade[id])
		client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "ALREADY_HAS")
	else if(cs_get_user_money(id) < get_pcvar_num(cvar_cost))
		client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "NOT_ENOUGH", get_pcvar_num(cvar_cost))
	else {
		cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(cvar_cost))
		g_has_upgrade[id] = true
		client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "BOUGHT_UPGRADE")
		fm_set_user_health(id, get_pcvar_num(cvar_hp))
		cs_set_user_armor(id, get_pcvar_num(cvar_ap), CS_ARMOR_VESTHELM)
		fm_set_user_gravity(id, get_pcvar_float(cvar_gravity))
	}
}

public fw_PlayerKilled(id) {
	if(!g_has_upgrade[id]) return PLUGIN_HANDLED
	
	client_print(id, print_chat, "[AMXX] %L", LANG_PLAYER, "LOST_UPGRADE")
	g_has_upgrade[id] = false
	return PLUGIN_HANDLED
}

public fw_PlayerSpawn_Post(id) {
	if(!is_user_alive(id) || !g_has_upgrade[id]) return PLUGIN_HANDLED
	
	fm_set_user_health(id, get_pcvar_num(cvar_hp))
	cs_set_user_armor(id, get_pcvar_num(cvar_ap), CS_ARMOR_VESTHELM)
	fm_set_user_gravity(id, get_pcvar_float(cvar_gravity))
	return PLUGIN_HANDLED
}

public fw_PlayerPreThink(id) {
	if(!is_user_alive(id) || !g_has_upgrade[id] || g_freezetime) return PLUGIN_HANDLED
	
	fm_set_user_maxspeed(id, get_pcvar_float(cvar_speed))
	return PLUGIN_HANDLED
}

public cmd_upgrade(id, level, cid) {
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
		if(!g_has_upgrade[player]) {
			switch(get_pcvar_num(pointer_showactivity)) {
				case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_GIVE_UPGRADE_PLAYER_CASE1", name)
				case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_GIVE_UPGRADE_PLAYER_CASE2", admin, name)
			}
			g_has_upgrade[player] = true
			fm_set_user_health(player, get_pcvar_num(cvar_hp))
			cs_set_user_armor(player, get_pcvar_num(cvar_ap), CS_ARMOR_VESTHELM)
			fm_set_user_gravity(id, get_pcvar_float(cvar_gravity))
		}
		else
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMIN_ALREADY_HAS")
	}
	else if(equal(arg2, "0")) {
		if(g_has_upgrade[player]) {
			switch(get_pcvar_num(pointer_showactivity)) {
				case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_TOOK_UPGRADE_PLAYER_CASE1", name)
				case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_TOOK_UPGRADE_PLAYER_CASE2", admin, name)
			}
			g_has_upgrade[player] = false
		}
		else
			client_print(id, print_console, "%L", LANG_PLAYER, "ADMIN_DOESNT_HAVE")
	}
	return PLUGIN_HANDLED
}
