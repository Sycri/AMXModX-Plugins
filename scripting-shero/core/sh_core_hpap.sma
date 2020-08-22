/* AMX Mod X script.
*
*   [SH] Core: HP/AP (sh_core_hpap.sma)
*
*****************************************************************************/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <sh_core_main>
#include <sh_core_objectives>

#pragma semicolon 1

new gSuperHeroCount;

new gHeroMaxHealth[SH_MAXHEROS];
new gHeroMaxArmor[SH_MAXHEROS];

new gMaxHealth[MAX_PLAYERS + 1];
new gMaxArmor[MAX_PLAYERS + 1];

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
	register_native("sh_get_max_hp", "@Native_GetMaxHP");
	register_native("sh_get_max_ap", "@Native_GetMaxAP");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
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
@Native_SetHeroHpAp()
{
	new heroIndex = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroIndex < 0 || heroIndex >= sh_get_num_heroes())
		return;

	new pcvarMaxHealth = get_param(2);
	new pcvarMaxArmor = get_param(3);

	sh_debug_message(0, 3, "Set Max HP/AP -> HeroID: %d - %d - %d", heroIndex, pcvarMaxHealth ? get_pcvar_num(pcvarMaxHealth) : 0, pcvarMaxArmor ? get_pcvar_num(pcvarMaxArmor) : 0);

	// Avoid setting if 0 because backward compatibility method would overwrite value
	if (pcvarMaxHealth != 0)
		bind_pcvar_num(pcvarMaxHealth, gHeroMaxHealth[heroIndex]);
	if (pcvarMaxArmor != 0)
		bind_pcvar_num(pcvarMaxArmor, gHeroMaxArmor[heroIndex]);
}
//----------------------------------------------------------------------------------------------
//native sh_get_max_hp(id)
@Native_GetMaxHP()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return 0;

	return gMaxHealth[id];
}
//----------------------------------------------------------------------------------------------
//native sh_get_max_ap(id)
@Native_GetMaxAP()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return 0;

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
	static returnHealth, x;
	returnHealth = 100;

	if (!(id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_HEALTH)) {
		static heroIndex, playerPowerCount, heroHealth;
		playerPowerCount = sh_get_user_powers(id);

		for (x = 1; x <= playerPowerCount; x++) {
			heroIndex = sh_get_user_hero(id, x);
			
			if (-1 < heroIndex < gSuperHeroCount) {
				heroHealth = gHeroMaxHealth[heroIndex];
				if (!heroHealth)
					continue;

				returnHealth = max(returnHealth, heroHealth);
			}
		}
	}
	
	// Other plugins might use this, even maps
	set_pev(id, pev_max_health, returnHealth);
	
	return gMaxHealth[id] = returnHealth;
}
//----------------------------------------------------------------------------------------------
getMaxArmor(id)
{
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_ARMOR)
		return gMaxArmor[id] = 200;
		
	static heroIndex, returnArmor, x, playerPowerCount, heroArmor;
	returnArmor = 0;
	playerPowerCount = sh_get_user_powers(id);
	
	for (x = 1; x <= playerPowerCount; x++) {
		heroIndex = sh_get_user_hero(id, x);

		if (-1 < heroIndex < gSuperHeroCount) {
			heroArmor = gHeroMaxArmor[heroIndex];
			if (!heroArmor)
				continue;

			returnArmor = max(returnArmor, heroArmor);
		}
	}
	
	return gMaxArmor[id] = returnArmor;
}
//----------------------------------------------------------------------------------------------