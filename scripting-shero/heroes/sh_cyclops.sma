// Cyclops! - Cool Laser Guy From Xmen (Yeah - Luds Laser Ripoff :D)

/* CVARS - copy and paste to shconfig.cfg

//Cyclops
cyclops_level 5
cyclops_laser_ammo 20			//Total # of shots given each round, -1 is unlimited 
cyclops_laser_burndecals 1		//Show the burn decals on the walls
cyclops_cooldown 0.20			//Cooldown timer between shots
cyclops_multishot 0.2			//Delay for multishots on holding key down

*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <sh_core_main>
#include <sh_core_weapons>
#include <sh_core_extradamage>

#pragma semicolon 1

// Damage Variables
new const lDamage[7] = {
	100,	//head
	56,		//chest
	56,		//stomach
	36,		//left arm
	36,		//right arm
	36,		//left leg
	36		//right leg
};

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Cyclops";

new bool:gUsingLaser[MAX_PLAYERS + 1];
new gLaserShots[MAX_PLAYERS + 1];
new gLastWeapon[MAX_PLAYERS + 1];

new CvarLaserAmmo, CvarBurnDecals;
new Float:CvarCooldown, Float:CvarMultiShot;

new gBurnDecal;
new const gSoundLaser[] = "weapons/electro5.wav";
new const gSoundHit[] = "weapons/xbow_hitbod2.wav";
new gSpriteSmoke, gSpriteLaser;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Cyclops", SH_VERSION_STR, "AssKicR/Batman/JTP10181");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("cyclops_level", "5", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("cyclops_laser_ammo", "20", .has_min = true, .min_val = 0.0), CvarLaserAmmo);
	bind_pcvar_num(create_cvar("cyclops_laser_burndecals", "1"), CvarBurnDecals);
	bind_pcvar_float(create_cvar("cyclops_cooldown", "0.20", .has_min = true, .min_val = 0.0), CvarCooldown);
	bind_pcvar_float(create_cvar("cyclops_multishot", "0.2"), CvarMultiShot);

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Optic Blast", "Press the +power key to fire your optic laser beam");
	sh_set_hero_bind(gHeroID);

	// Set to correct burn decals if mod is CZ or CS
	gBurnDecal = get_decal_index("{bigshot5");
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundLaser);
	precache_sound(gSoundHit);
	gSpriteSmoke = precache_model("sprites/steam1.spr");
	gSpriteLaser = precache_model("sprites/laserbeam.spr");
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	remove_task(id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	if (mode == SH_HERO_ADD) {
		gPlayerInCooldown[id] = false;
		gLaserShots[id] = CvarLaserAmmo;
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	remove_task(id);
	gUsingLaser[id] = false;
	
	gLaserShots[id] = CvarLaserAmmo;
	
	gPlayerInCooldown[id] = false;
}
//----------------------------------------------------------------------------------------------
public sh_client_death(id)
{
	if (is_user_alive(id) || !is_user_connected(id))
		return;

	remove_task(id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if (gHeroID != heroID)
		return;

	switch (key)
	{
		case SH_KEYDOWN: {
			if (sh_is_freezetime() || !is_user_alive(id))
				return;

			if (gLaserShots[id] == 0) {
				client_print(id, print_center, "No Optic Blasts Left");
				sh_sound_deny(id);
				return;
			}

			if (gPlayerInCooldown[id]) {
				sh_sound_deny(id);
				return;
			}

			// Remember this weapon...
			gLastWeapon[id] = get_user_weapon(id);

			// switch to knife
			sh_switch_weapon(id, CSW_KNIFE);

			gUsingLaser[id] = true;

			// 1 immediate shot
			@Task_FireLaser(id);

			// multishots
			new Float:delayTime = CvarMultiShot;
			if (delayTime >= 0.1)
				set_task_ex(delayTime, "@Task_FireLaser", id, _, _, SetTask_Repeat);
		}

		case SH_KEYUP: {
			remove_task(id);
			
			if (sh_is_freezetime() || gPlayerInCooldown[id] || !gUsingLaser[id])
				return;
			
			// Use the ultimate
			new Float:cooldown = CvarCooldown;
			if (cooldown > 0.0)
				sh_set_cooldown(id, cooldown);
			
			// Reset check var
			gUsingLaser[id] = false;

			// Switch back to previous weapon...
			if (gLastWeapon[id] != CSW_KNIFE)
				sh_switch_weapon(id, gLastWeapon[id]);
		}
	}
}
//----------------------------------------------------------------------------------------------
@Task_FireLaser(attacker)
{
	if (!is_user_alive(attacker))
		return;

	new lasershots = gLaserShots[attacker];

	if (lasershots == 0) {
		client_print(attacker, print_center, "No Optic Blasts Left");
		sh_sound_deny(attacker);
		remove_task(attacker);
		return;
	}

	// Make sure still on knife
	if (get_user_weapon(attacker) != CSW_KNIFE)
		sh_switch_weapon(attacker, CSW_KNIFE);

	// Do not decrement if unlimited shots are set
	if (lasershots > 0)
		gLaserShots[attacker] = --lasershots;

	// Warn How many Blasts Left...
	if (-1 < lasershots < 6)
		client_print(attacker, print_center, "Warning: %d Optic Blast%s Left", lasershots, lasershots == 1 ? "" : "s");

	new aimVec[3], victim, targetBody;

	get_user_origin(attacker, aimVec, Origin_AimEndEyes);
	laser_effects(attacker, aimVec);

	get_user_aiming(attacker, victim, targetBody);

	if (is_user_alive(victim) && (cs_get_user_team(attacker) != cs_get_user_team(victim) || sh_friendlyfire_on())) {
		emit_sound(victim, CHAN_BODY, gSoundHit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		// Deal the damage...
		sh_extra_damage(victim, attacker, lDamage[targetBody-1], "optic blast", targetBody == 1 ? 1 : 0, SH_DMG_NORM, true);
	}
}
//----------------------------------------------------------------------------------------------
laser_effects(id, aimVec[3])
{
	emit_sound(id, CHAN_ITEM, gSoundLaser, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new origin[3];
	get_user_origin(id, origin, Origin_Eyes);

	// Dynamic light, effect world, minor entity effect
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_DLIGHT); // 27
	write_coord(origin[0]); // pos
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(10);
	write_byte(250); // r, g, b
	write_byte(0); // r, g, b
	write_byte(0); // r, g, b
	write_byte(2); // life
	write_byte(1); // decay
	message_end();

	// Beam effect between two points
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS); // 0
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(aimVec[0]);
	write_coord(aimVec[1]);
	write_coord(aimVec[2]);
	write_short(gSpriteLaser);
	write_byte(1); // framestart
	write_byte(5); // framerate
	write_byte(2); // life
	write_byte(40); // width
	write_byte(0); // noise
	write_byte(250); // r, g, b
	write_byte(0); // r, g, b
	write_byte(0); // r, g, b
	write_byte(200); // brightness
	write_byte(200); // speed
	message_end();

	// Sparks
	message_begin(MSG_PVS, SVC_TEMPENTITY);
	write_byte(TE_SPARKS); // 9
	write_coord(aimVec[0]);
	write_coord(aimVec[1]);
	write_coord(aimVec[2]);
	message_end();

	// Smoke
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE); // 5
	write_coord(aimVec[0]);
	write_coord(aimVec[1]);
	write_coord(aimVec[2]);
	write_short(gSpriteSmoke);
	write_byte(22); // 10
	write_byte(10); // 10
	message_end();

	if (CvarBurnDecals) {
		// decal and ricochet sound
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_GUNSHOTDECAL); // 109
		write_coord(aimVec[0]); //pos
		write_coord(aimVec[1]);
		write_coord(aimVec[2]);
		write_short(0); // I have no idea what thats supposed to be
		write_byte(gBurnDecal + random_num(0, 4)); //decal
		message_end();
	}
}
//----------------------------------------------------------------------------------------------
