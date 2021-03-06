// VASH THE STAMPEDE! - From the anime Trigun. Vash is a peace loving, donut eating, girl crazy pacifist with a 60 billion double dollar bounty on his head.

/* CVARS - copy and paste to shconfig.cfg

//Vash the Stampede
vash_level 4
vash_deaglemult 2.5		//Damage multiplier for his Deagle
vash_gravity 1.0		//Default 1.0 = normal gravity (0.50 is 50% of normal gravity, ect.)
vash_rldmode 2			//Endless ammo mode: 0-server default, 1-no reload, 2-reload, 3-drop wpn

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


// Comment out to force not using the Deagle model, will result in a very small reduction in code/checks
// Note: If you change anything here from default setting you must recompile the plugin
#define USE_WEAPON_MODEL

// Comment out to not give a free Deagle
#define GIVE_WEAPON


//------- Do not edit below this point ------//

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_gravity>
#include <sh_core_weapons>

#if defined USE_WEAPON_MODEL
	#include <sh_core_models>
#endif

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Vash the Stampede";

new bool:gHasVashPower[MAX_PLAYERS + 1];
new gAllowedHitZones[MAX_PLAYERS + 1];
new gmsgSync;

new CvarReloadMode;

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
	bind_pcvar_num(create_cvar("vash_rldmode", "2"), CvarReloadMode);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Revolver & Evasion", "Get Vash's .45 Long Colt Revolver (DEAGLE), which does More Damage. Evade by automatically removing random hitzones");
	sh_set_hero_grav(gHeroID, pcvarGravity);
	sh_set_hero_dmgmult(gHeroID, pcvarDeagleMult, CSW_DEAGLE);
#if defined USE_WEAPON_MODEL
	if (gModelLoaded)
		sh_set_hero_viewmodel(gHeroID, gModel_V_Deagle, CSW_DEAGLE);
#endif

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	// read_data(2) == CSW_DEAGLE = 2=26
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "2=26", "3=0");

	RegisterHamPlayer(Ham_TraceAttack, "@Forward_Player_TraceAttack_Pre");
	
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
#if defined GIVE_WEAPON
			sh_give_weapon(id, CSW_DEAGLE);
#endif
			if (is_user_alive(id))
				vash_turnon(id);
		}
		case SH_HERO_DROP: {
			gHasVashPower[id] = false;
#if defined GIVE_WEAPON
			sh_drop_weapon(id, CSW_DEAGLE, true);
#endif
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
	
#if defined GIVE_WEAPON
	sh_give_weapon(id, CSW_DEAGLE);
#endif
	vash_turnon(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_death(id)
{
	if (!sh_is_active() || is_user_alive(id) || !gHasVashPower[id])
		return;
	
	vash_shutdown(id);
}
//----------------------------------------------------------------------------------------------
vash_turnon(index)
{
	set_hudmessage(200, 0, 0, -1.0, 0.28, 2, 0.02, 4.0, 0.01, 0.1, -1);
	ShowSyncHudMsg(index, gmsgSync, "Vash - EVASION ON - Removing a random hitzone every second");
}
//----------------------------------------------------------------------------------------------
vash_shutdown(index)
{
	set_hudmessage(200, 0, 0, -1.0, 0.28, 2, 0.02, 4.0, 0.01, 0.1, -1);
	ShowSyncHudMsg(index, gmsgSync, "Vash - EVASION OFF");
}
//----------------------------------------------------------------------------------------------
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasVashPower[id])
		return;
	
	sh_reload_ammo(id, CvarReloadMode);
}
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
@Task_VashLoop()
{
	if (!sh_is_active() || !sh_is_inround())
		return;
	
	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);
	
	for (i = 0; i < playerCount; ++i) {
		player = players[i];
		
		if (!gHasVashPower[player])
			continue;
		
		//255 - (1 << 7) = 127 = remove right leg hitzone
		//255 - (1 << 6) = 191 = remove left leg hitzone
		//255 - (1 << 5) = 223 = remove right arm hitzone
		//255 - (1 << 4) = 239 = remove left arm hitzone
		//255 - (1 << 3) = 247 = remove stomach hitzone
		//255 - (1 << 2) = 251 = remove chest hitzone
		//255 - (1 << 1) = 253 = remove head hitzone
		gAllowedHitZones[player] = 255 - (1 << random_num(1, 7));
	}
}
//----------------------------------------------------------------------------------------------
