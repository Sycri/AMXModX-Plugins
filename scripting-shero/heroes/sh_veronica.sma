// Veronica!

/* CVARS - copy and paste to shconfig.cfg

//Veronica
veronica_level 8
veronica_akmult 2.0		//Damage multiplier for ak47
veronica_grenades 5		//Grenades given
veronica_m203rad 200		//Radius of people affected by a grenade
veronica_m203maxdmg 120		//Max Grenades a mine can cause
veronica_m203conc 10.0		//Force of knockback
veronica_m203cooldown 2.0	//Cooldown per grenade shot
veronica_rldmode 0			//Endless ammo mode: 0-server default, 1-no reload, 2-reload, 3-drop wpn

*/

// Thanks to the original code of MP5+203 Mod by PaintLancer

//---------- User Changeable Defines --------//


// Comment out to not use the AK47 model
#define USE_WEAPON_MODEL

// Comment out to not give a free AK47
#define GIVE_WEAPON


//------- Do not edit below this point ------//

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_weapons>
#include <sh_core_extradamage>
#include <sh_core_shieldrestrict>

#if defined USE_WEAPON_MODEL
	#include <sh_core_models>
#endif

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Veronica";

new bool:gHasVeronica[MAX_PLAYERS + 1];
new gAmmo[MAX_PLAYERS + 1];
new gmsgStatusIcon;

new const Float:NADE_SIZE_MIN[3] = { -1.0, -1.0, -1.0 };
new const Float:NADE_SIZE_MAX[3] = { 1.0, 1.0, 1.0 };

new CvarGrenades, CvarMaxDamage, CvarReloadMode;
new Float:CvarRadius, Float:CvarConc, Float:CvarCooldown;

new const gPowerClass[] = "m203_nade";
new const gSoundLaunch[] = "shmod/glauncher.wav";
new const gSoundExplode[] = "shmod/a_exm2.wav";
new const gModelGrenade[] = "models/grenade.mdl";
#if defined USE_WEAPON_MODEL
	new const gModel_V_AK47[] = "models/shmod/ak47grenade.mdl";
	new bool:gModelLoaded;
#endif
new gSpriteTrail, gSpriteExplode;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Veronica", "1.6", "DuPeR/Yang/Fr33m@n");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("veronica_level", "8", .has_min = true, .min_val = 0.0);
	new pcvarAKMult = create_cvar("veronica_akmult", "2.0");
	bind_pcvar_num(create_cvar("veronica_grenades", "5", .has_min = true, .min_val = 0.0), CvarGrenades);
	bind_pcvar_float(create_cvar("veronica_m203rad", "200.0", .has_min = true, .min_val = 0.0), CvarRadius);
	bind_pcvar_num(create_cvar("veronica_m203maxdmg", "75", .has_min = true, .min_val = 0.0), CvarMaxDamage);
	bind_pcvar_float(create_cvar("veronica_m203conc", "10.0", .has_min = true, .min_val = 0.0), CvarConc);
	bind_pcvar_float(create_cvar("veronica_m203cooldown", "2.0", .has_min = true, .min_val = 0.0), CvarCooldown);
	bind_pcvar_num(create_cvar("veronica_rldmode", "0"), CvarReloadMode);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Resident Evil", "AK Grenade Launcher Right Mouse Button");
	sh_set_hero_dmgmult(gHeroID, pcvarAKMult, CSW_AK47);
#if defined GIVE_WEAPON
	sh_set_hero_shield(gHeroID, true);
#endif
#if defined USE_WEAPON_MODEL
	if (gModelLoaded)
		sh_set_hero_viewmodel(gHeroID, gModel_V_AK47, CSW_AK47);
#endif

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	// read_data(2) == CSW_AK47 = 2=28
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "2=28", "3=0");
	register_forward(FM_CmdStart, "@Forward_CmdStart");
	register_touch("*", gPowerClass, "@Forward_Touch");

	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);

	new weaponName[32];
	for (new i = CSW_P228; i <= CSW_P90; ++i) {
		if (i == CSW_AK47)
			continue;

		if (get_weaponname(i, weaponName, charsmax(weaponName)))
			RegisterHam(Ham_Item_Deploy, weaponName, "@Forward_OtherWeapon_Deploy_Post", 1);
	}

	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "@Forward_AK47_Deploy_Post", 1);

	gmsgStatusIcon = get_user_msgid("StatusIcon");
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundLaunch);
	precache_sound(gSoundExplode);
#if defined USE_WEAPON_MODEL
	gModelLoaded = true;
	if(file_exists(gModel_V_AK47)) {
		precache_model(gModel_V_AK47);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModel_V_AK47);
		gModelLoaded = false;
	}
