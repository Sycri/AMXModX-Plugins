// PENGUIN! - From Batman. Oswald Chesterfield Cobblepot, is a "reformed" master criminal.

/*****AMX Mod X ONLY! Requires Fakemeta module*****/

/* CVARS - copy and paste to shconfig.cfg

//Penguin
penguin_level 0
penguin_grenademult 1.0		//Damage multiplyer, 1.0 = no xtra dmg (def 1.0)
penguin_grenadetimer 30.0	//How many seconds delay for new grenade after nade is thrown (def 30.0)
penguin_cooldown 120.0		//How many seconds until penguin grenade can be used again (def 120.0)
penguin_fuse 5.0			//Length of time Penguin grenades can seek for before blowing up (def 5.0)
penguin_nadespeed 900		//Speed of Penguin grenades when seeking (def 900)

*/

/*
* v1.2 - vittu - 9/28/05
*      - Minor code clean up and changes.
*      - Fixed getting actual grenade id.
*      - Fixed pausing of grenade blowing up used for fuse cvar.
*      - Fixed grenade touching to only explode on enemy contact.
*      - Added view model, so you know when you have a penguin nade.
*      - Made a hack job, so multiplier/cooldown will work if nade is paused
*          past when nades are supposed to blow. This will likely have bugs.
*
*    Based on AMXX Heatseeking Hegrenade 1.3 by Cheap_Suit.
*    HE Grenade Model by Opposing Forces Team, xinsomniacboix, Indolence, & haZaa.
*   	Yang wrote, "Cred goez to vittu's sexiness on gambit and cheap_suit who created the original plugin".
*/

//---------- User Changeable Defines --------//


// Comment out to not use the Penguin viewmodel
#define USE_WEAPON_VIEW_MODEL

// Comment out to not use the Penguin worldmodel
#define USE_WEAPON_WORLD_MODEL


//------- Do not edit below this point ------//

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_weapons>

#pragma semicolon 1

const AMMOX_HEGRENADE = 12;

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Penguin";

new bool:gHasPenguinPower[MAX_PLAYERS + 1];
new bool:gBlockGiveTask[MAX_PLAYERS + 1];
new bool:gPauseEntity[999];
new bool:gPenguinNade[MAX_PLAYERS + 1][999];
new Float:gNadeSpeed;

new Float:CvarGrenadeMult, Float:CvarGrenadeTimer;
new Float:CvarCooldown, Float:CvarFuse, Float:CvarNadeSpeed;

new gSpriteTrail;

#if defined USE_WEAPON_VIEW_MODEL
	new const gModel_V_HEGrenade[] = "models/shmod/penguin_v_hegrenade.mdl";
	new bool:gViewModelLoaded;
#endif
#if defined USE_WEAPON_WORLD_MODEL
	new const gModel_W_HEGrenade[] = "models/shmod/penguin_w_hegrenade.mdl";
	new bool:gWorldModelLoaded;
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Penguin", "1.3", "Yang/vittu");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("penguin_level", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(create_cvar("penguin_grenademult", "1.0", .has_min = true, .min_val = 0.0), CvarGrenadeMult);
	bind_pcvar_float(create_cvar("penguin_grenadetimer", "30.0", .has_min = true, .min_val = 0.0), CvarGrenadeTimer);
	bind_pcvar_float(create_cvar("penguin_cooldown", "120.0", .has_min = true, .min_val = 0.0), CvarCooldown);
	bind_pcvar_float(create_cvar("penguin_fuse", "5.0", .has_min = true, .min_val = 0.0), CvarFuse);
	bind_pcvar_float(create_cvar("penguin_nadespeed", "900", .has_min = true, .min_val = 1.0, .has_max = true, .max_val = 2000.0), CvarNadeSpeed);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Seeking HE-Penguins", "Throw HE Grenade strapped Pengiun friends that Seek out your enemy, also refill HE Grenades");
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	register_event_ex("AmmoX", "@Event_AmmoX", RegisterEvent_Single);

	register_forward(FM_SetModel, "@Forward_SetModel");
	register_forward(FM_Think, "@Forward_Think");
	register_forward(FM_Touch, "@Forward_Touch");

	RegisterHamPlayer(Ham_TakeDamage, "@Forward_Player_TakeDamage_Pre");
