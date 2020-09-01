/*================================================================================
	
	-------------------------------------
	-*- [CS] Weapons Restrict API 0.5 -*-
	-------------------------------------
	
	- Allows easily restricting player's weapons in CS and CZ
	- ToDo: PODBots support?? (does engclient_cmd work for them?)
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" };

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = CSW_ALL_SHOTGUNS | CSW_ALL_SMGS | CSW_ALL_RIFLES | CSW_ALL_SNIPERRIFLES | CSW_ALL_MACHINEGUNS;
const OTHER_WEAPONS_BIT_SUM = (1 << CSW_KNIFE) | (1 << CSW_C4);

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2)		%1 |= (1 << (%2 & 31))
#define flag_clear(%1,%2)	%1 &= ~(1 << (%2 & 31))

new gHasWeaponRestrictions;
new gAllowedWeaponsBitsum[MAX_PLAYERS + 1];
new gDefaultAllowedWeapon[MAX_PLAYERS + 1];

public plugin_init()
{
	register_plugin("[CS] Weapons Restrict API", "0.5", "WiLS");
	
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++) {
		if (WEAPONENTNAMES[i][0])
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "@Forward_Item_Deploy_Post", 1);
	}
}

public plugin_natives()
{
	register_library("cs_weap_restrict_api");
	register_native("cs_set_player_weap_restrict", "@Native_SetPlayerWeapRestrict");
	register_native("cs_get_player_weap_restrict", "@Native_GetPlayerWeapRestrict");
}

@Native_SetPlayerWeapRestrict(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	new set = get_param(2);
	
	if (!set) {
		// Player doesn't have weapon restrictions, no need to reset
		if (!flag_get(gHasWeaponRestrictions, id))
			return true;
		
		flag_clear(gHasWeaponRestrictions, id);
		
		// Re-deploy current weapon, to unlock weapon's firing if we were blocking it
		new currentWeaponEnt = cs_get_user_weapon_entity(id);
		if (pev_valid(currentWeaponEnt))
			ExecuteHamB(Ham_Item_Deploy, currentWeaponEnt);
		return true;
	}
	
	new allowedBitsum = get_param(3);
	new allowedDefault = get_param(4);
	
	if (!(allowedBitsum & PRIMARY_WEAPONS_BIT_SUM) && !(allowedBitsum & CSW_ALL_PISTOLS)
		&& !(allowedBitsum & CSW_ALL_GRENADES) && !(allowedBitsum & OTHER_WEAPONS_BIT_SUM)) {
		// Bitsum does not contain any weapons, set allowed default weapon to CSW_NONE
		allowedDefault = CSW_NONE;
	} else if (!(allowedBitsum & (1 << allowedDefault))) {
		log_error(AMX_ERR_NATIVE, "[CS] Default allowed weapon must be in allowed weapons bitsum");
		return false;
	}
	
	flag_set(gHasWeaponRestrictions, id);
	gAllowedWeaponsBitsum[id] = allowedBitsum;
	gDefaultAllowedWeapon[id] = allowedDefault;
	
	// Update weapon restrictions
	new currentWeaponEnt = cs_get_user_weapon_entity(id);
	if (pev_valid(currentWeaponEnt))
		@Forward_Item_Deploy_Post(currentWeaponEnt);
	return true;
}

@Native_GetPlayerWeapRestrict(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	if (!flag_get(gHasWeaponRestrictions, id))
		return false;
	
	set_param_byref(2, gAllowedWeaponsBitsum[id]);
	set_param_byref(3, gDefaultAllowedWeapon[id]);
	return true;
}

public client_disconnected(id)
{
	flag_clear(gHasWeaponRestrictions, id);
}

@Forward_Item_Deploy_Post(weaponEnt)
{
	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weaponEnt);
	
	// Owner not valid or does not have any restrictions set
	if (!is_user_alive(owner) || !flag_get(gHasWeaponRestrictions, owner))
		return;
	
	// Get weapon's id
	new weaponID = cs_get_weapon_id(weaponEnt);
	
	// Owner not holding an allowed weapon
	if (!((1 << weaponID) & gAllowedWeaponsBitsum[owner])) {
		if (is_user_bot(owner)) {
			ham_strip_user_weapon(owner, weaponID);
		} else {
			if (user_has_weapon(owner, gDefaultAllowedWeapon[owner]))
				// Switch to default weapon
				engclient_cmd(owner, WEAPONENTNAMES[gDefaultAllowedWeapon[owner]]);
			else
				// Otherwise, block weapon firing and hide current weapon
				block_and_hide_weapon(owner);
		}
	}
}

// Prevent player from firing and hide current weapon model
block_and_hide_weapon(index)
{
	fm_cs_set_user_next_attack(index, 99999.0);
	set_pev(index, pev_viewmodel2, "");
	set_pev(index, pev_weaponmodel2, "");
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
}

stock fm_cs_set_user_next_attack(index, Float:nextAttack)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(index) != 2)
		return false;
	
	set_ent_data_float(index, "CBaseMonster", "m_flNextAttack", nextAttack);
	return true;
}

// ConnorMcLeod
// 99999.0 = 27hours, should be enough.
// Want to block attack1?
// set_ent_data_float(ent, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 99999.0);
// Want to block attack2?
// set_ent_data_float(ent, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 99999.0);
// Also want to block +use? (may block other things such as impulse(impulse are put in a queue))
// set_ent_data_float(id, "CBaseMonster", "m_flNextAttack", 99999.0);

// A more restrictive method by ConnorMcLeod
stock ham_strip_user_weapon(index, weaponIndex, slot = 0, bool:switchIfActive = true)
{
    new weapon;
    if(!slot) {
        static const weaponsSlots[] = {
            -1,
            2, //CSW_P228
            -1,
            1, //CSW_SCOUT
            4, //CSW_HEGRENADE
            1, //CSW_XM1014
            5, //CSW_C4
            1, //CSW_MAC10
            1, //CSW_AUG
            4, //CSW_SMOKEGRENADE
            2, //CSW_ELITE
            2, //CSW_FIVESEVEN
            1, //CSW_UMP45
            1, //CSW_SG550
            1, //CSW_GALIL
            1, //CSW_FAMAS
            2, //CSW_USP
            2, //CSW_GLOCK18
            1, //CSW_AWP
            1, //CSW_MP5NAVY
            1, //CSW_M249
            1, //CSW_M3
            1, //CSW_M4A1
            1, //CSW_TMP
            1, //CSW_G3SG1
            4, //CSW_FLASHBANG
            2, //CSW_DEAGLE
            1, //CSW_SG552
            1, //CSW_AK47
            3, //CSW_KNIFE
            1 //CSW_P90
        };
        slot = weaponsSlots[weaponIndex];
    }

    weapon = get_ent_data_entity(index, "CBasePlayer", "m_rgpPlayerItems", slot);

    while (weapon > 0) {
        if (get_ent_data(weapon, "CBasePlayerItem", "m_iId") == weaponIndex)
            break;
		
        weapon = get_ent_data_entity(weapon, "CBasePlayerItem", "m_pNext");
    }

    if (weapon > 0) {
        if (switchIfActive && cs_get_user_weapon_entity(index) == weapon)
            ExecuteHamB(Ham_Weapon_RetireWeapon, weapon);
		
        if (ExecuteHamB(Ham_RemovePlayerItem, index, weapon)) {
            user_has_weapon(index, weaponIndex, 0);
            ExecuteHamB(Ham_Item_Kill, weapon);
            return 1;
        }
    }

    return 0;
}
