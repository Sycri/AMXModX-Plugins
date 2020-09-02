/* AMX Mod X script.
*
*	[SH] Core: Gravity (sh_core_gravity.sma)
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

// Player bool variables (using bit-fields for lower memory footprint and better CPU performance)
#define flag_get(%1,%2)			(%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2)	(flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2)			%1 |= (1 << (%2 & 31))
#define flag_clear(%1,%2)		%1 &= ~(1 << (%2 & 31))

new gBlockGravity;

new Float:gHeroMinGravity[SH_MAXHEROS];
new gHeroGravityWeapons[SH_MAXHEROS]; // bit-field of weapons
new bool:gFreezeTime;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Gravity", SH_VERSION_STR, SH_AUTHOR_STR);
	
	register_event_ex("HLTV", "@Event_HLTV", RegisterEvent_Global, "1=0", "2=0"); // New Round
	register_logevent("@LogEvent_RoundStart", 2, "1=Round_Start");

	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_gravity");
	
	register_native("sh_set_hero_grav", "@Native_SetHeroGravity");
	register_native("sh_block_hero_grav", "@Native_BlockHeroGravity");
	register_native("sh_reset_min_gravity", "@Native_ResetMinGravity");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	flag_clear(gBlockGravity, id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroMinGravity[heroID] > 0.0 && is_user_alive(id))
		resetMinGravity(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (!gFreezeTime)
		setGravityPowers(id);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_grav(heroID, pcvarGravity, const weapons = CSW_ALL_WEAPONS)
@Native_SetHeroGravity(plugin_id, num_params)
{
	new heroID = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroID < 0 || heroID >= sh_get_num_heroes()) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Hero ID (%d)", heroID);
		return false;
	}

	new weapons = get_param(3);

	bind_pcvar_float(get_param(2), gHeroMinGravity[heroID]); // pCVAR expected!
	gHeroGravityWeapons[heroID] = weapons; // Bit-field expected!

	sh_debug_message(0, 3, "Set Min Gravity -> HeroID: %d - Gravity: %.3f - Weapon(s): %d", heroID, gHeroMinGravity[heroID], weapons);
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_block_hero_grav(id, bool:block = true)
@Native_BlockHeroGravity(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	if (get_param(2))
		flag_set(gBlockGravity, id);
	else
		flag_clear(gBlockGravity, id);
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_reset_min_gravity(id)
@Native_ResetMinGravity(plugin_id, num_params)
{
	if (!sh_is_active())
		return false;

	new id = get_param(1);
		
	if (!is_user_alive(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}
	
	return resetMinGravity(id);
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

	if (!sh_is_active())
		return;

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		setGravityPowers(player);
	}
}
//----------------------------------------------------------------------------------------------
@Forward_AddPlayerItem_Post(id)
{
	setHamGravityPowers(id);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_Player_ResetMaxSpeed_Post(id)
{
	setHamGravityPowers(id);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
setHamGravityPowers(id)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(id) || gFreezeTime || !sh_user_is_loaded(id))
		return;

	if (flag_get_boolean(gBlockGravity, id))
		return;

	static Float:heroGravity;
	heroGravity = getMinGravity(id, cs_get_user_weapon(id));

	set_user_gravity(id, heroGravity);
	sh_debug_message(id, 5, "Setting Gravity To %f", heroGravity);
}
//----------------------------------------------------------------------------------------------
bool:resetMinGravity(id)
{
	new Float:newGravity = getMinGravity(id, cs_get_user_weapon(id));
	if (get_user_gravity(id) != newGravity) {
		// Set to 1.0 or the next lowest Gravity
		set_user_gravity(id, newGravity);
		return true;
	}

	return false;
}
//----------------------------------------------------------------------------------------------
setGravityPowers(id)
{
	if (!is_user_alive(id) || !sh_user_is_loaded(id))
		return;

	new Float:oldGravity = 1.0;
	new Float:newGravity = getMinGravity(id, cs_get_user_weapon(id));

	if (oldGravity != newGravity) {
		sh_debug_message(id, 5, "Setting Gravity to %f", newGravity);
		set_user_gravity(id, newGravity);
	}
}
//----------------------------------------------------------------------------------------------
Float:getMinGravity(id, weapon)
{
	if (flag_get_boolean(gBlockGravity, id))
		return 1.0;
		
	static heroName[25];
	static Float:returnGravity, Float:heroMinGravity, i;
	static playerPowerCount, heroID;
	returnGravity = 1.0;
	playerPowerCount = sh_get_user_powers(id);
	
	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);
		
		if (-1 < heroID < gSuperHeroCount) {
			heroMinGravity = gHeroMinGravity[heroID];
			if (heroMinGravity <= 0.0)
				continue;

			sh_get_hero_name(heroID, heroName, charsmax(heroName));
			sh_debug_message(id, 5, "Looking for Gravity Functions - %s, %d, %d", heroName, gHeroGravityWeapons[heroID], weapon);

			if (gHeroGravityWeapons[heroID] & (1 << weapon))
				returnGravity = floatmin(returnGravity, heroMinGravity);
		}
	}
	
	return returnGravity;
}
//----------------------------------------------------------------------------------------------
