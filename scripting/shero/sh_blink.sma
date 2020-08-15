// BLINK! - from x-men, teleportation skill

/* CVARS - copy and paste to shconfig.cfg

//Blink
blink_level 10
blink_cooldown 1.0		//Cooldown timer between uses
blink_delay 0.1			//Delay time before the teleport occurs

*/

//---------- User Changeable Defines --------//

#define MAX_UNSTUCK_ATTEMPTS 128

#define START_DISTANCE 32

//------- Do not edit below this point ------//

#include <superheromod>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Blink";

new gBlinkSpot[MAX_PLAYERS + 1][3];

new Float:CvarCooldown, Float:CvarDelay;

new const gSoundBlink[] = "shmod/blink_teleport.wav";
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Blink", "1.1", "Sycri (Kristaps08)");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("blink_level", "10", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(create_cvar("blink_cooldown", "1.0", .has_min = true, .min_val = 0.0), CvarCooldown);
	bind_pcvar_float(create_cvar("blink_delay", "0.1", .has_min = true, .min_val = 0.0), CvarDelay);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Instant Teleport", "Point to a location and teleport in the blink of an eye!");
	sh_set_hero_bind(gHeroID);
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundBlink);
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	remove_task(id);
	gPlayerInCooldown[id] = false;
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if (gHeroID != heroID || sh_is_freezetime() || !is_user_alive(id))
		return;
	
	if (key == SH_KEYDOWN) {
		if (gPlayerInCooldown[id]) {
			sh_sound_deny(id);
			return;
		}
		
		if (get_user_weapon(id) == CSW_C4 && pev(id, pev_button) & IN_ATTACK) {
			sh_sound_deny(id);
			return;
		}
		
		new Float:cooldown = CvarCooldown;
		if (cooldown > 0.0)
			sh_set_cooldown(id, cooldown);
		
		get_user_origin(id, gBlinkSpot[id], Origin_AimEndEyes);
		
		new Float:blinkdelay = CvarDelay;
		new Float:flashtime = floatclamp(blinkdelay, 0.8, 1.2);
		
		sh_set_rendering(id, 255, 105, 180, 16, kRenderFxGlowShell);
		sh_screen_fade(id, flashtime, flashtime / 2, 255, 105, 180, 60);
		set_task(blinkdelay, "@Task_Teleport", id);
	}
}
//----------------------------------------------------------------------------------------------
@Task_Teleport(id)
{
	if (!is_user_alive(id))
		return;

	if (get_user_weapon(id) == CSW_C4 && pev(id, pev_button) & IN_ATTACK) {
		sh_sound_deny(id);
		return;
	}
	
	emit_sound(id, CHAN_AUTO, gSoundBlink, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	gBlinkSpot[id][2] += 8;
	set_user_origin(id, gBlinkSpot[id]);

	new Float:origin[3];
	pev(id, pev_origin, origin);

	new hulltype = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	if (!sh_hull_vacant(id, origin, hulltype))
		user_unstuck(id, origin, hulltype);
	
	set_task(1.0, "@Task_Unglow", id);
}
//----------------------------------------------------------------------------------------------
@Task_Unglow(id)
{
	sh_set_rendering(id);
}
//----------------------------------------------------------------------------------------------
user_unstuck(index, Float:origin[3], hulltype)
{	
	new Float:newOrigin[3];
	new attempts, dist;
	
	dist = START_DISTANCE;
	
	while (dist < 1000) { // 1000 is just incase, should never get anywhere near that
		attempts = MAX_UNSTUCK_ATTEMPTS;
		
		while (attempts--) {
			newOrigin[0] = random_float(origin[0] - dist, origin[0] + dist);
			newOrigin[1] = random_float(origin[1] - dist, origin[1] + dist);
			newOrigin[2] = random_float(origin[2] - dist, origin[2] + dist);
			
			engfunc(EngFunc_TraceHull, newOrigin, newOrigin, 0, hulltype, index, 0);
			
			if (get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2 (0, TR_StartSolid)) {
				engfunc(EngFunc_SetOrigin, index, newOrigin);
				return;
			}
		}
		
		dist += START_DISTANCE;
	}
}
//----------------------------------------------------------------------------------------------
