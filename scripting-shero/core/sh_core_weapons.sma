/* AMX Mod X script.
*
*	[SH] Core: Weapons (sh_core_weapons.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_objectives>
#include <sh_core_weapons_const>

#pragma semicolon 1

new gSuperHeroCount;

new Float:gHeroMaxDamageMult[SH_MAXHEROS][31];

new Float:gReloadTime[MAX_PLAYERS + 1];
new bool:gMapBlockWeapons[31]; //1-30 CSW_ constants

new CvarReloadMode;
new CvarDebugMessages;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Weapons", SH_VERSION_STR, SH_AUTHOR_STR);

	RegisterHamPlayer(Ham_TakeDamage, "@Forward_Player_TakeDamage_Pre");

	bind_pcvar_num(create_cvar("sh_reloadmode", "1"), CvarReloadMode);
	
	bind_pcvar_num(get_cvar_pointer("sh_debug_messages"), CvarDebugMessages);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_weapons");
	
	register_native("sh_set_hero_dmgmult", "@Native_SetHeroDamageMultiplier");
	register_native("sh_drop_weapon", "@Native_DropWeapon");
	register_native("sh_give_weapon", "@Native_GiveWeapon");
	register_native("sh_give_item", "@Native_GiveItem");
	register_native("sh_reload_ammo", "@Native_ReloadAmmo");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();

	// Check to see if we need to block weapon giving heroes
	giveWeaponConfig();
}
//----------------------------------------------------------------------------------------------
// This will set the sh_give_weapon blocks for the map
giveWeaponConfig()
{
	// Set Up Config Files
	new shConfigDir[128];
	get_configsdir(shConfigDir, charsmax(shConfigDir));
	add(shConfigDir, charsmax(shConfigDir), "/shero", 6);

	// Attempt to create directory if it does not exist
	if (!dir_exists(shConfigDir))
		mkdir(shConfigDir);

	new wpnBlockFile[128];
	formatex(wpnBlockFile, charsmax(wpnBlockFile), "%s/shweapon.cfg", shConfigDir);

	if (!file_exists(wpnBlockFile)) {
		//Create the file if it doesn't exist
		createGiveWeaponConfig(wpnBlockFile);
		return;
	}

	new blockWpnFile = fopen(wpnBlockFile, "rt");

	if (!blockWpnFile) {
		sh_debug_message(0, 0, "Failed to open shweapon.cfg, please verify file/folder permissions");
		return;
	}

	new data[512], mapName[32], blockMapName[32];
	new blockWeapons[512], weapon[16], weaponName[32];
	new checkLength, i, weaponID;

	get_mapname(mapName, charsmax(mapName));

	while (!feof(blockWpnFile)) {
		fgets(blockWpnFile, data, charsmax(data));
		trim(data);

		//Comments or blank skip it
		switch (data[0]) {
			case '^0', '^n', ';', '/', '\', '#': continue;
		}

		argbreak(data, blockMapName, charsmax(blockMapName), blockWeapons, charsmax(blockWeapons));

		//all maps or check for something more specific?
		if (blockMapName[0] != '*') {

			//How much of the map name do we check?
			checkLength = strlen(blockMapName);

			if (blockMapName[checkLength-1] == '*')
				--checkLength;
			else //Largest length between the 2, do this because of above check
				checkLength = max(checkLength, strlen(mapName));

			//Keep checking or did we find the map?
			if (!equali(mapName, blockMapName, checkLength))
				continue;
		}

		//If gotten this far a map has been found
		remove_quotes(blockWeapons);

		//Idiot check, make sure weapon names are lowercase before going further
		strtolower(blockWeapons);

		while (blockWeapons[0] != '^0') {
			//trim any spaces left over especially from strtok
			trim(blockWeapons);
			strtok(blockWeapons, weapon, charsmax(weapon), blockWeapons, 415, ',', 1);

			if (equal(weapon, "all")) {
				//Set all 1-30 CSW_ constants
				for (i = CSW_P228; i <= CSW_P90; ++i)
					gMapBlockWeapons[i] = gMapBlockWeapons[i] ? false : true;
			} else {
				//Set named weapon
				formatex(weaponName, charsmax(weaponName), "weapon_%s", weapon);
				weaponID = get_weaponid(weaponName);

				if (!weaponID) {
					sh_debug_message(0, 0, "Invalid block weapon name ^"%s^" for entry ^"%s^" check shweapon.cfg", weapon, blockMapName);
					continue;
				}

				gMapBlockWeapons[weaponID] = gMapBlockWeapons[weaponID] ? false : true;
			}
		}

		// Map found stop looking for more
		break;
	}
	fclose(blockWpnFile);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_dmgmult(heroID, pcvarDamage, const weaponID = 0)
@Native_SetHeroDamageMultiplier()
{
	new heroIndex = get_param(1);

	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroIndex < 0 || heroIndex >= sh_get_num_heroes())
		return;

	new pcvarDamageMult = get_param(2);
	new weaponID = get_param(3);

	sh_debug_message(0, 3, "Set Damage Multiplier -> HeroID: %d - Multiplier: %.3f - Weapon: %d", heroIndex, get_pcvar_float(pcvarDamageMult), weaponID);

	bind_pcvar_float(pcvarDamageMult, gHeroMaxDamageMult[heroIndex][weaponID]); // pCVAR expected!
}
//----------------------------------------------------------------------------------------------
//native sh_drop_weapon(id, weaponID, bool:remove = false)
@Native_DropWeapon()
{
	dropWeapon(get_param(1), get_param(2), get_param(3) ? true : false);
}
//---------------------------------------------------------------------------------------------
dropWeapon(id, weaponID, bool:remove)
{
	if (!sh_is_active())
		return;

	if (!is_user_alive(id))
		return;

	// If VIPs are not allowed other weapons, protect them from losing what they have
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_WEAPONS)
		return;

	if (!user_has_weapon(id, weaponID))
		return;

	new slot = sh_get_weapon_slot(weaponID);
	if (slot == 1 || slot == 2 || slot == 5) {
		//Don't drop/remove the main c4
		if (weaponID == CSW_C4 && is_valid_ent(sh_get_c4_id()) && id == entity_get_edict2(sh_get_c4_id(), EV_ENT_owner))
			return;

		static weaponName[32];
		get_weaponname(weaponID, weaponName, charsmax(weaponName));

		engclient_cmd(id, "drop", weaponName);

		if (!remove)
			return;

		new Float:weaponVel[3];
		new weaponBox = -1;

		while ((weaponBox = cs_find_ent_by_owner(weaponBox, "weaponbox", id)) > 0) {
			// Skip anything not owned by this client
			if (!is_valid_ent(weaponBox))
				continue;

			// If Velocities are all zero its on the ground already and should stay there
			entity_get_vector(weaponBox, EV_VEC_velocity, weaponVel);
			if (weaponVel[0] == 0.0 && weaponVel[1] == 0.0 && weaponVel[2] == 0.0)
				continue;

			// Forcing a think cleanly removes weaponbox and it's contents
			call_think(weaponBox);
		}
	}
}
//---------------------------------------------------------------------------------------------
//native sh_give_weapon(id, weaponID, bool:switchTo = false)
@Native_GiveWeapon()
{
	return giveWeapon(get_param(1), get_param(2), get_param(3) ? true : false);
}
//---------------------------------------------------------------------------------------------
giveWeapon(id, weaponID, bool:switchTo)
{
	if (!sh_is_active())
		return 0;

	if (!is_user_alive(id))
		return 0;

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_WEAPONS)
		return 0;

	if (weaponID < CSW_P228 || weaponID > CSW_P90)
		return 0;

	if (gMapBlockWeapons[weaponID])
		return 0;

	if (!user_has_weapon(id, weaponID)) {
		static weaponName[32];
		get_weaponname(weaponID, weaponName, charsmax(weaponName));

		new itemID = give_item(id, weaponName);

		// Switch to the given weapon?
		if (switchTo)
			engclient_cmd(id, weaponName);

		return itemID;
	}

	return 0;
}
//---------------------------------------------------------------------------------------------
//native sh_give_item(id, const itemName[], bool:switchTo = false)
@Native_GiveItem()
{
	if (!sh_is_active())
		return 0;

	new id = get_param(1);

	if (!is_user_alive(id))
		return 0;

	new itemName[32], itemID;
	get_array(2, itemName, charsmax(itemName));

	if (equal(itemName, "weapon", 6)) {
		if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_WEAPONS)
			return 0;

		new weaponID = get_weaponid(itemName);
		if (weaponID) {
			//It's a weapon see if it is blocked or user already has it
			if (gMapBlockWeapons[weaponID] || user_has_weapon(id, weaponID))
				return 0;
		}

		itemID = give_item(id, itemName);

		if (get_param(3))
			engclient_cmd(id, itemName);
	} else {
		itemID = give_item(id, itemName);
	}

	return itemID;
}
//----------------------------------------------------------------------------------------------
//native sh_reload_ammo(id, mode = 0)
@Native_ReloadAmmo()
{
	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	// re-entrency check
	new Float:gametime = get_gametime();
	if (gametime - gReloadTime[id] < 0.5)
		return;
	gReloadTime[id] = gametime;

	new clip, ammo;
	new wpnID = get_user_weapon(id, clip, ammo);
	new wpnSlot = sh_get_weapon_slot(wpnID);

	if (wpnSlot != 1 && wpnSlot != 2)
		return;

	new mode = get_param(2);

	if (mode == 0) {
		// Server decides what mode to use
		mode = CvarReloadMode;

		if (!mode)
			return;
	}

	switch (mode) {
		// No reload, reset max clip (most common)
		case 1: {
			if (clip != 0)
				return;

			new weaponEnt = cs_get_user_weapon_entity(id);
			if (!weaponEnt)
				return;

			cs_set_weapon_ammo(weaponEnt, sh_get_max_clipammo(wpnID));
		}
		// Requires reload, but reset max backpack ammo
		case 2: {
			new maxbpammo = sh_get_max_bpammo(wpnID);
			if (ammo < maxbpammo)
				cs_set_user_bpammo(id, wpnID, maxbpammo);
		}
		// Drop weapon and get a new one with full clip
		case 3: {
			if (clip != 0)
				return;

			new idSilence, idBurst;
			if (wpnID == CSW_M4A1 || wpnID == CSW_USP) {
				new weaponEnt = -1;
				new wpn[32];
				get_weaponname(wpnID, wpn, charsmax(wpn));

				while ((weaponEnt = find_ent_by_class(weaponEnt, wpn)) != 0) {
					if (id == entity_get_edict2(weaponEnt, EV_ENT_owner)) {
						idSilence = cs_get_weapon_silen(weaponEnt);
						break;
					}
				}
			} else if (wpnID == CSW_FAMAS || wpnID == CSW_GLOCK18) {
				new weaponEnt = -1;
				new wpn[32];
				get_weaponname(wpnID, wpn, charsmax(wpn));

				while ((weaponEnt = find_ent_by_class(weaponEnt, wpn)) != 0) {
					if (id == entity_get_edict2(weaponEnt, EV_ENT_owner)) {
						idBurst = cs_get_weapon_burst(weaponEnt);
						break;
					}
				}
			}

			dropWeapon(id, wpnID, true);

			new entityID = giveWeapon(id, wpnID, true);

			if (idSilence)
				cs_set_weapon_silen(entityID, idSilence, 0);
			else if (idBurst)
				cs_set_weapon_burst(entityID, idBurst);
		}
	}
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (damage <= 0.0)
		return HAM_IGNORED;

	if (!is_user_connected(attacker) || !is_user_alive(victim))
		return HAM_IGNORED;

	// if (victim != attacker && cs_get_user_team(victim) == cs_get_user_team(attacker) && !CvarFreeForAll)
		// return HAM_IGNORED;

	if (attacker == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_EXTRADMG)
		return HAM_IGNORED;

	new weaponID;
	if (damagebits & DMG_GRENADE)
		weaponID = CSW_HEGRENADE;
	else if (damagebits & DMG_BULLET && inflictor == attacker)
		//includes knife and any other weapon
		weaponID = get_user_weapon(attacker);

	//Damage not from a CS weapon
	if (!weaponID)
		return HAM_IGNORED;

	new Float:dmgmult = getMaxDamageMult(attacker, weaponID);

	//Damage is not increased damage
	if (dmgmult <= 1.0)
		return HAM_IGNORED;

	SetHamParamFloat(4, damage * dmgmult);
	return HAM_HANDLED;
}
//----------------------------------------------------------------------------------------------
Float:getMaxDamageMult(id, weaponID)
{
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_EXTRADMG)
		return 1.0;

	static Float:returnDamageMult, Float:heroDamageMult, i;
	static playerPowerCount, heroIndex;
	returnDamageMult = 1.0;
	playerPowerCount = sh_get_user_powers(id);

	for (i = 1; i <= playerPowerCount; ++i) {
		heroIndex = sh_get_user_hero(id, i);

		if (-1 < heroIndex < gSuperHeroCount) {
			// Check hero for all weapons wildcard first
			heroDamageMult = gHeroMaxDamageMult[heroIndex][0];

			if (heroDamageMult <= 1.0) {
				// Check hero for weapon that was passed in
				heroDamageMult = gHeroMaxDamageMult[heroIndex][weaponID];

				if (heroDamageMult <= 1.0)
					continue;
			}

			returnDamageMult = floatmax(returnDamageMult, heroDamageMult);
		}
	}

	return returnDamageMult;
}
//----------------------------------------------------------------------------------------------
createGiveWeaponConfig(const wpnBlockFile[])
{
	new blockWpnFile = fopen(wpnBlockFile, "wt");
	if (!blockWpnFile) {
		sh_debug_message(0, 0, "Failed to create shweapon.cfg, please verify file/folder permissions");
		return;
	}

	fputs(blockWpnFile, "// Use this file to block SuperHero from giving weapons by map. This only blocks shmod from giving weapons.^n");
	fputs(blockWpnFile, "// For example you can block all heroes from giving any weapon on all ka_ maps instead of disabling the hero.^n");
	fputs(blockWpnFile, "// You can even force people to buy weapons for all maps by blocking all weapons on all maps.^n");
	fputs(blockWpnFile, "//^n");
	fputs(blockWpnFile, "// Usage for maps:^n");
	fputs(blockWpnFile, "// - The asterisk * symbol will act as wildcard or by itself will be all maps, ie de_* is all maps that start with de_^n");
	fputs(blockWpnFile, "// - If setting a map prefix with wildcard and setting a map that has the same prefix, place map name before the^n");
	fputs(blockWpnFile, "//     prefix is used to use it over the prefix. ie set de_dust before de_* to use de_dust over the de_* config.^n");
	fputs(blockWpnFile, "// Usage for weapon:^n");
	fputs(blockWpnFile, "// - Place available weapon shorthand names from list below inside quotes and separate by commas.^n");
	fputs(blockWpnFile, "// - Works like an on/off switch so if you set a weapon twice it will block then unblock it.^n");
	fputs(blockWpnFile, "// - A special ^"all^" shorthand name can be used to toggle all weapons at once.^n");
	fputs(blockWpnFile, "// Valid shorthand weapon names:^n");
	fputs(blockWpnFile, "// - all, p228, scout, hegrenade, xm1014, c4, mac10, aug, smokegrenade, elite, fiveseven, ump45, sg550, galil,^n");
	fputs(blockWpnFile, "// - famas, usp, glock18, awp, mp5navy, m249, m3, m4a1, tmp, g3sg1, flashbang, deagle, sg552, ak47, knife, p90^n");
	fputs(blockWpnFile, "//^n");
	fputs(blockWpnFile, "// Examples of proper usage are as follows (these can be used by removing the // from the line):^n");
	fputs(blockWpnFile, "// - below blocks sh from giving the awp and p90 on de_dust.^n");
	fputs(blockWpnFile, "//de_dust ^"awp, p90^"^n");
	fputs(blockWpnFile, "// - below blocks sh from giving all weapons on all ka_ maps.^n");
	fputs(blockWpnFile, "//ka_* ^"all^"^n");
	fputs(blockWpnFile, "// - below blocks sh from giving all weapons then unblocks hegrenade on all he_ maps.^n");
	fputs(blockWpnFile, "//he_* ^"all, hegrenade^"^n");

	fclose(blockWpnFile);
}
//----------------------------------------------------------------------------------------------
