
#if defined _sh_core_speed_const_included
  #endinput
#endif
#define _sh_core_speed_const_included

//------------
// Weapon look up tables
//------------
// Usage: check sh_get_weapon_speed stock in sh_core_speed.inc
stock Float:gWeaponSpeed[] = {
	0.0,
	250.0,	// CSW_P228
	0.0,
	260.0,	// CSW_SCOUT
	250.0,	// CSW_HEGRENADE
	240.0,	// CSW_XM1014
	250.0,	// CSW_C4
	250.0,	// CSW_MAC10
	240.0,	// CSW_AUG
	250.0,	// CSW_SMOKEGRENADE
	250.0,	// CSW_ELITE
	250.0,	// CSW_FIVESEVEN
	250.0,	// CSW_UMP45
	210.0,	// CSW_SG550
	240.0,	// CSW_GALI
	240.0,	// CSW_FAMAS
	250.0,	// CSW_USP
	250.0,	// CSW_GLOCK18
	210.0,	// CSW_AWP
	250.0,	// CSW_MP5NAVY
	220.0,	// CSW_M249
	230.0,	// CSW_M3
	230.0,	// CSW_M4A1
	250.0,	// CSW_TMP
	210.0,	// CSW_G3SG1
	250.0,	// CSW_FLASHBANG
	250.0,	// CSW_DEAGLE
	235.0,	// CSW_SG552
	221.0,	// CSW_AK47
	250.0,	// CSW_KNIFE
	245.0	// CSW_P90
};
