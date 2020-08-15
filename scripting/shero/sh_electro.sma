// ELECTRO! - from Marvel Comics, Spider-Man villain.

/* CVARS - copy and paste to shconfig.cfg

//Electro
electro_level 0
electro_cooldown 45		//# of seconds for cooldown between use (Default 45)
electro_searchtime 45		//# of seconds to search for a victim when key is pressed (Default 45)
electro_maxdamage 50		//Damage on first victim, amount is decreased each jump by decay rate (Default 50)
electro_jumpdecay 0.66		//Decay rate for damage and sprite line width each lightning jump (Default 0.66)
electro_jumpradius 500		//Radius to search for a lightning jump (Default 500)

*/

/*
* v1.1 - vittu - 9/27/09
*      - Cleaned up and recoded using wc3ft chain lightning as a base.
*
*   Based on a mix of wc3 and wc3ft Orc Chain Lightning.
*   Originally commented with "WC3 Chain Lightning Ripoff :D".
*/

#include <superheromod>
#include <amxmisc>

#pragma semicolon 1

#define LINE_WIDTH 80

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Electro";

new bool:gHasElectro[MAX_PLAYERS + 1];
new bool:gLightningHit[MAX_PLAYERS + 1];
new bool:gIsSearching[MAX_PLAYERS + 1];

new Float:CvarCooldown, Float:CvarJumpDecay;
new CvarSearchTime, CvarMaxDamage, CvarJumpRadius;

