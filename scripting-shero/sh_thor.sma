// THOR! from Marvel Comics. Asgardian god, son of Odin, wielder of the enchanted hammer Mjolnir.

/* CVARS - copy and paste to shconfig.cfg

//Thor
thor_level 8
thor_pctofdmg 75		//Percent of Damage Taken that is dealt back at your attacker (def 75%)
thor_cooldown 45		//Amount of time before next available use (def 45)

*/

/*
* v1.2 - vittu - 12/31/05
*      - Cleaned up code.
*      - Changed damage cvar to a percent of damage taken.
*      - Changed sounds.
*      - Changed look of effects.
*
*/

#include <superheromod>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Thor";

new bool:gHasThor[MAX_PLAYERS + 1];

new CvarDamagePercentage;
new Float:CvarCooldown;

new const gSoundSpark[] = "buttons/spark5.wav";
new const gSoundThunderClap[] = "ambience/thunder_clap.wav";
new gSpriteLightning;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Thor", "1.3", "TreDizzle");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("thor_level", "8", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("thor_pctofdmg", "75", .has_min = true, .min_val = 0.0), CvarDamagePercentage);
	bind_pcvar_float(create_cvar("thor_cooldown", "45", .has_min = true, .min_val = 0.0), CvarCooldown);

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Thunder Bolt", "Return Damage with a Mighty Lightning Bolt from Thor's hammer Mjolnir!");
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundSpark);
	precache_sound(gSoundThunderClap);
	gSpriteLightning = precache_model("sprites/lgtning.spr");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	gHasThor[id] = mode ? true : false;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false;
}
//----------------------------------------------------------------------------------------------
public client_damage(attacker, victim, damage)
{
	if (!sh_is_active() || !is_user_connected(victim))
		return;
	
	if (!gHasThor[victim] || gPlayerInCooldown[victim])
		return;
	
	if (is_user_alive(attacker) && !get_user_godmode(attacker) && victim != attacker) {
		emit_sound(victim, CHAN_STATIC, gSoundThunderClap, 0.6, ATTN_NORM, 0, PITCH_NORM);
		emit_sound(attacker, CHAN_STATIC, gSoundSpark, 0.4, ATTN_NORM, 0, PITCH_NORM);
		
		new returnDamage = max(1, floatround(damage * CvarDamagePercentage * 0.01));
		sh_extra_damage(attacker, victim, returnDamage, "thunder bolt");
		
		returnDamage = clamp(returnDamage, 20, 70);
		lightning_effect(victim, attacker, returnDamage);
		
		new alphanum = clamp((damage * 2), 40, 200);
		sh_screen_fade(attacker, 1.0, 0.5, 255, 255, 224, alphanum);
		sh_screen_shake(attacker, 1.2, 1.0, 1.4);

		if (is_user_alive(victim)) {
			new Float:cooldown = CvarCooldown;
			if (cooldown > 0.0)
				sh_set_cooldown(victim, cooldown);
		}
	}
}
//----------------------------------------------------------------------------------------------
lightning_effect(id, targetid, lineWidth)
{
	// Main Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS); // 8
	write_short(id); // start entity
	write_short(targetid); // entity
	write_short(gSpriteLightning); // model
	write_byte(0); // starting frame
	write_byte(200); // frame rate
	write_byte(15); // life
	write_byte(lineWidth); // line width
	write_byte(6); // noise amplitude
	write_byte(255); // r, g, b
	write_byte(255); // r, g, b
	write_byte(224); // r, g, b
	write_byte(125); // brightness
	write_byte(0); // scroll speed
	message_end();

	// Extra Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS); // 8
	write_short(id); // start entity
	write_short(targetid); // entity
	write_short(gSpriteLightning); // model
	write_byte(10); // starting frame
	write_byte(200); // frame rate
	write_byte(15); // life
	write_byte(floatround(lineWidth / 2.5)); // line width
	write_byte(18); // noise amplitude
	write_byte(255); // r, g, b
	write_byte(255); // r, g, b
	write_byte(224); // r, g, b
	write_byte(125); // brightness
	write_byte(0); // scroll speed
	message_end();
}
//----------------------------------------------------------------------------------------------