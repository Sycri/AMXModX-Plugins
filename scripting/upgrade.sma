
#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <hamsandwich>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.7";

new const UpgradeCommand[] = "amx_upgrade";

new CvarCost;
new CvarHealth;
new CvarArmor;
new Float:CvarGravity;
new Float:CvarSpeed;

new bool:g_HasUpgrade[MAX_PLAYERS + 1];
new bool:g_IsFreezetime;

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

public plugin_init()
{
	register_plugin("Upgrade", PLUGIN_VERSION, "Sycri (Kristaps08)");
	register_dictionary("upgrade.txt");
	
	register_clcmd("say /upgrade", "@ClientCommand_BuyUpgrade");
	register_clcmd("say_team /upgrade", "@ClientCommand_BuyUpgrade");
	
	register_concmd(UpgradeCommand, "@ConsoleCommand_Upgrade", ADMIN_LEVEL_A, "UPGRADE_CMD_INFO", .info_ml = true);
	
	RegisterHamPlayer(Ham_Killed, "@Forward_PlayerKilled");
	RegisterHamPlayer(Ham_Spawn, "@Forward_PlayerSpawn_Post", 1);
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);
	
	register_event_ex("HLTV", "@Forward_NewRound", RegisterEvent_Global, "1=0", "2=0");

	register_logevent("@Forward_RoundStart", 2, "1=Round_Start");
	
	bind_pcvar_num(create_cvar("upgrade_cost", "4000", .has_min = true, .min_val = 0.0), CvarCost);
	bind_pcvar_num(create_cvar("upgrade_hp", "150", .has_min = true, .min_val = 1.0), CvarHealth);
	bind_pcvar_num(create_cvar("upgrade_ap", "150", .has_min = true, .min_val = 0.0), CvarArmor);
	bind_pcvar_float(create_cvar("upgrade_gravity", "0.75", .has_min = true, .min_val = 0.0), CvarGravity);
	bind_pcvar_float(create_cvar("upgrade_speed", "300.0", .has_min = true, .min_val = 0.0), CvarSpeed);
	
	create_cvar("upgrade_version", PLUGIN_VERSION, FCVAR_SERVER);
}

public client_disconnected(id)
{
	g_HasUpgrade[id] = false;
}

@ClientCommand_BuyUpgrade(id)
{
	if (!is_user_alive(id)) {
		client_print(id, print_chat, "%l", "NOT_ALIVE");
		return PLUGIN_HANDLED;
	}
	
	if (g_HasUpgrade[id]) {
		client_print(id, print_chat, "%l", "ALREADY_IS");
		return PLUGIN_HANDLED;
	}
	
	if (cs_get_user_money(id) < CvarCost) {
		client_print(id, print_chat, "%l", "NOT_ENOUGH", CvarCost);
		return PLUGIN_HANDLED;
	}
	
	cs_set_user_money(id, cs_get_user_money(id) - CvarCost);
	g_HasUpgrade[id] = true;
	client_print(id, print_chat, "%l", "GAIN_UPGRADE");

	upgradePlayer(id);
	return PLUGIN_HANDLED;
}

@ConsoleCommand_Upgrade(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;
	
	new arg[32];
	read_argv(1, arg, charsmax(arg));
	
	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	if (!player) 
		return PLUGIN_HANDLED;
	
	new name[32];
	new admin[32];
	get_user_name(player, name, charsmax(name));
	get_user_name(id, admin, charsmax(admin));
	
	if (read_argv_int(2) == 1) {
		if (!g_HasUpgrade[player]) {
			show_activity_key("ADMIN_GIVE_UPGRADE_1", "ADMIN_GIVE_UPGRADE_2", admin, name);
			g_HasUpgrade[player] = true;
			client_print(player, print_chat, "%l", "GAIN_UPGRADE");

			upgradePlayer(player);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS");
		}
	} else {
		if (g_HasUpgrade[player]) {
			show_activity_key("ADMIN_TOOK_UPGRADE_1", "ADMIN_TOOK_UPGRADE_2", admin, name);
			g_HasUpgrade[player] = false;
			client_print(player, print_chat, "%l", "LOST_UPGRADE");

			deupgradePlayer(player);
		} else {
			console_print(id, "%l", "ADMIN_ALREADY_IS_NOT");
		}
	}
	return PLUGIN_HANDLED;
}

@Forward_PlayerKilled(id)
{
	if (!g_HasUpgrade[id])
		return HAM_IGNORED;
	
	client_print(id, print_chat, "%l", "LOST_UPGRADE");
	g_HasUpgrade[id] = false;
	return HAM_HANDLED;
}

@Forward_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_HasUpgrade[id])
		return HAM_IGNORED;
	
	upgradePlayer(id);
	return HAM_HANDLED;
}

@Forward_Player_ResetMaxSpeed_Post(id)
{
	if (!is_user_alive(id) || !g_HasUpgrade[id] || g_IsFreezetime)
		return HAM_IGNORED;
	
	set_user_maxspeed(id, CvarSpeed);
	return HAM_HANDLED;
}

@Forward_NewRound()
{
	g_IsFreezetime = true;
}

@Forward_RoundStart()
{
	g_IsFreezetime = false;
}

upgradePlayer(index)
{
	set_user_health(index, CvarHealth);
	cs_set_user_armor(index, CvarArmor, CS_ARMOR_VESTHELM);
	set_user_gravity(index, CvarGravity);
	set_user_maxspeed(index, CvarSpeed);
}

deupgradePlayer(index)
{

	if (get_user_health(index) > 100)
		set_user_health(index, 100);
	
	if (get_user_armor(index) > 100)
		set_user_armor(index, 100);

	set_user_gravity(index, 1.0);
	cs_reset_user_maxspeed(index);
}

cs_reset_user_maxspeed(index)
{
    new Float:maxSpeed;
    switch (get_user_weapon(index)) {
        case CSW_SG550, CSW_AWP, CSW_G3SG1: maxSpeed = 210.0;
        case CSW_M249: maxSpeed = 220.0;
        case CSW_AK47: maxSpeed = 221.0;
        case CSW_M3, CSW_M4A1: maxSpeed = 230.0;
        case CSW_SG552: maxSpeed = 235.0;
        case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: maxSpeed = 240.0;
        case CSW_P90: maxSpeed = 245.0;
        case CSW_SCOUT: maxSpeed = 260.0;
        default: maxSpeed = 250.0;
    }
    set_user_maxspeed(index, maxSpeed);
}