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

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Blink"
new gBlinkSpot[SH_MAXSLOTS+1][3]
new gPcvarCooldown, gPcvarDelay
new const gSoundBlink[] = "shmod/blink_teleport.wav"
//----------------------------------------------------------------------------------------------
public plugin_init() {
	// Plugin Info
	register_plugin("SUPERHERO Blink", "1.1", "Sycri")
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("blink_level", "10")
	gPcvarCooldown = register_cvar("blink_cooldown", "1.0")
	gPcvarDelay = register_cvar("blink_delay", "0.1")
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Instant Teleport", "Point to a location and teleport in the blink of an eye!")
	sh_set_hero_bind(gHeroID)
}
//----------------------------------------------------------------------------------------------
public plugin_precache() {
	precache_sound(gSoundBlink)
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id) {
	remove_task(id)
	gPlayerInCooldown[id] = false
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key) {
	if(gHeroID != heroID || sh_is_freezetime() || !is_user_alive(id)) return
	
	if(key == SH_KEYDOWN) {
		if(gPlayerInCooldown[id]) {
			sh_sound_deny(id)
			return
		}
		
		new clip, ammo, weapID = get_user_weapon(id, clip, ammo)
		if(weapID == CSW_C4 && pev(id, pev_button) & IN_ATTACK) {
			sh_sound_deny(id)
			return
		}
		
		sh_set_cooldown(id, get_pcvar_float(gPcvarCooldown))
		
		get_user_origin(id, gBlinkSpot[id], 3)
		
		new Float:blinkdelay = get_pcvar_float(gPcvarDelay)
		if(blinkdelay < 0.0) blinkdelay = 0.0
		
		new Float:flashtime = floatclamp(blinkdelay, 0.8, 1.2)
		
		sh_set_rendering(id, 255, 105, 180, 16, kRenderFxGlowShell)
		sh_screen_fade(id, flashtime, flashtime/2, 255, 105, 180, 60)
		set_task(blinkdelay, "task_teleport", id)
	}
}
//----------------------------------------------------------------------------------------------
public task_teleport(id) {
	new clip, ammo, weapID = get_user_weapon(id, clip, ammo)
	if(weapID == CSW_C4 && pev(id, pev_button) & IN_ATTACK) {
		sh_sound_deny(id)
		return
	}
	
	emit_sound(id, CHAN_AUTO, gSoundBlink, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	gBlinkSpot[id][2] += 8
	
	set_user_origin(id, gBlinkSpot[id])
	if(is_user_stuck(id)) user_unstuck(id, START_DISTANCE, MAX_UNSTUCK_ATTEMPTS)
	
	set_task(1.0, "task_unglow", id)
}
//----------------------------------------------------------------------------------------------
public task_unglow(id) {
	sh_set_rendering(id)
}
//----------------------------------------------------------------------------------------------
is_user_stuck(index) {
	if(!is_user_alive(index)) return -1
	
	static Float:originF[3]
	pev(index, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(index, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, index, 0)
	
	if(get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen)) return true
	
	return false
}
//----------------------------------------------------------------------------------------------
user_unstuck(index, startDistance, maxAttempts) {
	if(!is_user_alive(index)) return -1
	
	static Float:oldOriginF[3], Float:newOriginF[3]
	static attempts, distance
	
	pev(index, pev_origin, oldOriginF)
	
	distance = startDistance
	
	while(distance < 1000) {
		attempts = maxAttempts
		
		while(attempts--) {
			newOriginF[0] = random_float(oldOriginF[0] - distance, oldOriginF[0] + distance)
			newOriginF[1] = random_float(oldOriginF[1] - distance, oldOriginF[1] + distance)
			newOriginF[2] = random_float(oldOriginF[2] - distance, oldOriginF[2] + distance)
			
			engfunc(EngFunc_TraceHull, newOriginF, newOriginF, 0, (pev(index, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, index, 0)
			
			if(get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2 (0, TR_StartSolid)) {
				engfunc(EngFunc_SetOrigin, index, newOriginF)
				return true
			}
		}
		
		distance += startDistance
	}
	
	return false
}
//----------------------------------------------------------------------------------------------