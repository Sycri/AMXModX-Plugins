/* AMX Mod X script.
*
*   [SH] Core: Speed (sh_core_speed.sma)
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_objectives>
#include <sh_core_speed>

#pragma semicolon 1

new gSuperHeroCount;

new Float:gHeroMaxSpeed[SH_MAXHEROS];
new gHeroSpeedWeapons[SH_MAXHEROS][31]; // array weapons of weapon's i.e. {4,30} Note:{0}=all

new gPlayerStunTimer[MAX_PLAYERS + 1];
new Float:gPlayerStunSpeed[MAX_PLAYERS + 1];

new CvarDebugMessages;
new sv_maxspeed;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Speed", SH_VERSION_STR, SH_AUTHOR_STR);

	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	
	new weaponName[32];
	for (new id = CSW_P228; id <= CSW_P90; id++) {
		if (get_weaponname(id, weaponName, charsmax(weaponName)))
			RegisterHam(Ham_CS_Item_GetMaxSpeed, weaponName, "@Forward_CS_Item_GetMaxSpeed_Pre", 0);
	}

	bind_pcvar_num(get_cvar_pointer("sh_debug_messages"), CvarDebugMessages);
	sv_maxspeed = get_cvar_pointer("sv_maxspeed");
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_speed");
	
	register_native("sh_set_hero_speed", "@Native_SetHeroSpeed");
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
public client_connect(id)
{
	gPlayerStunTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	gPlayerStunTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID)
{
	if (gHeroMaxSpeed[heroID] > 0.0)
		setSpeedPowers(id, true);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerStunTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_speed(heroID, pcvarSpeed, const weapons[] = {0}, numofwpns = 1)
@Native_SetHeroSpeed()
{
	new heroIndex = get_param(1);

    //Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroIndex < 0 || heroIndex >= sh_get_num_heroes())
        return;

	new pcvarSpeed = get_param(2);
	new numWpns = get_param(4);

	new weaponList[31];
	get_array(3, weaponList, numWpns);

	//Avoid running this unless debug is high enough
	if (CvarDebugMessages > 2) {
		//Set up the weapon string for the debug message
		new weapons[32], number[3], x;
		for (x = 0; x < numWpns; x++) {
			formatex(number, charsmax(number), "%d", weaponList[x]);
			add(weapons, charsmax(weapons), number);
			
			if (weaponList[x + 1] != '^0')
				add(weapons, charsmax(weapons), ",");
			else
				break;
		}

		sh_debug_message(0, 3, "Set Max Speed -> HeroID: %d - Speed: %f - Weapon(s): %s", heroIndex, get_pcvar_float(pcvarSpeed), weapons);
	}

	bind_pcvar_float(pcvarSpeed, gHeroMaxSpeed[heroIndex]);
	copy(gHeroSpeedWeapons[heroIndex], charsmax(gHeroSpeedWeapons[]), weaponList); // Array expected!
}
//----------------------------------------------------------------------------------------------
//native sh_set_stun(id, Float:howLong, Float:speed = 0.0)
@Native_SetStun()
{
	if (!sh_is_active())
		return;

	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	new Float:howLong = get_param_f(2);

	if (howLong > gPlayerStunTimer[id]) {
		new Float:speed = get_param_f(3);
		sh_debug_message(id, 5, "Stunning for %f seconds at %f speed", howLong, speed);
		gPlayerStunTimer[id] = floatround(howLong);
		gPlayerStunSpeed[id] = speed;
		set_user_maxspeed(id, speed);
	}
}
//----------------------------------------------------------------------------------------------
//native sh_get_stun(id)
bool:@Native_GetStun()
{
	if (!sh_is_active())
		return false;

	new id = get_param(1);

	if (!is_user_alive(id))
		return false;

	return gPlayerStunTimer[id] > 0 ? true : false;
}
//----------------------------------------------------------------------------------------------
//native sh_reset_max_speed(id)
@Native_ResetMaxSpeed()
{
	setSpeedPowers(get_param(1), true);
}
//----------------------------------------------------------------------------------------------
@Forward_AddPlayerItem_Post(id)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	if (!is_user_alive(id) || sh_is_freezetime() || !sh_user_is_loaded(id))
		return HAM_IGNORED;

	if (gPlayerStunTimer[id] > 0) {
		static Float:stunSpeed;
		stunSpeed = gPlayerStunSpeed[id];

		SetHamReturnFloat(stunSpeed);
		sh_debug_message(id, 5, "Setting Stun Speed To %f", stunSpeed);
		return HAM_SUPERCEDE;
	}

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_SPEED)
		return HAM_IGNORED;

	if (cs_get_user_zoom(id) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	static Float:heroSpeed;
	heroSpeed = getMaxSpeed(id, cs_get_user_weapon(id));

	if (heroSpeed == -1.0)
		return HAM_IGNORED;

	set_user_maxspeed(id, heroSpeed);
	sh_debug_message(id, 5, "Setting Speed To %f", heroSpeed);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_CS_Item_GetMaxSpeed_Pre(weapon, Float:newSpeed)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	static owner;
	owner = pev(weapon, pev_owner);

	if (!is_user_alive(owner) || !sh_user_is_loaded(owner))
		return HAM_IGNORED;

	if (gPlayerStunTimer[owner] > 0) {
		static Float:stunSpeed;
		stunSpeed = gPlayerStunSpeed[owner];

		SetHamReturnFloat(stunSpeed);
		sh_debug_message(owner, 5, "Setting Stun Speed To %f", stunSpeed);
		return HAM_SUPERCEDE;
	}

	if (owner == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_SPEED)
		return HAM_IGNORED;

	if (cs_get_user_zoom(owner) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	static Float:heroSpeed;
	heroSpeed = getMaxSpeed(owner, cs_get_weapon_id(weapon));

	if (heroSpeed == -1.0)
		return HAM_IGNORED;

	SetHamReturnFloat(heroSpeed);
	sh_debug_message(owner, 5, "Setting Speed To %f", heroSpeed);
	return HAM_SUPERCEDE;
}
//----------------------------------------------------------------------------------------------
setSpeedPowers(id, bool:checkDefault)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(id) || sh_is_freezetime() || !sh_user_is_loaded(id))
		return;

	if (gPlayerStunTimer[id] > 0) {
		new Float:stunSpeed = gPlayerStunSpeed[id];
		set_user_maxspeed(id, stunSpeed);

		sh_debug_message(id, 5, "Setting Stun Speed To %f", stunSpeed);
		return;
	}

	new weapon = cs_get_user_weapon(id);
	new Float:oldSpeed = get_user_maxspeed(id);
	new Float:newSpeed;

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_SPEED) {
		newSpeed = 227.0;
	} else if (cs_get_user_zoom(id) != CS_SET_NO_ZOOM) {
		switch (weapon) {
			// If weapon is a zoomed sniper rifle set default speeds
			case CSW_SCOUT, CSW_SG550, CSW_AWP, CSW_G3SG1: newSpeed = sh_get_weapon_speed(weapon, true);
		}
	} else {
		newSpeed = getMaxSpeed(id, weapon);
	}

	sh_debug_message(id, 10, "Checking Speeds - Old: %f - New: %f", oldSpeed, newSpeed);

	// OK SET THE SPEED
	if (newSpeed != oldSpeed) {
		switch (newSpeed) {
			case -1.0: {
				if (checkDefault) {
					if (id == sh_get_vip_id())
						//Still need to check this because vip speed may not be blocked
						//and user may not have a hero with current weapon speed 
						set_user_maxspeed(id, 227.0);
					else
						// Set default weapon speed
						// Do not need to check for scoped sniper rifles as getMaxSpeed will
						// return that value since heroes can not effect scoped sniper rifles.
						set_user_maxspeed(id, sh_get_weapon_speed(weapon));
				}
			}
			default: {
				set_user_maxspeed(id, newSpeed);
				sh_debug_message(id, 5, "Setting Speed To %f", newSpeed);
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
Float:getMaxSpeed(id, weapon)
{
	static heroName[25];
	static Float:returnSpeed, Float:heroSpeed, x, i;
	static playerPowerCount, heroIndex, heroWeapon;
	returnSpeed = -1.0;
	playerPowerCount = sh_get_user_powers(id);

	for (x = 1; x <= playerPowerCount; x++) {
		heroIndex = sh_get_user_hero(id, x);
		
		if (-1 < heroIndex < gSuperHeroCount) {
			heroSpeed = gHeroMaxSpeed[heroIndex];
			if (heroSpeed <= 0.0)
				continue;
			
			for (i = CSW_NONE; i <= CSW_LAST_WEAPON; i++) {
				heroWeapon = gHeroSpeedWeapons[heroIndex][i];

				//Stop checking, end of list
				if (i != CSW_NONE && heroWeapon == CSW_NONE)
					break;

				sh_get_hero_name(heroIndex, heroName, charsmax(heroName));
				sh_debug_message(id, 5, "Looking for Speed Functions - %s, %d, %d", heroName, heroWeapon, weapon);

				//If 0 or current weapon check max
				if (heroWeapon == CSW_NONE || heroWeapon == weapon) {
					returnSpeed = floatmax(returnSpeed, heroSpeed);
					break;
				}
			}
		}
	}

	return returnSpeed;
}
//----------------------------------------------------------------------------------------------
@Task_StunCheck()
{
	static players[32], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; i++) {
		player = players[i];

		// Switches are faster but we don't want to do anything with -1
		switch (gPlayerStunTimer[player]) {
			case -1: { /*Do nothing*/ }
			case 0: {
				gPlayerStunTimer[player] = -1;
				setSpeedPowers(player, true);
			}
			default: {
				gPlayerStunTimer[player]--;
				gPlayerStunSpeed[player] = get_user_maxspeed(player); //is this really needed?
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
@Task_SetServerMaxSpeed()
{
	new maxSpeed = 320; // Server Default
	for (new x = 0; x < gSuperHeroCount; x++) {
		if (gHeroMaxSpeed[x] != 0)
			maxSpeed = max(maxSpeed, floatround(gHeroMaxSpeed[x], floatround_ceil));
	}

	// Only set if below required speed to avoid setting lower then server op may want
	if (get_pcvar_num(sv_maxspeed) < maxSpeed) {
		sh_debug_message(0, 1, "Setting server CVAR sv_maxspeed to: %d", maxSpeed);
		set_pcvar_num(sv_maxspeed, maxSpeed);
	}
}
//----------------------------------------------------------------------------------------------