#if defined USE_WEAPON_VIEW_MODEL
	if (gViewModelLoaded)
		RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "@Forward_HEGrenade_Deploy_Post", 1);
#endif
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSpriteTrail = precache_model("sprites/smoke.spr");

#if defined USE_WEAPON_VIEW_MODEL
	gViewModelLoaded = true;
	if(file_exists(gModel_V_HEGrenade)) {
		precache_model(gModel_V_HEGrenade);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_HEGrenade);
		gViewModelLoaded = false;
	}
#endif
#if defined USE_WEAPON_WORLD_MODEL
	gWorldModelLoaded = true;
	if(file_exists(gModel_W_HEGrenade)) {
		precache_model(gModel_W_HEGrenade);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_W_HEGrenade);
		gWorldModelLoaded = false;
	}
#endif
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	switch (mode) {
		case SH_HERO_ADD: {
			gHasPenguinPower[id] = true;

			@Task_GiveGrenade(id);

#if defined USE_WEAPON_VIEW_MODEL
			if (gViewModelLoaded && get_user_weapon(id) == CSW_HEGRENADE)
				switch_model(id);
#endif
		}
		case SH_HERO_DROP: {
			gHasPenguinPower[id] = false;

#if defined USE_WEAPON_VIEW_MODEL
			if (gViewModelLoaded && get_user_weapon(id) == CSW_HEGRENADE)
				reset_model(id);
#endif
		}
	}
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (!gHasPenguinPower[id])
		return;
	
	gPlayerInCooldown[id] = false;

	if (gHasPenguinPower[id]) {
		gBlockGiveTask[id] = true;
		@Task_GiveGrenade(id);
	}
	
	for (new i = MaxClients + 1; i < charsmax(gPauseEntity); ++i)
		gPenguinNade[id][i] = false;
}
//----------------------------------------------------------------------------------------------
public sh_round_start()
{
	for (new i = MaxClients + 1; i < charsmax(gPauseEntity); ++i)
		gPauseEntity[i] = false;
}
//----------------------------------------------------------------------------------------------
@Event_AmmoX(id)
{
	if (!sh_is_active() || !is_user_alive(id) || !gHasPenguinPower[id])
		return;

	if (read_data(1) == AMMOX_HEGRENADE) {
		new ammoCount = read_data(2);

		if (ammoCount == 0 && !gBlockGiveTask[id]) {
			set_task(CvarGrenadeTimer, "@Task_GiveGrenade", id);
		} else if (ammoCount > 0) {
			gBlockGiveTask[id] = false;
			remove_task(id);
		}
	}
}
//----------------------------------------------------------------------------------------------
@Task_GiveGrenade(id)
{
	if (sh_is_active() && is_user_alive(id) && gHasPenguinPower[id])
		sh_give_weapon(id, CSW_HEGRENADE);
}
//----------------------------------------------------------------------------------------------
@Forward_SetModel(ent, const model[])
{
	if (!sh_is_active())
		return FMRES_IGNORED;
	
	if (!equal(model, "models/w_hegrenade.mdl"))
		return FMRES_IGNORED;
	
	static Float:dmgtime;
	pev(ent, pev_dmgtime, dmgtime);
	
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	new owner = pev(ent, pev_owner);
	
	if (!is_user_alive(owner) || !gHasPenguinPower[owner])
		return FMRES_IGNORED;
	
	if (!gPlayerInCooldown[owner]) {
#if defined USE_WEAPON_WORLD_MODEL
		if (gWorldModelLoaded)
			engfunc(EngFunc_SetModel, ent, gModel_W_HEGrenade);
#endif
		
		gNadeSpeed = CvarNadeSpeed;
		gPauseEntity[ent] = true;
		
		new parm[3];
		parm[0] = ent;
		parm[1] = owner;
		// If this changes so must nade_reset time or cooldown may not be set
		// The longer the nade_rest time the more chance for error with attacker identity
		set_task(1.0, "@Task_FindTarget", 0, parm, 3);
		
		set_task(CvarFuse, "@Task_UnpauseNade", ent, parm, 2);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Task_FindTarget(parm[])
{
	new grenadeID = parm[0];
	new grenadeOwner = parm[1];
	
	if (!pev_valid(grenadeID))
		return;
	
	static Float:shortestDist, Float:distance, Float:playerOrigin[3], Float:grenadeOrigin[3], nearestPlayer;
	static players[MAX_PLAYERS], playerCount, player, i, rgb[3], CsTeams:userTeam;

	shortestDist = 9999.0;
	nearestPlayer = 0;
	userTeam = cs_get_user_team(grenadeOwner);
	
	switch (userTeam) {
		case CS_TEAM_CT: rgb = {50, 50, 175};
		case CS_TEAM_T: rgb = {175, 50, 50};
		default: rgb = {175, 175, 175};
	}
	
	pev(grenadeID, pev_origin, grenadeOrigin);
	
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);
	
	for (i = 0; i < playerCount; ++i) {
		player = players[i];
		
		if (cs_get_user_team(player) == userTeam)
			continue;
		
		pev(player, pev_origin, playerOrigin);
		distance = get_distance_f(playerOrigin, grenadeOrigin);
		
		if (distance <= shortestDist) {
			shortestDist = distance;
			nearestPlayer = player;
		}
	}
	
	if (nearestPlayer > 0) {
		// Trail on grenade
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // 22
		write_short(grenadeID); // entity:attachment to follow
		write_short(gSpriteTrail); // sprite index
		write_byte(10); // life in 0.1's
		write_byte(3); // line width in 0.1's
		write_byte(rgb[0]); // r
		write_byte(rgb[1]); // g
		write_byte(rgb[2]); // b
		switch (random_num(0,2)) {
			case 0: write_byte(64); // brightness
			case 1: write_byte(128);
			case 2: write_byte(192);
		}
		message_end();
		
		parm[2] = nearestPlayer;
		set_task_ex(0.1, "@Task_SeekTarget", grenadeID + 1099, parm, 3, SetTask_Repeat);
	}
}
//----------------------------------------------------------------------------------------------
@Task_SeekTarget(parm[])
{
	new grenade = parm[0];
	new target = parm[2];
	
	if (!pev_valid(grenade)) {
		remove_task(grenade + 1099);
		return;
	}
	
	if (is_user_alive(target)) {
		fm_entity_set_follow(grenade, target);
	} else {
		remove_task(grenade + 1099);
		
		// Stop the Trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_KILLBEAM); // 99
		write_short(grenade); // entity
		message_end();
		
		set_task(0.1, "@Task_FindTarget", 0, parm, 3);
	}
}
//----------------------------------------------------------------------------------------------
fm_entity_set_follow(entity, target)
{
	if (!pev_valid(entity) || !is_user_alive(target))
		return false;
	
	new Float:targetOrigin[3], Float:entityOrigin[3];
	pev(target, pev_origin, targetOrigin);
	pev(entity, pev_origin, entityOrigin);
	
	new Float:invTime = (gNadeSpeed / vector_distance(targetOrigin, entityOrigin));
	
	new Float:distance[3];
	distance[0] = targetOrigin[0] - entityOrigin[0];
	distance[1] = targetOrigin[1] - entityOrigin[1];
	distance[2] = targetOrigin[2] - entityOrigin[2];
	
	new Float:velocity[3];
	velocity[0] = distance[0] * invTime;
	velocity[1] = distance[1] * invTime;
	velocity[2] = distance[2] * invTime;
	
	set_pev(entity, pev_velocity, velocity);
	
	new Float:angle[3];
	vector_to_angle(velocity, angle);
	set_pev(entity, pev_angles, angle);
	
	return true;
}
//----------------------------------------------------------------------------------------------
@Task_NadeReset(parm[])
{
	new grenadeID = parm[0];
	new grenadeOwner = parm[1];
	
	gPenguinNade[grenadeOwner][grenadeID] = false;
}
//----------------------------------------------------------------------------------------------
@Forward_Think(ent)
{
	if (ent <= MaxClients || ent > charsmax(gPauseEntity))
		return FMRES_IGNORED;
	
	if (gPauseEntity[ent]) {
		new Float:nextThink;
		pev(ent, pev_nextthink, nextThink);
		set_pev(ent, pev_nextthink, nextThink + 0.1);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_Touch(ptr, ptd)
{
	if (ptr <= MaxClients || ptr > charsmax(gPauseEntity))
		return FMRES_IGNORED;
	
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;
	
	new classNamePtr[32], classNamePtd[32];
	pev(ptr, pev_classname, classNamePtr, charsmax(classNamePtr));
	pev(ptd, pev_classname, classNamePtd, charsmax(classNamePtd));
	
	if (!equal(classNamePtr, "grenade") || !equal(classNamePtd, "player"))
		return FMRES_IGNORED;

	if (!gPauseEntity[ptr])
		return FMRES_IGNORED;
	
	if (!is_user_connected(ptd))
		return FMRES_IGNORED;
	
	new grenadeOwner = pev(ptr, pev_owner);
	
	if (cs_get_user_team(grenadeOwner) == cs_get_user_team(ptd))
		return FMRES_IGNORED;
	
	new parm[2];
	parm[0] = ptr;
	parm[1] = grenadeOwner;
	@Task_UnpauseNade(parm);
	return FMRES_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Task_UnpauseNade(parm[])
{
	new grenadeID = parm[0];
	new grenadeOwner = parm[1];
	
	remove_task(grenadeID);
	
	gPenguinNade[grenadeOwner][grenadeID] = true;
	set_task(0.4, "@Task_NadeReset", 0, parm, 2);
	
	gPauseEntity[grenadeID] = false;
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!sh_is_active() || !is_user_connected(attacker))
		return HAM_IGNORED;
	
	if (!gHasPenguinPower[attacker] || gPlayerInCooldown[attacker])
		return HAM_IGNORED;
	
	if (!(damagebits & DMG_GRENADE))
		return HAM_IGNORED;
	
	SetHamParamFloat(4, damage *= CvarGrenadeMult);
	
	static i;
	for (i = MaxClients + 1; i < charsmax(gPauseEntity); ++i) {
		if (gPenguinNade[attacker][i])
			set_cooldown(i, attacker);
	}
	return HAM_HANDLED;
}
//----------------------------------------------------------------------------------------------
set_cooldown(grenadeID, grenadeOwner)
{
	gPenguinNade[grenadeOwner][grenadeID] = false;
	
	if (!is_user_alive(grenadeOwner) || gPlayerInCooldown[grenadeOwner])
		return;
	
	new Float:cooldown = CvarCooldown;
	if (cooldown > 0.0)
		sh_set_cooldown(grenadeOwner, cooldown);
}
//----------------------------------------------------------------------------------------------
#if defined USE_WEAPON_VIEW_MODEL
@Forward_HEGrenade_Deploy_Post(weapon_ent)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	// Get weapon's owner
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent);
	
	switch_model(owner);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
switch_model(id)
{
	if (!is_user_alive(id) || !gHasPenguinPower[id] || gPlayerInCooldown[id])
		return;
	
	if (cs_get_user_shield(id))
		return;
	
	set_pev(id, pev_viewmodel2, gModel_V_HEGrenade);
}
//----------------------------------------------------------------------------------------------
reset_model(index)
{
	if (!is_user_alive(index))
		return;

	if (cs_get_user_shield(index))
		return;
	
	new weaponEnt = cs_get_user_weapon_entity(index);
	
	// Let CS update weapon models
	ExecuteHamB(Ham_Item_Deploy, weaponEnt);
}
//----------------------------------------------------------------------------------------------
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
}
#endif
//----------------------------------------------------------------------------------------------
