// VASH THE STAMPEDE! - From the anime Trigun. Vash is a peace loving, donut eating, girl crazy pacifist with a 60 billion double dollar bounty on his head.

/* CVARS - copy and paste to shconfig.cfg

//Vash the Stampede
vash_level 4
vash_deaglemult 2.5		//Damage multiplier for his Deagle
vash_gravity 1.0		//Default 1.0 = normal gravity (0.50 is 50% of normal gravity, ect.)

*/

/*
* v1.4 - vittu - 6/22/05
*      - Code clean up.
*
* v1.3 - vittu - 5/05/05
*      - Fixed code run on clearpowers, now only gets run if user actually had the hero.
*      - Other minor change to code for efficiency.
*
* v1.2 - vittu - 2/02/05
*      - Changed weapon model, old one was for the wrong hand anyway.
*      - Added Evasion to code, a missing hitzone randomly chosen every second.
*      - Set gravity default to none because vash doesn't have low gravity, but
*         left cvar since it was in orginal.
*      - Removed no-reload because he uses a revolver, and gave ammo instead but
*         just enough not affect no-reload heroes.
*
*   Ripped from the hero - Morpheus by RadidEskimo & Freecode.
*   Weapon model by Thin Red Paste & X-convinct, converted by SplinterCell.
*/

//---------- User Changeable Defines --------//


// 0-follow server sh_reloadmode cvar setting
// 1-no reload, continuous shooting
// 2-reload, but backpack ammo never depletes [Default]
// 3-drop weapon and get a new one with full clip
// 4-normal cs, reload and backpack ammo depletes
#define AMMO_MODE 2

// Comment out to force not using the Deagle model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
// #define USE_WEAPON_MODEL


//------- Do not edit below this point ------//

#include <superheromod>
#include <amxmisc>

#pragma semicolon 1

// CS Weapon CBase Offsets (win32)
const PDATA_SAFE = 2;
const OFFSET_WEAPONOWNER = 41;
const OFFSET_LINUX_WEAPONS = 4;

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Vash the Stampede";

new bool:gHasVashPower[MAX_PLAYERS + 1];
new gAllowedHitZones[MAX_PLAYERS + 1];
new gmsgSync;

#if defined USE_WEAPON_MODEL
	new const gModel_V_Deagle[] = "models/shmod/vash_deagle.mdl";
	new bool:gModelLoaded;
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Vash the Stampede", "1.5", "sharky / vittu");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("vash_level", "4", .has_min = true, .min_val = 0.0);
	new pcvarDeagleMult = create_cvar("vash_deaglemult", "2.5");
	new pcvarGravity = create_cvar("vash_gravity", "1.0");
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Revolver & Evasion", "Get Vash's .45 Long Colt Revolver (DEAGLE), which does More Damage. Evade by automatically removing random hitzones");
	sh_set_hero_grav(gHeroID, pcvarGravity);
	sh_set_hero_dmgmult(gHeroID, pcvarDeagleMult, CSW_DEAGLE);
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
#if AMMO_MODE < 4
	// read_data(2) == CSW_DEAGLE = 2=26
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "2=26", "3=0");
#endif

	RegisterHamPlayer(Ham_TraceAttack, "@Forward_Player_TraceAttack_Pre");
#if defined USE_WEAPON_MODEL
	if (gModelLoaded)
		RegisterHam(Ham_Item_Deploy, "weapon_deagle", "@Forward_Deagle_Deploy_Post", 1);
#endif
	
	// LOOP
	set_task_ex(1.0, "@Task_VashLoop", _, _, _, SetTask_Repeat);

	gmsgSync = CreateHudSyncObj();
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
public plugin_precache()
{
	gModelLoaded = true;
	if (file_exists(gModel_V_Deagle)) {
		precache_model(gModel_V_Deagle);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_Deagle);
		gModelLoaded = false;
	}
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	switch(mode) {
		case SH_HERO_ADD: {
			gHasVashPower[id] = true;

			if (is_user_alive(id))
				vash_weapons(id);
			
#if defined USE_WEAPON_MODEL
			if (get_user_weapon(id) == CSW_DEAGLE)
				switch_model(id);
#endif
		}
		case SH_HERO_DROP: {
			gHasVashPower[id] = false;

			sh_drop_weapon(id, CSW_DEAGLE, true);

			if (is_user_alive(id))
				vash_shutdown(id);
		}
	}
	
	gAllowedHitZones[id] = 255;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (!gHasVashPower[id])
		return;
	
	vash_weapons(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_death(id)
{
	if (!sh_is_active() || is_user_alive(id) || !gHasVashPower[id])
		return;
	
	vash_shutdown(id);
}
//----------------------------------------------------------------------------------------------
vash_weapons(index)
{
	set_hudmessage(200, 0, 0, -1.0, 0.28, 2, 0.02, 4.0, 0.01, 0.1, -1);
	ShowSyncHudMsg(index, gmsgSync, "Vash - EVASION ON - Removing a random hitzone every second");
	
	sh_give_weapon(index, CSW_DEAGLE);
}
//----------------------------------------------------------------------------------------------
vash_shutdown(index)
{
	set_hudmessage(200, 0, 0, -1.0, 0.28, 2, 0.02, 4.0, 0.01, 0.1, -1);
	ShowSyncHudMsg(index, gmsgSync, "Vash - EVASION OFF");
}
//----------------------------------------------------------------------------------------------
#if AMMO_MODE < 4
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasVashPower[id])
		return;
	
	sh_reload_ammo(id, AMMO_MODE);
}
#endif
//----------------------------------------------------------------------------------------------
@Forward_Player_TraceAttack_Pre(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if (!sh_is_active() || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	if (!gHasVashPower[victim] || victim == attacker)
		return HAM_IGNORED;
	
	if (!(damagebits & DMG_BULLET) && !(damagebits & DMG_SLASH))
		return HAM_IGNORED;
	
	if (!(gAllowedHitZones[victim] & (1 << get_tr2(tracehandle, TR_iHitgroup))))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_MODEL
@Forward_Deagle_Deploy_Post(weapon_ent)
{
	if (!sh_is_active())
		return;

	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent);
	
	switch_model(owner);
}
//----------------------------------------------------------------------------------------------
switch_model(index)
{
	if (!is_user_alive(index) || !gHasVashPower[index])
		return;
	
	if (cs_get_user_shield(index))
		return;
	
	set_pev(index, pev_viewmodel2, gModel_V_Deagle);
}
//----------------------------------------------------------------------------------------------
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}
#endif
//----------------------------------------------------------------------------------------------
@Task_VashLoop()
{
	if (!sh_is_active() || !sh_is_inround())
		return;
	
	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);
	
	for (i = 0; i < playerCount; i++) {
		player = players[i];
		
		if (gHasVashPower[player]) {
			// new randomHitZone = random_num(1, 7);
			switch(random_num(1, 7)) {
				case 1: gAllowedHitZones[player] = 127; //remove right leg hitzone
				case 2: gAllowedHitZones[player] = 191;	//remove left leg hitzone
				case 3: gAllowedHitZones[player] = 223;	//remove right arm hitzone
				case 4: gAllowedHitZones[player] = 239;	//remove left arm hitzone
				case 5: gAllowedHitZones[player] = 247;	//remove stomach hitzone
				case 6: gAllowedHitZones[player] = 251;	//remove chest hitzone
				case 7: gAllowedHitZones[player] = 253;	//remove head hitzone
			}
		}
	}
}
//----------------------------------------------------------------------------------------------