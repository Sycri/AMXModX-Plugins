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
#include <sh_core_objectives>

#pragma semicolon 1

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

new gSuperHeroCount;

new Float:gHeroMinGravity[SH_MAXHEROS];
new gHeroGravityWeapons[SH_MAXHEROS]; // bit-field of weapons
new bool:gFreezeTime;

new CvarDebugMessages;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Gravity", SH_VERSION_STR, SH_AUTHOR_STR);
	
	register_event_ex("HLTV", "@Event_HLTV", RegisterEvent_Global, "1=0", "2=0"); // New Round
	register_logevent("@LogEvent_RoundStart", 2, "1=Round_Start");

	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);
	
	bind_pcvar_num(get_cvar_pointer("sh_debug_messages"), CvarDebugMessages);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_gravity");
	
	register_native("sh_set_hero_grav", "@Native_SetHeroGravity");
	register_native("sh_reset_min_gravity", "@Native_ResetMinGravity");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroMinGravity[heroID] > 0.0)
		resetMinGravity(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	setGravityPowers(id);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_grav(heroID, pcvarGravity, const weapons[] = {0}, numofwpns = 1)
@Native_SetHeroGravity()
{
	new heroIndex = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroIndex < 0 || heroIndex >= sh_get_num_heroes())
		return;

	new weapons = get_param(3);

	bind_pcvar_float(get_param(2), gHeroMinGravity[heroIndex]); // pCVAR expected!
	gHeroGravityWeapons[heroIndex] = weapons; // Bit-field expected!

	sh_debug_message(0, 3, "Set Min Gravity -> HeroID: %d - Gravity: %.3f - Weapon(s): %d", heroIndex, gHeroMinGravity[heroIndex], weapons);
}
//----------------------------------------------------------------------------------------------
//native sh_reset_min_gravity(id)
@Native_ResetMinGravity()
{
	resetMinGravity(get_param(1));
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
setHamGravityPowers(index)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(index) || gFreezeTime || !sh_user_is_loaded(index))
		return;

	if (index == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_GRAVITY)
		return;

	static Float:heroGravity;
	heroGravity = getMinGravity(index, cs_get_user_weapon(index));

	set_user_gravity(index, heroGravity);
	sh_debug_message(index, 5, "Setting Gravity To %f", heroGravity);
}
//----------------------------------------------------------------------------------------------
resetMinGravity(id)
{
	if (!sh_is_active())
		return;
		
	if (!is_user_alive(id))
		return;
		
	new Float:newGravity = getMinGravity(id, cs_get_user_weapon(id));
	if (get_user_gravity(id) != newGravity)
		// Set to 1.0 or the next lowest Gravity
		set_user_gravity(id, newGravity);
}
//----------------------------------------------------------------------------------------------
setGravityPowers(id)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(id) || gFreezeTime || !sh_user_is_loaded(id))
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
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_GRAVITY)
		return 1.0;
		
	static heroName[25];
	static Float:returnGravity, Float:heroMinGravity, i;
	static playerPowerCount, heroIndex;
	returnGravity = 1.0;
	playerPowerCount = sh_get_user_powers(id);
	
	for (i = 1; i <= playerPowerCount; ++i) {
		heroIndex = sh_get_user_hero(id, i);
		
		if (-1 < heroIndex < gSuperHeroCount) {
			heroMinGravity = gHeroMinGravity[heroIndex];
			if (heroMinGravity <= 0.0)
				continue;

			sh_get_hero_name(heroIndex, heroName, charsmax(heroName));
			sh_debug_message(id, 5, "Looking for Gravity Functions - %s, %d, %d", heroName, gHeroGravityWeapons[heroIndex], weapon);

			if (gHeroGravityWeapons[heroIndex] & (1 << weapon))
				returnGravity = floatmin(returnGravity, heroMinGravity);
		}
	}
	
	return returnGravity;
}
//----------------------------------------------------------------------------------------------
