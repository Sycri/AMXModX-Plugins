/* AMX Mod X script.
*
*	[SH] Core: Speed (sh_core_speed.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>

#pragma semicolon 1

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

new gSuperHeroCount;

new Float:gHeroMaxSpeed[SH_MAXHEROS];
new gHeroSpeedWeapons[SH_MAXHEROS]; // bit-field of weapons

// Player bool variables (using bit-fields for lower memory footprint and better CPU performance)
#define flag_get(%1,%2)			(%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2)	(flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2)			%1 |= (1 << (%2 & 31))
#define flag_clear(%1,%2)		%1 &= ~(1 << (%2 & 31))

new gBlockSpeed;

new gPlayerStunTimer[MAX_PLAYERS + 1];
new Float:gPlayerStunSpeed[MAX_PLAYERS + 1];
new bool:gFreezeTime;

new sv_maxspeed;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Speed", SH_VERSION_STR, SH_AUTHOR_STR);

	register_event("HLTV", "@Event_HLTV", "a", "1=0", "2=0"); // New Round
	register_logevent("@LogEvent_RoundStart", 2, "1=Round_Start");

	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);

	sv_maxspeed = get_cvar_pointer("sv_maxspeed");
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_speed");
	
	register_native("sh_set_hero_speed", "@Native_SetHeroSpeed");
	register_native("sh_block_hero_speed", "@Native_BlockHeroSpeed");
	register_native("sh_set_stun", "@Native_SetStun");
	register_native("sh_get_stun", "@Native_GetStun");
	register_native("sh_reset_max_speed", "@Native_ResetMaxSpeed");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();

	set_task_ex(1.0, "@Task_StunCheck", _, _, _, SetTask_Repeat);
	set_task(5.0, "@Task_SetServerMaxSpeed");
}
//----------------------------------------------------------------------------------------------
public client_putinserver(id)
{
	gPlayerStunTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	gPlayerStunTimer[id] = -1;

	flag_clear(gBlockSpeed, id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID)
{
	if (gHeroMaxSpeed[heroID] > 0.0 && is_user_alive(id))
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerStunTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_speed(heroID, pcvarSpeed, const weapons = CSW_ALL_WEAPONS)
@Native_SetHeroSpeed(plugin_id, num_params)
{
	new heroID = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroID < 0 || heroID >= sh_get_num_heroes()) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Hero ID (%d)", heroID);
		return false;
	}

	new weapons = get_param(3);

	bind_pcvar_float(get_param(2), gHeroMaxSpeed[heroID]); // pCVAR expected!
	gHeroSpeedWeapons[heroID] = weapons; // Bit-field expected!

	sh_debug_message(0, 3, "Set Max Speed -> HeroID: %d - Speed: %.3f - Weapon(s): %s", heroID, gHeroMaxSpeed[heroID], weapons);
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_block_hero_speed(id, bool:block = true)
@Native_BlockHeroSpeed(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	if (get_param(2))
		flag_set(gBlockSpeed, id);
	else
		flag_clear(gBlockSpeed, id);
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_set_stun(id, Float:howLong, Float:speed = 0.0)
@Native_SetStun(plugin_id, num_params)
{
	if (!sh_is_active())
		return false;

	new id = get_param(1);

	if (!is_user_alive(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	new Float:howLong = get_param_f(2);

	if (howLong > gPlayerStunTimer[id]) {
		new Float:speed = get_param_f(3);
		sh_debug_message(id, 5, "Stunning for %f seconds at %f speed", howLong, speed);
		gPlayerStunTimer[id] = floatround(howLong);
		gPlayerStunSpeed[id] = speed;
		set_user_maxspeed(id, speed);
		return true;
	}
	return false;
}
//----------------------------------------------------------------------------------------------
//native sh_get_stun(id)
bool:@Native_GetStun(plugin_id, num_params)
{
	if (!sh_is_active())
		return false;

	new id = get_param(1);

	if (!is_user_alive(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	return gPlayerStunTimer[id] > 0 ? true : false;
}
//----------------------------------------------------------------------------------------------
//native sh_reset_max_speed(id)
@Native_ResetMaxSpeed(plugin_id, num_params)
{
	if (!sh_is_active())
		return false;

	new id = get_param(1);

	if (!is_user_alive(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
	return true;
}
//----------------------------------------------------------------------------------------------
@Event_HLTV()
{
	gFreezeTime = true;
}
//----------------------------------------------------------------------------------------------
@LogEvent_RoundStart()
{
	gFreezeTime = false;
}
//----------------------------------------------------------------------------------------------
@Forward_AddPlayerItem_Post(id)
{
	setSpeedPowers(id);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_Player_ResetMaxSpeed_Post(id)
{
	setSpeedPowers(id);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
setSpeedPowers(id)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(id) || gFreezeTime || !sh_user_is_loaded(id))
		return;

	if (gPlayerStunTimer[id] > 0) {
		static Float:stunSpeed;
		stunSpeed = gPlayerStunSpeed[id];

		set_user_maxspeed(id, stunSpeed);
		sh_debug_message(id, 5, "Setting Stun Speed To %f", stunSpeed);
		return;
	}

	if (flag_get_boolean(gBlockSpeed, id))
		return;

	if (cs_get_user_zoom(id) != CS_SET_NO_ZOOM)
		return;

	static Float:heroSpeed;
	heroSpeed = getMaxSpeed(id, cs_get_user_weapon(id));

	if (heroSpeed == -1.0)
		return;

	static Float:oldSpeed;
	oldSpeed = get_user_maxspeed(id);

	sh_debug_message(id, 10, "Checking Speeds - Old: %f - New: %f", oldSpeed, heroSpeed);

	if (oldSpeed != heroSpeed) {
		set_user_maxspeed(id, heroSpeed);
		sh_debug_message(id, 5, "Setting Speed To %f", heroSpeed);
	}
}
//----------------------------------------------------------------------------------------------
Float:getMaxSpeed(id, weapon)
{
	static heroName[25];
	static Float:returnSpeed, Float:heroSpeed, i;
	static playerPowerCount, heroID;
	returnSpeed = -1.0;
	playerPowerCount = sh_get_user_powers(id);

	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);
		
		if (-1 < heroID < gSuperHeroCount) {
			heroSpeed = gHeroMaxSpeed[heroID];
			if (heroSpeed <= 0.0)
				continue;

			sh_get_hero_name(heroID, heroName, charsmax(heroName));
			sh_debug_message(id, 5, "Looking for Speed Functions - %s, %d, %d", heroName, gHeroSpeedWeapons[heroID], weapon);

			if (gHeroSpeedWeapons[heroID] & (1 << weapon))
				returnSpeed = floatmax(returnSpeed, heroSpeed);
		}
	}

	return returnSpeed;
}
//----------------------------------------------------------------------------------------------
@Task_StunCheck()
{
	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		// Switches are faster but we don't want to do anything with -1
		switch (gPlayerStunTimer[player]) {
			case -1: { /*Do nothing*/ }
			case 0: {
				gPlayerStunTimer[player] = -1;
				ExecuteHamB(Ham_Player_ResetMaxSpeed, player);
			}
			default: {
				--gPlayerStunTimer[player];
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
@Task_SetServerMaxSpeed()
{
	new maxSpeed = 320; // Server Default
	for (new i = 0; i < gSuperHeroCount; ++i) {
		if (gHeroMaxSpeed[i] != 0)
			maxSpeed = max(maxSpeed, floatround(gHeroMaxSpeed[i], floatround_ceil));
	}

	// Only set if below required speed to avoid setting lower then server op may want
	if (get_pcvar_num(sv_maxspeed) < maxSpeed) {
		sh_debug_message(0, 1, "Setting server CVAR sv_maxspeed to: %d", maxSpeed);
		set_pcvar_num(sv_maxspeed, maxSpeed);
	}
}
//----------------------------------------------------------------------------------------------
