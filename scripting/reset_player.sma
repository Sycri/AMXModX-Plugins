
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
	
	create_cvar("rp_version", PLUGIN_VERSION, FCVAR_SERVER);
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
