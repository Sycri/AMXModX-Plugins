// BISHOP! - from X-MEN, member of the X.S.E. who is trapped in a past that is no longer his own.
// In truth he can't absorb a projectile weapons energy, but this is cs so what you gonna do.

/*

//Bishop
bishop_level 7
bishop_absorbmult 0.50		//Weapon damage taken X this cvar = damage absorbed [def=0.50]
bishop_damagemult 0.75		//Energy absorbed X this cvar = extra weapon damage dealt [def=0.75]
bishop_blastmult 2.50		//Energy absorbed X this cvar = damage that Energy Blast deals [def=2.50]
bishop_blastradius 150		//Energy Blast damage radius [def=150]

*/

/*
* v1.1 - vittu - 12/28/05
*      - Cleaned up code.
*      - Changed look and color of energy blast and hud message a bit.
*      - Fixed stored absorbed damage to be seperate for each Bishop user.
*      - Fixed Energy Blast to not repeat on user in crosshair.
*
*/

#define DMG_GRENADE (1<<24)

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Bishop"
new bool:gHasBishop[SH_MAXSLOTS+1]
new gAbsorbedDamage[SH_MAXSLOTS+1]
new gPcvarAbsorbMult, gPcvarDamageMult, gPcvarBlastMult, gPcvarBlastRadius
new bool:gCZBotRegisterHam
new bot_quota
new gSpriteLaser, gSpriteExplosion
//----------------------------------------------------------------------------------------------
public plugin_init() {
	// Plugin Info
	register_plugin("SUPERHERO Bishop", "1.2", "scoutPractice")
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("bishop_level", "7")
	gPcvarAbsorbMult = register_cvar("bishop_absorbmult", "0.50")
	gPcvarDamageMult = register_cvar("bishop_damagemult", "0.75")
	gPcvarBlastMult = register_cvar("bishop_blastmult", "2.50")
	gPcvarBlastRadius = register_cvar("bishop_blastradius", "150")
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Absorb Energy", "Absorb Damage and use it with your weapons! Or release all of it to deal even more damage.")
	sh_set_hero_bind(gHeroID)
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Pre")
	RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Post", 1)

	// BISHOP LOOP
	set_task(1.0, "bishop_loop", _, _, _, "b")
	
	bot_quota = get_cvar_pointer("bot_quota")
}
//----------------------------------------------------------------------------------------------
public plugin_precache() {
	gSpriteLaser = precache_model("sprites/laserbeam.spr")
	gSpriteExplosion = precache_model("sprites/zerogxplode.spr")
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode) {
	if(gHeroID != heroID) return
	
	gHasBishop[id] = mode ? true : false
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id) {
	gAbsorbedDamage[id] = 0
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key) {
	if(gHeroID != heroID || sh_is_freezetime() || !is_user_alive(id)) return
	
	if(key == SH_KEYDOWN) {
		if(gAbsorbedDamage[id] <= 0) {
			sh_chat_message(id, gHeroID, "You have NO energy left in reserve!")
			sh_sound_deny(id)
			return
		}
		
		release_energy(id)
	}
}
//----------------------------------------------------------------------------------------------
public client_putinserver(id) {
	if(id < 1 || id > sh_maxplayers()) return
	
	if(pev(id, pev_flags) & FL_FAKECLIENT && get_pcvar_num(bot_quota) > 0 && !gCZBotRegisterHam) {
		set_task(0.1, "czbotHookHam", id)
	}
}
//----------------------------------------------------------------------------------------------
public czbotHookHam(id) {
	if(gCZBotRegisterHam || !is_user_connected(id)) return
	
	if(pev(id, pev_flags) & FL_FAKECLIENT && get_pcvar_num(bot_quota) > 0) {
		RegisterHamFromEntity(Ham_TakeDamage, id, "fw_Player_TakeDamage_Pre")
		RegisterHamFromEntity(Ham_TakeDamage, id, "fw_Player_TakeDamage_Post", 1)
		
		gCZBotRegisterHam = true
	}
}
//----------------------------------------------------------------------------------------------
public fw_Player_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits) {
	if(!sh_is_active() || !is_user_connected(attacker)) return HAM_IGNORED
	
	if(!gHasBishop[attacker] || victim == attacker) return HAM_IGNORED
	
	if(!(damagebits & DMG_BULLET) && !(damagebits & DMG_SLASH) && !(damagebits & DMG_GRENADE)) return HAM_IGNORED
	
	if(gAbsorbedDamage[attacker] > 0) {
		static Float:energyDamage
		energyDamage = get_pcvar_float(gPcvarDamageMult) * gAbsorbedDamage[attacker]
		
		if(energyDamage > 0.0) SetHamParamFloat(4, damage += energyDamage)
	}
	return HAM_IGNORED
}
//----------------------------------------------------------------------------------------------
public fw_Player_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits) {
	if(!sh_is_active() || !is_user_connected(attacker)) return HAM_IGNORED
	
	if(!gHasBishop[victim] || victim == attacker) return HAM_IGNORED
	
	static damageAbsorbed
	damageAbsorbed = floatround(get_pcvar_float(gPcvarAbsorbMult) * damage)
	
	gAbsorbedDamage[victim] += damageAbsorbed
	client_print(victim, print_center, "You absorbed %d energy points", damageAbsorbed)
	
	new alphanum = clamp(floatround(damage * 2), 40, 200)
	sh_screen_fade(victim, 1.0, 0.5, 255, 90, 102, alphanum)
	return HAM_IGNORED
}
//----------------------------------------------------------------------------------------------
release_energy(id) {
	new userAim[3], victimOrigin[3]
	new blastDamage = floatround(get_pcvar_float(gPcvarBlastMult) * gAbsorbedDamage[id])
	new blastRadius = get_pcvar_num(gPcvarBlastRadius)
	new bool:hit = false
	
	get_user_origin(id, userAim, 3)
	
	beam_effects(id, userAim)

	for(new victim = 1; victim <= sh_maxplayers(); victim++) {
		if(!is_user_alive(victim) || victim == id || (get_user_team(id) == get_user_team(victim) && !sh_friendlyfire_on())) continue
		
		get_user_origin(victim, victimOrigin)
		
		if(get_distance(userAim, victimOrigin) <= blastRadius) {
			sh_extra_damage(victim, id, blastDamage, "Energy Blast")
			hit = true
		}
	}

	if(hit) {
		sh_chat_message(id, gHeroID, "ENERGY BLAST of %d Hit Points", blastDamage)
	}
	else {
		sh_chat_message(id, gHeroID, "Your Energy Blast MISSED!")
	}

	gAbsorbedDamage[id] = 0
}
//----------------------------------------------------------------------------------------------
beam_effects(id, userAim[3]) {
	new userEyeOrigin[3]
	get_user_origin(id, userEyeOrigin, 1)

	// Energy Beam
	message_begin(MSG_PAS, SVC_TEMPENTITY, userEyeOrigin)
	write_byte(1) // TE_BEAMENTPOINT
	write_short(id) // start entity
	write_coord(userAim[0]) // end position
	write_coord(userAim[1])
	write_coord(userAim[2])
	write_short(gSpriteLaser) // sprite index
	write_byte(0) // starting frame
	write_byte(10) // frame rate in 0.1's
	write_byte(2) // life in 0.1s
	write_byte(80) // line width in 0.1's
	write_byte(9) // noise amplitude in 0.01's
	write_byte(255) // Red
	write_byte(90) // Green
	write_byte(102) // Blue
	write_byte(150) // brightness
	write_byte(100) // scroll speed in 0.1's
	message_end()

	// Explosion (smoke, sound/effects)
	message_begin(MSG_PAS, SVC_TEMPENTITY, userAim)
	write_byte(3) // TE_EXPLOSION
	write_coord(userAim[0])	// start position
	write_coord(userAim[1])
	write_coord(userAim[2])
	write_short(gSpriteExplosion) // sprite index
	write_byte(30) // scale in 0.1's
	write_byte(30) // framerate
	write_byte(8) // flags
	message_end()
}
//----------------------------------------------------------------------------------------------
public bishop_loop() {
	if(!sh_is_active()) return
	
	static players[SH_MAXSLOTS], playerCount, player, i, message[128]
	get_players(players, playerCount, "ach")
	
	for(i = 0; i < playerCount; i++) {
		player = players[i]
		
		if(gHasBishop[player]) {
			formatex(message, charsmax(message), "Total Energy Absorbed: %i", gAbsorbedDamage[player])
			set_hudmessage(50, 50, 255, -1.0, 0.10, 0, 1.0, 1.0, 0.0, 0.0, 4)
			show_hudmessage(player, message)
		}
	}
}
//----------------------------------------------------------------------------------------------