// PHOENIX! - The fiery bird from Mythology. Rebirth from the ashes of it's burning death.

/* CVARS copy and paste to shconfig.cfg

//Phoenix
phoenix_level 8
phoenix_cooldown 120	//Ammount of time before next available respawn (Default 120)
phoenix_radius 375		//Radius of people affected by blast (Default 375)
phoenix_maxdamage 90	//Maximum damage dealt spread over radius (Default 90)

*/

/*
* v1.1 - vittu - 12/31/05
*      - Code cleaned up.
*      - Fixed respawn issues.
*      - Changed damage to be an actual radius damage.
*      - Added extra sound.
*
*   Hero based on Chucky for respawn, Agent for teleport, and Kamikaze for blowing up.
*/

//---------- User Changeable Defines --------//

#define MAX_UNSTUCK_ATTEMPTS 128

#define START_DISTANCE 32

//------- Do not edit below this point ------//

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_hpap>
#include <sh_core_extradamage>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Phoenix";

new bool:gHasPhoenix[MAX_PLAYERS + 1];
new CsTeams:gUserTeam[MAX_PLAYERS + 1];
new Float:gVecOrigin[MAX_PLAYERS + 1][3];
new Float:gVecAngles[MAX_PLAYERS + 1][3];
new gmsgSync;

new const Float:VEC_DUCK_HULL_MIN[3] = { -16.0, -16.0, -18.0 };
new const Float:VEC_DUCK_HULL_MAX[3] = { 16.0, 16.0, 32.0 };
new const Float:VEC_DUCK_VIEW[3] = { 0.0, 0.0, 12.0 };
new const Float:VEC_NULL[3] = { 0.0, 0.0, 0.0 };

new Float:CvarCooldown, Float:CvarRadius;
new CvarMaxDamage;