new const gSoundSearch[] = "turret/tu_ping.wav";
new const gSoundLightning[] = "weapons/gauss2.wav";
new gSpriteLightning;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Electro", "1.2", "AssKicR");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("electro_level", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(create_cvar("electro_cooldown", "45", .has_min = true, .min_val = 0.0), CvarCooldown);
	bind_pcvar_num(create_cvar("electro_searchtime", "45", .has_min = true, .min_val = 0.0), CvarSearchTime);
	bind_pcvar_num(create_cvar("electro_maxdamage", "50", .has_min = true, .min_val = 0.0), CvarMaxDamage);
	bind_pcvar_float(create_cvar("electro_jumpdecay", "0.66", .has_min = true, .min_val = 0.0), CvarJumpDecay);
	bind_pcvar_num(create_cvar("electro_jumpradius", "500", .has_min = true, .min_val = 0.0), CvarJumpRadius);

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Chain Lightning", "Powerful Lightning Attack that can hurt Multiple Enemies");
	sh_set_hero_bind(gHeroID);

	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	register_forward(FM_TraceLine, "@Forward_TraceLine_Post", 1);
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundSearch);
	precache_sound(gSoundLightning);
	gSpriteLightning = precache_model("sprites/lgtning.spr");
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	gHasElectro[id] = mode ? true : false;

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false;
	gIsSearching[id] = false;
	gLightningHit[id] = false;

	remove_task(id);
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if (gHeroID != heroID || sh_is_freezetime() || !is_user_alive(id))
		return;

	if (gIsSearching[id])
		return;

	if (key == SH_KEYDOWN) {
		// Let them know they already used their ultimate if they have
		if (gPlayerInCooldown[id]) {
			sh_sound_deny(id);
			return;
		}

		gIsSearching[id] = true;

		new parm[2];
		parm[0] = id;
		parm[1] = CvarSearchTime;
		@Task_ElectroSearch(parm);
	}
}
//----------------------------------------------------------------------------------------------
@Task_ElectroSearch(parm[2])
{
	new id = parm[0];
	new timeLeft = parm[1];

	// Decrement our timer
	parm[1]--;

	// User died or diconnected
	if (!is_user_alive(id) || !gHasElectro[id])
		gIsSearching[id] = false;

	// This is the last "playing" of the sound, no target was found :/
	if (timeLeft == 0)
		gIsSearching[id] = false;

	// Then we need to play the sound + flash their icon!
	if (gIsSearching[id]) {
		// Play the ping sound
		emit_sound(id, CHAN_STATIC, gSoundSearch, 1.0, ATTN_NORM, 0, PITCH_NORM);

		set_task(1.0, "@Task_ElectroSearch", id, parm, 2);
	}
}
//----------------------------------------------------------------------------------------------
@Forward_TraceLine_Post(Float:v1[3], Float:v2[3], const noMonsters, const pentToSkip)
{
	if (!sh_is_active())
		return FMRES_IGNORED;

	new victim = get_tr(TR_pHit);
	if (!is_user_alive(victim))
		return FMRES_IGNORED;

	//new attacker = pentToSkip
	if (!is_user_alive(pentToSkip) || !gHasElectro[pentToSkip] || !gIsSearching[pentToSkip])
		return FMRES_IGNORED;

	if (cs_get_user_team(pentToSkip) == cs_get_user_team(victim))
		return FMRES_IGNORED;

	new damage = CvarMaxDamage;

	electro_attack(victim, pentToSkip, damage, LINE_WIDTH, pentToSkip);

	new Float:cooldown = CvarCooldown;
	if (cooldown > 0.0)
		sh_set_cooldown(pentToSkip, cooldown);

	gIsSearching[pentToSkip] = false;

	// Now we need to search for the next "jump"
	new parm[4];
	parm[0] = victim;
	parm[1] = damage;
	parm[2] = LINE_WIDTH;
	parm[3] = pentToSkip;

	set_task(0.2, "@Task_ElectroJumpCheck", pentToSkip, parm, 4);

	return FMRES_IGNORED;
}
//----------------------------------------------------------------------------------------------
@Task_ElectroJumpCheck(parm[4])
{
	// parm[0] = victim
	// parm[1] = damage
	// parm[2] = linewidth
	// parm[3] = attacker

	new lastVictim = parm[0];
	new players[MAX_PLAYERS], playerCount, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	new Float:decay = CvarJumpDecay;

	// Damage should be decreased on each jump
	new damage = floatround(parm[1] * decay);

	if (is_user_connected(lastVictim) && damage > 0) {
		new lastVicOrigin[3];
		get_user_origin(lastVictim, lastVicOrigin);

		new attacker = parm[3];
		new CsTeams:attackerTeam = cs_get_user_team(attacker);

		new target, closestTarget, closestDistance;
		new distance, targetOrigin[3];
		new radius = CvarJumpRadius;

		// Loop through every alive player
		for (i = 0; i < playerCount; i++) {
			target = players[i];

			if (target == attacker ||  target == lastVictim)
				continue;

			if (gLightningHit[target])
				continue;

			// Make sure our target player isn't on the same team!
			if (cs_get_user_team(target) == attackerTeam)
				continue;

			get_user_origin(target, targetOrigin);
			distance = get_distance(lastVicOrigin, targetOrigin);

			// Verify the user is within range
			if (distance <= radius) {
				// This user is closest!! Lets make a note of this...
				if (distance < closestDistance || !closestTarget) {
					closestDistance = distance;
					closestTarget = target;
				}
			}
		}

		if (closestTarget) {
			// Then we have a valid target!!!

			// Decrease line width as well
			new lineWidth = floatround(parm[2] * decay);

			// Display the actual lightning
			electro_attack(closestTarget, attacker, damage, lineWidth, lastVictim);

			// Lets call this again on our next target!
			parm[0] = closestTarget;
			parm[1] = damage;
			parm[2] = lineWidth;
			set_task(0.2, "@Task_ElectroJumpCheck", attacker, parm, 4);

			return;
		}
	}

	// No valid target found - reset all lightning hit variables
	for (i = 0; i < playerCount; i++)
		gLightningHit[players[i]] = false;
}
//----------------------------------------------------------------------------------------------
electro_attack(const victim, const attacker, const damage, const linewidth, const beamStartID)
{
	// Make sure we set this user as hit, otherwise we'll hit him again
	gLightningHit[victim] = true;

	// Get the target's origin
	new Float:beamOrigin[3];
	pev(beamStartID, pev_origin, beamOrigin);

	// Damage the user
	sh_extra_damage(victim, attacker, damage, "chain lightning", 0, SH_DMG_NORM, true, false, beamOrigin);

	// Create the lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS);
	write_short(beamStartID); // start entity
	write_short(victim); // entity
	write_short(gSpriteLightning); // model
	write_byte(0); // starting frame
	write_byte(15); // frame rate
	write_byte(10); // life
	write_byte(linewidth); // line width
	write_byte(10); // noise amplitude
	write_byte(255); // r, g, b
	write_byte(255); // r, g, b
	write_byte(100); // r, g, b 125
	write_byte(200); // brightness 175
	write_byte(0); // scroll speed
	message_end();

	// Get the victim's origin
	new vicOrigin[3];
	get_user_origin(victim, vicOrigin);

	// Create an elight on the target
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_ELIGHT);
	write_short(victim); // entity
	write_coord(vicOrigin[0]); // initial position
	write_coord(vicOrigin[1]); // initial position
	write_coord(vicOrigin[2]); // initial position
	write_coord(100); // radius
	write_byte(255); // r, g, b
	write_byte(255); // r, g, b
	write_byte(100); // r, g, b
	write_byte(10); // life
	write_coord(0); // decay rate
	message_end();

	// Play the lightning sound
	emit_sound(beamStartID, CHAN_STATIC, gSoundLightning, 1.0, ATTN_NORM, 0, PITCH_NORM);
}
//----------------------------------------------------------------------------------------------