#endif
	gSpriteTrail = precache_model("sprites/smoke.spr");
	gSpriteExplode = precache_model("sprites/shmod/zerogxplode2.spr");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	switch (mode) {
		case SH_HERO_ADD: {
			gHasVeronica[id] = true;
			gAmmo[id] = CvarGrenades;
#if defined GIVE_WEAPON
			sh_give_weapon(id, CSW_AK47);
#endif
		}
		case SH_HERO_DROP: {
			gHasVeronica[id] = false;
#if defined GIVE_WEAPON
			sh_drop_weapon(id, CSW_AK47, true);
#endif
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false;

	if (!gHasVeronica[id])
		return;

#if defined GIVE_WEAPON
	sh_give_weapon(id, CSW_AK47);
#endif
	ammo_hud(id, 0);
	gAmmo[id] = CvarGrenades;
	ammo_hud(id, 1);
}
//----------------------------------------------------------------------------------------------
public sh_client_death(id)
{
	if (is_user_alive(id) || !gHasVeronica[id])
		return;

	ammo_hud(id, 0);
}
//----------------------------------------------------------------------------------------------
@Event_CurWeapon(id)
{
	if (!sh_is_active() || !gHasVeronica[id])
		return;

	sh_reload_ammo(id, CvarReloadMode);
}
//----------------------------------------------------------------------------------------------
@Forward_CmdStart(id, uc_handle, seed)
{
	if (!sh_is_active() || !gHasVeronica[id] || !is_user_alive(id) || sh_is_freezetime())
		return FMRES_IGNORED;

	if ((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(entity_get_int(id, EV_INT_oldbuttons) & IN_ATTACK2)) {
		if (get_user_weapon(id) == CSW_AK47)
			launch_nade(id);
	}

	return FMRES_IGNORED;
}
//----------------------------------------------------------------------------------------------
launch_nade(id)
{
	if (gPlayerInCooldown[id]) {
		sh_sound_deny(id);
		return;
	}

	if (gAmmo[id] == 0) {
		client_print(id, print_center, "You are out of M203 grenades!");
		sh_sound_deny(id);
		return;
	}

	send_weapon_anim(id, 3);

	new ent = cs_create_entity("info_target");
	if (!ent)
		return;

	cs_set_ent_class(ent, gPowerClass);
	entity_set_model(ent, gModelGrenade);

	entity_set_size(ent, NADE_SIZE_MIN, NADE_SIZE_MAX);

	new Float:origin[3], Float:angles[3], Float:vAngle[3];
	// Get users postion and angles
	entity_get_vector(id, EV_VEC_origin, origin);
	entity_get_vector(id, EV_VEC_angles, angles);
	entity_get_vector(id, EV_VEC_v_angle, vAngle);

	// Change height of entity origin
	origin[2] += 10.0;

	// Set entity postion and angles
	entity_set_origin(ent, origin);
	entity_set_vector(ent, EV_VEC_angles, angles);
	entity_set_vector(ent, EV_VEC_v_angle, vAngle);

	// Set properties of the entity
	entity_set_int(ent, EV_INT_effects, EF_MUZZLEFLASH);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_edict(ent, EV_ENT_owner, id);

	new Float:velocity[3];
	velocity_by_aim(id, 2000, velocity);

	entity_set_vector(ent, EV_VEC_velocity, velocity);

	emit_sound(id, CHAN_WEAPON, gSoundLaunch, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	// remove an ammo and refresh the hud
	ammo_hud(id, 0);
	--gAmmo[id];
	ammo_hud(id, 1);

	new parm[1];
	parm[0] = ent;
	set_task(0.2, "@Task_GrenadeTrail", id, parm, 1);

	new Float:cooldown = CvarCooldown;
	if (cooldown > 0.0)
		sh_set_cooldown(id, cooldown);
}
//----------------------------------------------------------------------------------------------
send_weapon_anim(id, animation)
{
	entity_set_int(id, EV_INT_weaponanim, animation);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
	write_byte(animation);
	write_byte(entity_get_int(id, EV_INT_body));
	message_end();
}
//----------------------------------------------------------------------------------------------
@Forward_Touch(ptd, ptr)
{
	if (!sh_is_active())
		return PLUGIN_CONTINUE;

	new attacker = entity_get_edict2(ptr, EV_ENT_owner);

	new Float:dRatio, Float:distanceBetween, damage;
	new Float:dmgRadius = CvarRadius;
	new maxDamage = CvarMaxDamage;
	new FFOn = sh_friendlyfire_on();
	new CsTeams:attackerTeam = cs_get_user_team(attacker);
	new Float:vicOrigin[3], Float:explosionOrigin[3];

	entity_get_vector(ptr, EV_VEC_origin, explosionOrigin);

	new players[MAX_PLAYERS], playerCount, victim;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (new i = 0; i < playerCount; i++) {
		victim = players[i];

		entity_get_vector(victim, EV_VEC_origin, vicOrigin);
		distanceBetween = vector_distance(explosionOrigin, vicOrigin);

		if (distanceBetween <= dmgRadius) {
			if (FFOn || victim == attacker || attackerTeam != cs_get_user_team(victim)) {
				dRatio = distanceBetween / dmgRadius;

				// Have a minimum of 1 in case damage cvar is really low cause something is within the radius
				damage = max(1, maxDamage - floatround(maxDamage * dRatio));

				sh_extra_damage(victim, attacker, damage, "grenade", _, SH_DMG_NORM, true, _, explosionOrigin);
				set_velocity_from_origin(victim, explosionOrigin, CvarConc * damage);
			}
		}
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITE); // 17
	write_coord_f(explosionOrigin[0]);
	write_coord_f(explosionOrigin[1]);
	write_coord_f(explosionOrigin[2] + 60);
	write_short(gSpriteExplode);
	write_byte(20); // scale in 0.1's
	write_byte(200); // brightness
	message_end();

	emit_sound(ptr, CHAN_WEAPON, gSoundExplode, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	remove_entity(ptr);
	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
stock get_velocity_from_origin(ent, Float:origin[3], Float:speed, Float:velocity[3])
{
	new Float:entOrigin[3];
	entity_get_vector(ent, EV_VEC_origin, entOrigin);

	// Velocity = Distance / Time

	new Float:distance[3];
	distance[0] = entOrigin[0] - origin[0];
	distance[1] = entOrigin[1] - origin[1];
	distance[2] = entOrigin[2] - origin[2];

	new Float:time = (vector_distance(entOrigin, origin) / speed);

	velocity[0] = distance[0] / time;
	velocity[1] = distance[1] / time;
	velocity[2] = distance[2] / time;

	return (velocity[0] && velocity[1] && velocity[2]);
}
//----------------------------------------------------------------------------------------------
stock set_velocity_from_origin(ent, Float:origin[3], Float:speed)
{
	new Float:velocity[3];
	get_velocity_from_origin(ent, origin, speed, velocity);

	entity_set_vector(ent, EV_VEC_velocity, velocity);

	return 1;
}
//----------------------------------------------------------------------------------------------
@Forward_AddPlayerItem_Post(id)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	if (!is_user_alive(id) || !gHasVeronica[id])
		return HAM_IGNORED;

	if (cs_get_user_weapon(id) == CSW_AK47)
		ammo_hud(id, 1);
	else
		ammo_hud(id, 0);
		
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_OtherWeapon_Deploy_Post(weapon_ent)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	// Get weapon's owner
	new owner = get_ent_data_entity(weapon_ent, "CBasePlayerItem", "m_pPlayer");
	
	if (!is_user_alive(owner) || !gHasVeronica[owner])
		return HAM_IGNORED;
	
	ammo_hud(owner, 0);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Forward_AK47_Deploy_Post(weapon_ent)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	// Get weapon's owner
	new owner = get_ent_data_entity(weapon_ent, "CBasePlayerItem", "m_pPlayer");
	
	if (!is_user_alive(owner) || !gHasVeronica[owner])
		return HAM_IGNORED;
	
	ammo_hud(owner, 1);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
ammo_hud(id, show)
{
	new spriteString[32];
	formatex(spriteString, charsmax(spriteString), "number_%d", gAmmo[id]);

	if (show && gAmmo[id] > 0) {
		message_begin(MSG_ONE, gmsgStatusIcon, _, id);
		write_byte(1); // status (0 = hide, 1 = show, 2 = flash)
		write_string(spriteString);
		write_byte(0); // r, g, b
		write_byte(160); // r, g, b
		write_byte(0); // r, g, b
		message_end();
	} else {
		message_begin(MSG_ONE, gmsgStatusIcon, _, id);
		write_byte(0); // status (0 = hide, 1 = show, 2 = flash)
		write_string(spriteString);
		write_byte(0); // r, g, b
		write_byte(0); // r, g, b
		write_byte(0); // r, g, b
		message_end();
	}
}
//----------------------------------------------------------------------------------------------
@Task_GrenadeTrail(parm[])
{
	new ent = parm[0];

	if (ent) {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); //22
		write_short(ent);
		write_short(gSpriteTrail);
		write_byte(10); // life
		write_byte(5); // width
		write_byte(255); // r, g, b
		write_byte(255); // r, g, b
		write_byte(255); // r, g, b
		write_byte(100); // brightness
		message_end();
	}
}
//----------------------------------------------------------------------------------------------