new const gSoundEagle[] = "ambience/3dmeagle.wav";
new const gSoundRebirth[] = "ambience/port_suckin1.wav";
new gSpriteSmoke, gSpriteRing, gSpriteExplosion;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Phoenix", "1.2", "[FTW]-S.W.A.T / vittu");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("phoenix_level", "8", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(create_cvar("phoenix_cooldown", "120", .has_min = true, .min_val = 0.0), CvarCooldown);
	bind_pcvar_float(create_cvar("phoenix_radius", "375", .has_min = true, .min_val = 0.0), CvarRadius);
	bind_pcvar_num(create_cvar("phoenix_maxdamage", "90", .has_min = true, .min_val = 0.0), CvarMaxDamage);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Re-Birth", "As the Phoenix you shall Rise Again from your Burning Ashes");
	
	gmsgSync = CreateHudSyncObj();
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundEagle);
	precache_sound(gSoundRebirth);
	gSpriteSmoke = precache_model("sprites/steam1.spr");
	gSpriteRing = precache_model("sprites/white.spr");
	gSpriteExplosion = precache_model("sprites/explode1.spr");
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
	
	gHasPhoenix[id] = mode ? true : false;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim, attacker)
{
	if (!sh_is_active() || !sh_is_inround())
		return;
	
	if (!is_user_connected(victim) || is_user_alive(victim))
		return;
	
	if (!gHasPhoenix[victim] || gPlayerInCooldown[victim])
		return;
	
	gUserTeam[victim] = cs_get_user_team(victim);
	
	entity_get_vector(victim, EV_VEC_origin, gVecOrigin[victim]);
	entity_get_vector(victim, EV_VEC_v_angle, gVecAngles[victim]);
	
	// Respawn it faster then Grandmaster, let this power be used before Grandmaster's
	// Never set higher than 1.9 or lower than 0.5
	set_task(0.6, "@Task_Rebirth", victim);
}
//----------------------------------------------------------------------------------------------
@Task_Rebirth(id)
{
	if (!is_user_connected(id) || is_user_alive(id))
		return;
	
	if (!sh_is_inround() && sh_is_freezetime())
		return;
	
	if (gUserTeam[id] != cs_get_user_team(id))
		return;
	
	emit_sound(id, CHAN_STATIC, gSoundRebirth, 1.0, ATTN_NORM, 0, PITCH_NORM);
	sh_chat_message(id, gHeroID, "You used the Phoenix power to Rise Again from the Ashes!");
	
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	
	new Float:cooldown = CvarCooldown;
	if (cooldown > 0.0) 
		sh_set_cooldown(id, cooldown);
	
	emit_sound(id, CHAN_STATIC, gSoundEagle, 0.6, ATTN_NORM, 0, PITCH_NORM);
	
	sh_set_rendering(id, 248, 20, 25, 16, kRenderFxGlowShell);
	set_task(3.0, "@Task_Unglow", id);
	
	// Need to delay setting half max health because SuperHero mod sets health
	set_task(0.1, "@Task_SetHealth", id);

	phoenix_teleport(id);
	rebirth_explosion(id);

	new hullType = (entity_get_int(id, EV_INT_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	if (!sh_hull_vacant(id, gVecOrigin[id], hullType))
		user_unstuck(id, gVecOrigin[id], hullType);
}
//----------------------------------------------------------------------------------------------
@Task_Unglow(id)
{
	sh_set_rendering(id);
}
//----------------------------------------------------------------------------------------------
@Task_SetHealth(id)
{
	set_user_health(id, sh_get_max_hp(id) / 2);
}
//----------------------------------------------------------------------------------------------
public sh_round_end()
{
	static players[MAX_PLAYERS], playerCount, player;
	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);

	for (new i = 0; i < playerCount; ++i) {
		player = players[i];

		remove_task(player);
		gPlayerInCooldown[player] = false;
	}
}
//----------------------------------------------------------------------------------------------
phoenix_teleport(id)
{
	// Thanks to Connor for duck and angles part
	if (is_user_alive(id) && gVecOrigin[id][0]) {
		entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) | FL_DUCKING);
		entity_set_size(id, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX);
		entity_set_origin(id, gVecOrigin[id]);
		entity_set_vector(id, EV_VEC_view_ofs, VEC_DUCK_VIEW);

		entity_set_vector(id, EV_VEC_angles, gVecAngles[id]);
		entity_set_vector(id, EV_VEC_v_angle, VEC_NULL);
		entity_set_int(id, EV_INT_fixangle, 1);
	}

	// Teleport Effects
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_TELEPORT); // 11
	write_coord_f(gVecOrigin[id][0]); // start position
	write_coord_f(gVecOrigin[id][1]);
	write_coord_f(gVecOrigin[id][2]);
	message_end();
}
//----------------------------------------------------------------------------------------------
rebirth_explosion(id)
{
	static Float:dmgRatio, Float:distanceBetween, damage;
	new Float:playerOrigin[3];
	new Float:dmgRadius = CvarRadius;
	new maxDamage = CvarMaxDamage;
	new FFOn = sh_friendlyfire_on();
	
	new name[32];
	get_user_name(id, name, charsmax(name));
	
	explosion_effect(gVecOrigin[id], dmgRadius);
	
	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);
	
	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		if ((cs_get_user_team(id) == cs_get_user_team(player) && !FFOn) || player == id)
			continue;
		
		entity_get_vector(player, EV_VEC_origin, playerOrigin);
		distanceBetween = vector_distance(gVecOrigin[id], playerOrigin);
			
		if (distanceBetween < dmgRadius) {
			set_hudmessage(248, 20, 25, 0.05, 0.65, 2, 0.02, 3.0, 0.01, 0.1, -1);
			ShowSyncHudMsg(player, gmsgSync, "%s was Re-Born using the power of the Phoenix!", name);
			
			dmgRatio = distanceBetween / dmgRadius;
			damage = max(1, maxDamage - floatround(maxDamage * dmgRatio));

			sh_extra_damage(player, id, damage, "Phoenix Re-Birth");
		}
	}
}
//----------------------------------------------------------------------------------------------
explosion_effect(Float:vec1[3], Float:dmgRadius)
{
	// Ring
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, vec1, 0);
	write_byte(TE_BEAMCYLINDER); // 21
	write_coord_f(vec1[0]); // center position
	write_coord_f(vec1[1]);
	write_coord_f(vec1[2] + 10);
	write_coord_f(vec1[0]); // axis and radius
	write_coord_f(vec1[1]);
	write_coord_f(vec1[2] + (dmgRadius * 3.5));
	write_short(gSpriteRing); // sprite index
	write_byte(0); // starting frame
	write_byte(0); // frame rate in 0.1's
	write_byte(2); // life in 0.1's
	write_byte(20); // line width in 0.1's
	write_byte(0); // noise amplitude in 0.01's
	write_byte(248); // red
	write_byte(20); // green
	write_byte(25); // blue
	write_byte(255); // brightness
	write_byte(0); // scroll speed in 0.1's
	message_end();
	
	// Explosion2
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION2); // 12
	write_coord_f(vec1[0]); // start position
	write_coord_f(vec1[1]);
	write_coord_f(vec1[2]);
	write_byte(188); // starting color
	write_byte(10); // num colors
	message_end();
	
	// Explosion
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, vec1, 0);
	write_byte(TE_EXPLOSION); // 3
	write_coord_f(vec1[0]); // start position 
	write_coord_f(vec1[1]);
	write_coord_f(vec1[2]);
	write_short(gSpriteExplosion); // sprite index
	write_byte(floatround(dmgRadius / 9)); // scale in 0.1's 
	write_byte(10); // framerate
	write_byte(TE_EXPLFLAG_NONE); // flags
	message_end();
	
	// Smoke
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, vec1, 0);
	write_byte(TE_SMOKE); // 5
	write_coord_f(vec1[0]); // start position
	write_coord_f(vec1[1]);
	write_coord_f(vec1[2]);
	write_short(gSpriteSmoke); // sprite index
	write_byte(floatround(dmgRadius / 14)); // scale in 0.1's
	write_byte(10); // framerate
	message_end();
}
//----------------------------------------------------------------------------------------------
user_unstuck(index, Float:origin[3], hullType)
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
			
			if (sh_hull_vacant(index, newOrigin, hullType)) {
				entity_set_origin(index, newOrigin);
				return;
			}
		}
		
		dist += START_DISTANCE;
	}
}
//----------------------------------------------------------------------------------------------
