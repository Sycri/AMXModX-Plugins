/*================================================================================
	
	-----------------------
	-*- [ZP] Ammo Packs -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <zp50_core>

#pragma semicolon 1

#define is_user_valid(%1) (1 <= %1 <= MaxClients)

#define TASK_HIDEMONEY 100
#define ID_HIDEMONEY (taskid - TASK_HIDEMONEY)

const HIDE_MONEY_BIT = (1 << 5);

new gAmmoPacks[MAX_PLAYERS + 1];
new gmsgHideWeapon, gmsgCrosshair;

new CvarStartingAmmoPacks, CvarDisableMoney;

public plugin_init()
{
	register_plugin("[ZP] Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team");
	
	gmsgHideWeapon = get_user_msgid("HideWeapon");
	gmsgCrosshair = get_user_msgid("Crosshair");
	
	bind_pcvar_num(create_cvar("zp_starting_ammo_packs", "5"), CvarStartingAmmoPacks);
	bind_pcvar_num(create_cvar("zp_disable_money", "0"), CvarDisableMoney);
	
	register_event_ex("ResetHUD", "@Event_ResetHUD", RegisterEvent_Single | RegisterEvent_OnlyAlive);
	register_message(get_user_msgid("Money"), "@Message_Money");
}

public plugin_natives()
{
	register_library("zp50_ammopacks");
	register_native("zp_ammopacks_get", "@Native_AmmopacksGet");
	register_native("zp_ammopacks_set", "@Native_AmmopacksSet");
}

@Native_AmmopacksGet(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return -1;
	}
	
	return gAmmoPacks[id];
}

@Native_AmmopacksSet(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	new amount = get_param(2);
	
	gAmmoPacks[id] = amount;
	return true;
}

public client_putinserver(id)
{
	gAmmoPacks[id] = CvarStartingAmmoPacks;
}

public client_disconnected(id)
{
	remove_task(id + TASK_HIDEMONEY);
}

@Event_ResetHUD(id)
{
	// Hide money?
	if (CvarDisableMoney)
		set_task(0.1, "@Task_HideMoney", id + TASK_HIDEMONEY);
}

// Hide Player's Money Task
@Task_HideMoney(taskid)
{
	// Hide money
	message_begin(MSG_ONE, gmsgHideWeapon, _, ID_HIDEMONEY);
	write_byte(HIDE_MONEY_BIT); // what to hide bitsum
	message_end();
	
	// Hide the HL crosshair that's drawn
	message_begin(MSG_ONE, gmsgCrosshair, _, ID_HIDEMONEY);
	write_byte(0); // toggle
	message_end();
}

@Message_Money(msg_id, msg_dest, msg_entity)
{
	// Disable money setting enabled?
	if (!CvarDisableMoney)
		return PLUGIN_CONTINUE;
	
	cs_set_user_money(msg_entity, 0, 0);
	return PLUGIN_HANDLED;
}
