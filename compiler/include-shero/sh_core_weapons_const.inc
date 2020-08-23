
#if defined _sh_core_weapons_const_included
  #endinput
#endif
#define _sh_core_weapons_const_included

//------------
// Weapon look up tables
//------------
// usage: sh_get_max_bpammo(weaponID)
#define sh_get_max_bpammo(%1) gMaxBPAmmo[%1]
stock gMaxBPAmmo[] = {
	0,
	52,	//CSW_P228
	0,
	90,	//CSW_SCOUT
	1,	//CSW_HEGRENADE
	32,	//CSW_XM1014
	1,	//CSW_C4
	100,	//CSW_MAC10
	90,	//CSW_AUG
	1,	//CSW_SMOKEGRENADE
	120,	//CSW_ELITE
	100,	//CSW_FIVESEVEN
	100,	//CSW_UMP45
	90,	//CSW_SG550
	90,	//CSW_GALIL
	90,	//CSW_FAMAS
	100,	//CSW_USP
	120,	//CSW_GLOCK18
	30,	//CSW_AWP
	120,	//CSW_MP5NAVY
	200,	//CSW_M249
	32,	//CSW_M3
	90,	//CSW_M4A1
	120,	//CSW_TMP
	90,	//CSW_G3SG1
	2,	//CSW_FLASHBANG
	35,	//CSW_DEAGLE
	90,	//CSW_SG552
	90,	//CSW_AK47
	0,	//CSW_KNIFE
	100	//CSW_P90
};
// usage: sh_get_max_clipammo(weaponID)
#define sh_get_max_clipammo(%1) gMaxClipAmmo[%1]
stock gMaxClipAmmo[] = {
	0,
	13,	//CSW_P228
	0,
	10,	//CSW_SCOUT
	0,	//CSW_HEGRENADE
	7,	//CSW_XM1014
	0,	//CSW_C4
	30,	//CSW_MAC10
	30,	//CSW_AUG
	0,	//CSW_SMOKEGRENADE
	30,	//CSW_ELITE
	20,	//CSW_FIVESEVEN
	25,	//CSW_UMP45
	30,	//CSW_SG550
	35,	//CSW_GALIL
	25,	//CSW_FAMAS
	12,	//CSW_USP
	20,	//CSW_GLOCK18
	10,	//CSW_AWP
	30,	//CSW_MP5NAVY
	100,	//CSW_M249
	8,	//CSW_M3
	30,	//CSW_M4A1
	30,	//CSW_TMP
	20,	//CSW_G3SG1
	0,	//CSW_FLASHBANG
	7,	//CSW_DEAGLE
	30,	//CSW_SG552
	30,	//CSW_AK47
	0,	//CSW_KNIFE
	50	//CSW_P90
};
// usage: sh_get_weapon_slot(weaponID)
#define sh_get_weapon_slot(%1) gWeaponSlot[%1]
stock gWeaponSlot[] = {
	0,
	2,	//CSW_P228
	0,
	1,	//CSW_SCOUT
	4,	//CSW_HEGRENADE
	1,	//CSW_XM1014
	5,	//CSW_C4
	1,	//CSW_MAC10
	1,	//CSW_AUG
	4,	//CSW_SMOKEGRENADE
	2,	//CSW_ELITE
	2,	//CSW_FIVESEVEN
	1,	//CSW_UMP45
	1,	//CSW_SG550
	1,	//CSW_GALIL
	1,	//CSW_FAMAS
	2,	//CSW_USP
	2,	//CSW_GLOCK18
	1,	//CSW_AWP
	1,	//CSW_MP5NAVY
	1,	//CSW_M249
	1,	//CSW_M3
	1,	//CSW_M4A1
	1,	//CSW_TMP
	1,	//CSW_G3SG1
	4,	//CSW_FLASHBANG
	2,	//CSW_DEAGLE
	1,	//CSW_SG552
	1,	//CSW_AK47
	3,	//CSW_KNIFE
	1	//CSW_P90
};
