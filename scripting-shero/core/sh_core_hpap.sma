/* AMX Mod X script.
*
*	[SH] Core: HP/AP (sh_core_hpap.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <engine>
#include <fun>
#include <cstrike>
#include <sh_core_main>

#pragma semicolon 1

#define is_user_valid(%1) (1 <= %1 <= MaxClients)

new gSuperHeroCount;

new gHeroMaxHealth[SH_MAXHEROS];
new gHeroMaxArmor[SH_MAXHEROS];

// Player bool variables (using bit-fields for lower memory footprint and better CPU performance)
#define flag_get(%1,%2)			(%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2)	(flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2)			%1 |= (1 << (%2 & 31))
#define flag_clear(%1,%2)		%1 &= ~(1 << (%2 & 31))

new gBlockHealth;
new gBlockArmor;
new gBlockAddHP;
new gBlockAddAP;

new gMaxHealth[MAX_PLAYERS + 1];
new gMaxArmor[MAX_PLAYERS + 1];
new gTempHealth[MAX_PLAYERS + 1];
new gTempArmor[MAX_PLAYERS + 1];

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: HP/AP", SH_VERSION_STR, SH_AUTHOR_STR);

	// Fixes bug with HUD showing 0 health and reversing keys
	register_message(get_user_msgid("Health"), "@Message_Health");
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_hpap");
	
	register_native("sh_set_hero_hpap", "@Native_SetHeroHpAp");

	register_native("sh_add_hp", "@Native_AddHP");
	register_native("sh_add_ap", "@Native_AddAP");

	register_native("sh_block_add_hp", "@Native_BlockAddHP");
	register_native("sh_block_add_ap", "@Native_BlockAddAP");
	register_native("sh_block_hero_hp", "@Native_BlockHeroHP");
	register_native("sh_block_hero_ap", "@Native_BlockHeroAP");

	register_native("sh_get_max_hp", "@Native_GetMaxHP");
	register_native("sh_get_max_ap", "@Native_GetMaxAP");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	flag_clear(gBlockHealth, id);
	flag_clear(gBlockArmor, id);
	flag_clear(gBlockAddHP, id);
	flag_clear(gBlockAddAP, id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (!is_user_alive(id))
		return;

	switch (mode) {
		case SH_HERO_ADD: {
			if (gHeroMaxHealth[heroID] != 0)
				setHealthPowers(id);

			if (gHeroMaxArmor[heroID] != 0)
				setArmorPowers(id, false);
		}
		case SH_HERO_DROP: {
			if (gHeroMaxHealth[heroID] != 0) {
				new newHealth = getMaxHealth(id);

				if (get_user_health(id) > newHealth) {
					// Assume some damage for doing this?
					// Don't want players picking Superman let's say then removing his power - and trying to keep the HPs
					// If they do that - feel free to lose some hps
					// Also - Superman starts with around 150 Person could take some damage (i.e. reduced to 110 )
					// but then clear powers and start at 100 - like 40 free hps for doing that, trying to avoid exploits
					set_user_health(id, newHealth - (newHealth / 4));
				}
			}

			if (gHeroMaxArmor[heroID] != 0) {
				new newArmor = getMaxArmor(id);
				new CsArmorType:armorType;

				if (cs_get_user_armor(id, armorType) > newArmor)
					// Remove Armor for doing this
					cs_set_user_armor(id, newArmor, armorType);
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	setHealthPowers(id);
	setArmorPowers(id, true);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_hpap(heroID, pcvarHealth = 0, pcvarArmor = 0)
@Native_SetHeroHpAp(plugin_id, num_params)
{
	new heroID = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroID < 0 || heroID >= sh_get_num_heroes()) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Hero ID (%d)", heroID);
		return false;
	}

	new pcvarMaxHealth = get_param(2);
	new pcvarMaxArmor = get_param(3);

	sh_debug_message(0, 3, "Set Max HP/AP -> HeroID: %d - %d - %d", heroID, pcvarMaxHealth ? get_pcvar_num(pcvarMaxHealth) : 0, pcvarMaxArmor ? get_pcvar_num(pcvarMaxArmor) : 0);

	// Avoid setting if 0 because backward compatibility method would overwrite value
	if (pcvarMaxHealth != 0)
		bind_pcvar_num(pcvarMaxHealth, gHeroMaxHealth[heroID]);
	if (pcvarMaxArmor != 0)
		bind_pcvar_num(pcvarMaxArmor, gHeroMaxArmor[heroID]);
	
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_add_hp(id, hitPoints, maxHealth = 0)
@Native_AddHP(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_alive(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return 0;
	}

	if (flag_get_boolean(gBlockAddHP, id))
		return 0;

	new hitPoints = get_param(2);

	if (hitPoints == 0)
		return 0;

	new maxHealth = get_param(3);

	if (maxHealth == 0)
		maxHealth = gMaxHealth[id];

	new currentHealth = get_user_health(id);

	if (currentHealth < maxHealth) {
		new newHealth = min((currentHealth + hitPoints), maxHealth);
		set_user_health(id, newHealth);
		return newHealth - currentHealth;
	}

	return 0;
}
//----------------------------------------------------------------------------------------------
//native sh_add_ap(id, armorPoints, maxArmor = 0)
@Native_AddAP(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_alive(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return 0;
	}

	if (flag_get_boolean(gBlockAddAP, id))
		return 0;

	new armorPoints = get_param(2);

	if (armorPoints == 0)
		return 0;

	new maxArmor = get_param(3);

	if (maxArmor == 0)
		maxArmor = gMaxArmor[id];

	new CsArmorType:armorType;
	new currentArmor = cs_get_user_armor(id, armorType);

	if (currentArmor < maxArmor) {
		if (!currentArmor)
			armorType = CS_ARMOR_VESTHELM;

		new newArmor = min((currentArmor + armorPoints), maxArmor);
		cs_set_user_armor(id, newArmor, armorType);
		return newArmor - currentArmor;
	}

	return 0;
}
//----------------------------------------------------------------------------------------------
//native sh_block_add_hp(id, bool:block = true)
@Native_BlockAddHP(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	if (get_param(2))
		flag_set(gBlockAddHP, id);
	else
		flag_clear(gBlockAddHP, id);
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_block_add_ap(id, bool:block = true)
@Native_BlockAddAP(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	if (get_param(2))
		flag_set(gBlockAddAP, id);
	else
		flag_clear(gBlockAddAP, id);
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_block_hero_hp(id, bool:block = true, maxHealth = 0)
@Native_BlockHeroHP(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	if (get_param(2)) {
		flag_set(gBlockHealth, id);
		gTempHealth[id] = max(0, get_param(3));
	} else {
		flag_clear(gBlockHealth, id);
	}
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_block_hero_ap(id, bool:block = true, maxArmor = 0)
@Native_BlockHeroAP(plugin_id, num_params)
{
	new id = get_param(1);

	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return false;
	}

	if (get_param(2)) {
		flag_set(gBlockArmor, id);
		gTempArmor[id] = max(0, get_param(3));
	} else {
		flag_clear(gBlockArmor, id);
	}
	return true;
}
//----------------------------------------------------------------------------------------------
//native sh_get_max_hp(id)
@Native_GetMaxHP(plugin_id, num_params)
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return 0;
	}

	return gMaxHealth[id];
}
//----------------------------------------------------------------------------------------------
//native sh_get_max_ap(id)
@Native_GetMaxAP(plugin_id, num_params)
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (!is_user_valid(id)) {
		log_error(AMX_ERR_NATIVE, "[SH] Invalid Player (%d)", id);
		return 0;
	}

	return gMaxArmor[id];
}
//----------------------------------------------------------------------------------------------
@Message_Health(msgid, dest, id)
{
	// Run even when mod is off, not a big deal
	if (!is_user_alive(id))
		return;

	// Fixes bug with health multiples of 256 showing 0 HP on HUD causes keys to be reversed
	static hp;
	hp = get_msg_arg_int(1);

	if (hp % 256 == 0)
		set_msg_arg_int(1, ARG_BYTE, ++hp);
}
//----------------------------------------------------------------------------------------------
setHealthPowers(id)
{
	if (!sh_is_active())
		return;
	
	if (!sh_user_is_loaded(id))
		return;

	new oldHealth = get_user_health(id);
	new newHealth = getMaxHealth(id);

	// Can't get health in the middle of a round UNLESS you didn't get shot...
	if (oldHealth < newHealth && oldHealth >= 100) {
		set_user_health(id, newHealth);

		sh_debug_message(id, 5, "Setting Health to %d", newHealth);
	}
}
//----------------------------------------------------------------------------------------------
setArmorPowers(id, bool:resetArmor)
{
	if (!sh_is_active())
		return;

	if (!sh_user_is_loaded(id))
		return;

	new oldArmor = cs_get_user_armor(id);
	new newArmor = getMaxArmor(id);

	// Little check for armor system
	if ((oldArmor != 0 || oldArmor >= newArmor) && (newArmor == 0 || !resetArmor))
		return;

	// Set the armor to the correct value
	cs_set_user_armor(id, newArmor, CS_ARMOR_VESTHELM);

	sh_debug_message(id, 5, "Setting Armor to %d", newArmor);
}
//----------------------------------------------------------------------------------------------
getMaxHealth(id)
{
	static returnHealth;

	if (flag_get_boolean(gBlockHealth, id)) {
		returnHealth = gTempHealth[id] == 0 ? 100 : gTempHealth[id];

		// Other plugins might use this, even maps
		entity_set_float(id, EV_FL_max_health, float(returnHealth));
		return gMaxHealth[id] = returnHealth;
	}

	static i, playerPowerCount, heroID, heroHealth;
	returnHealth = 100;
	playerPowerCount = sh_get_user_powers(id);

	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);

		if (-1 < heroID < gSuperHeroCount) {
			heroHealth = gHeroMaxHealth[heroID];
			if (!heroHealth)
				continue;

			returnHealth = max(returnHealth, heroHealth);
		}
	}
	
	// Other plugins might use this, even maps
	entity_set_float(id, EV_FL_max_health, float(returnHealth));
	
	return gMaxHealth[id] = returnHealth;
}
//----------------------------------------------------------------------------------------------
getMaxArmor(id)
{
	if (flag_get_boolean(gBlockArmor, id))
		return gMaxArmor[id] = gTempArmor[id];
		
	static i, playerPowerCount, returnArmor, heroID, heroArmor;
	returnArmor = 0;
	playerPowerCount = sh_get_user_powers(id);
	
	for (i = 1; i <= playerPowerCount; ++i) {
		heroID = sh_get_user_hero(id, i);

		if (-1 < heroID < gSuperHeroCount) {
			heroArmor = gHeroMaxArmor[heroID];
			if (!heroArmor)
				continue;

			returnArmor = max(returnArmor, heroArmor);
		}
	}
	
	return gMaxArmor[id] = returnArmor;
}
//----------------------------------------------------------------------------------------------
