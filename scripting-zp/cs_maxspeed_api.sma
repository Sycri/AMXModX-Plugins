/*================================================================================
	
	-----------------------------
	-*- [CS] MaxSpeed API 1.1 -*-
	-----------------------------
	
	- Allows easily setting a player's maxspeed in CS and CZ
	- Lets you use maxspeed multipliers instead of absolute values
	- Doesn't affect CS Freezetime
	
================================================================================*/

#include <amxmodx>
#include <engine>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <cs_maxspeed_api_const>

#pragma semicolon 1

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2)		%1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2)	%1 &= ~(1 << (%2 & 31))

new gHasCustomMaxSpeed;
new gMaxSpeedIsMultiplier;
new Float:gCustomMaxSpeed[MAX_PLAYERS + 1];
new bool:gFreezeTime;

public plugin_init()
{
	register_plugin("[CS] MaxSpeed API", "1.1", "WiLS");

	register_event("HLTV", "@Event_HLTV", "a", "1=0", "2=0"); // New Round
	register_logevent("@LogEvent_RoundStart", 2, "1=Round_Start");

	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);
}

public plugin_cfg()
{
	// Prevents CS from limiting player maxspeeds at 320
	set_pcvar_num(get_cvar_pointer("sv_maxspeed"), 2000);
}

public plugin_natives()
{
	register_library("cs_maxspeed_api");
	register_native("cs_set_player_maxspeed", "@Native_SetPlayerMaxSpeed");
	register_native("cs_reset_player_maxspeed", "@Native_ResetPlayerMaxSpeed");
}

@Native_SetPlayerMaxSpeed(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	new Float:maxspeed = get_param_f(2);
	
	if (maxspeed < 0.0) {
		log_error(AMX_ERR_NATIVE, "[CS] Invalid maxspeed value %.2f", maxspeed);
		return false;
	}
	
	new multiplier = get_param(3);
	
	flag_set(gHasCustomMaxSpeed, id);
	gCustomMaxSpeed[id] = maxspeed;
	
	if (multiplier)
		flag_set(gMaxSpeedIsMultiplier, id);
	else
		flag_unset(gMaxSpeedIsMultiplier, id);
	
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
	return true;
}

@Native_ResetPlayerMaxSpeed(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	// Player doesn't have custom maxspeed, no need to reset
	if (!flag_get(gHasCustomMaxSpeed, id))
		return true;
	
	flag_unset(gHasCustomMaxSpeed, id);
	
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
	return true;
}

public client_disconnected(id)
{
	flag_unset(gHasCustomMaxSpeed, id);
}

@Event_HLTV()
{
	gFreezeTime = true;
}

@LogEvent_RoundStart()
{
	gFreezeTime = false;
}

@Forward_AddPlayerItem_Post(id)
{
	setSpeed(id);
	return HAM_IGNORED;
}

@Forward_Player_ResetMaxSpeed_Post(id)
{
	setSpeed(id);
	return HAM_IGNORED;
}

setSpeed(index)
{
	if (gFreezeTime || !is_user_alive(index) || !flag_get(gHasCustomMaxSpeed, index))
		return;

	if (cs_get_user_zoom(index) != CS_SET_NO_ZOOM)
		return;

	if (flag_get(gMaxSpeedIsMultiplier, index))
		set_user_maxspeed(index, get_user_maxspeed(index) * gCustomMaxSpeed[index]);
	else
		set_user_maxspeed(index, gCustomMaxSpeed[index]);
}
