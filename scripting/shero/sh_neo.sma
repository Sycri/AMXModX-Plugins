// Neo! - Right out of the Matrix!

/* CVARS - Copy and paste in shconfig.cfg

//Neo
neo_level 10
neo_health 150			//Def=150
neo_armor 350			//Def=350
neo_gravity 0.5			//Def=0.5
neo_speed 900			//Def=900
neo_flyspeed 1000		//Def=1000
neo_flybeforeftime 1	//Def=1
neo_flytoggle 0			//Def=0

*/


//---------- User Changeable Defines --------//


// Comment out to not use the Neo player model
#define USE_PLAYER_MODEL

// Comment out to not show bullets
#define SHOW_BULLETS


//------- Do not edit below this point ------//

#include <superheromod>
#include <amxmisc>

#pragma semicolon 1

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Neo";

new bool:gHasNeoPowers[MAX_PLAYERS + 1];
new bool:gIsFlying[MAX_PLAYERS + 1];
new gmsgSync;

#if defined SHOW_BULLETS
	new gLastWeapon[MAX_PLAYERS + 1];
	new gLastAmmo[MAX_PLAYERS + 1];
#endif

new CvarFlySpeed, CvarFlyBeforeFTime, CvarFlyToggle;

#if defined USE_PLAYER_MODEL
	new bool:gModelPlayerSet[MAX_PLAYERS + 1];
	new bool:gModelPlayerLoaded;
	new const gModelPlayer[] = "models/player/Neo/Neo.mdl";
	new const gModelPlayer_Name[] = "Neo";
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Neo", "1.2", "thechosenone");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("neo_level", "10", .has_min = true, .min_val = 0.0);
	new pcvarHealth = create_cvar("neo_health", "150");
	new pcvarArmor = create_cvar("neo_armor", "350");
	new pcvarGravity = create_cvar("neo_gravity", "0.5");
	new pcvarSpeed = create_cvar("neo_speed", "900");
	bind_pcvar_num(create_cvar("neo_flyspeed","1000", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 2000.0), CvarFlySpeed);
	bind_pcvar_num(create_cvar("neo_flybeforeftime","1"), CvarFlyBeforeFTime);
	bind_pcvar_num(create_cvar("neo_flytoggle","0"), CvarFlyToggle);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "The Chosen One", "Become like Neo - Gain ability to fly, have more health, armor, run faster and jump higher");
	sh_set_hero_hpap(gHeroID, pcvarHealth, pcvarArmor);
	sh_set_hero_grav(gHeroID, pcvarGravity);
	sh_set_hero_speed(gHeroID, pcvarSpeed);
	sh_set_hero_bind(gHeroID);
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
#if defined SHOW_BULLETS
	register_event_ex("CurWeapon", "@Event_CurWeapon", RegisterEvent_Single | RegisterEvent_OnlyAlive, "1=1", "3>0");
#endif

	register_forward(FM_CmdStart, "@Forward_CmdStart");

	gmsgSync = CreateHudSyncObj();
}
//----------------------------------------------------------------------------------------------
#if defined USE_PLAYER_MODEL
public plugin_precache()
{
	gModelPlayerLoaded = true;
	if(file_exists(gModelPlayer)) {
		precache_model(gModelPlayer);
	} else {
		sh_debug_message(0, 0, "Aborted loading ^"%s^", file does not exist on server", gModelPlayer);
		gModelPlayerLoaded = false;
	}
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gModelPlayerSet[id] = false;
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	if(is_user_alive(id))
		stop_flying(id);
		
	switch (mode) {
		case SH_HERO_ADD: {
			gHasNeoPowers[id] = true;
#if defined USE_PLAYER_MODEL
			if (gModelPlayerLoaded)
				set_task(1.2, "@Task_Morph", id);
#endif
		}
		case SH_HERO_DROP: {
			gHasNeoPowers[id] = false;

#if defined USE_PLAYER_MODEL
			if (gModelPlayerLoaded)
				neo_unmorph(id);
#endif
		}
	}
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (!gHasNeoPowers[id])
		return;
	
	stop_flying(id);
	
#if defined USE_PLAYER_MODEL
	if (gModelPlayerLoaded)
		set_task(1.2, "@Task_Morph", id);
#endif
}
//----------------------------------------------------------------------------------------------
public sh_client_death(id)
{
	if (!sh_is_active() || is_user_alive(id) || !gHasNeoPowers[id])
		return;
	
	stop_flying(id);

#if defined USE_PLAYER_MODEL
	if (gModelPlayerLoaded)
		neo_unmorph(id);
#endif
}
//----------------------------------------------------------------------------------------------
#if defined USE_PLAYER_MODEL
@Task_Morph(id)
{
	if (gModelPlayerSet[id] || !is_user_alive(id) || !gHasNeoPowers[id])
		return;
	
	cs_set_user_model(id, gModelPlayer_Name);
	
	set_hudmessage(50, 205, 50, -1.0, 0.40, 2, 0.02, 4.0, 0.01, 0.1, -1);
	ShowSyncHudMsg(id, gmsgSync, "You are now %s", gHeroName);
	
	gModelPlayerSet[id] = true;
}
//----------------------------------------------------------------------------------------------
neo_unmorph(index)
{
	if (gModelPlayerSet[index] && is_user_connected(index)) {
		if (is_user_alive(index)) {
			set_hudmessage(50, 205, 50, -1.0, 0.40, 2, 0.02, 4.0, 0.01, 0.1, -1);
			ShowSyncHudMsg(index, gmsgSync, "You are not %s anymore", gHeroName);
		}
		
		cs_reset_user_model(index);
		
		gModelPlayerSet[index] = false;
	}
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if (gHeroID != heroID || !is_user_alive(id))
		return;
	
	switch (key) {
		case SH_KEYDOWN: {
			if (CvarFlyToggle && gIsFlying[id]) {
				stop_flying(id);
				return;
			}
			
			start_flying(id);
		}
		case SH_KEYUP: {
			if (CvarFlyToggle)
				return;
			
			stop_flying(id);
		}
	}
}
//----------------------------------------------------------------------------------------------
start_flying(id)
{
	if (sh_is_freezetime() && !CvarFlyBeforeFTime)
		return;
	
	set_user_gravity(id, 0.000001);
	
	gIsFlying[id] = true;
	set_task_ex(1.0, "@Task_Flight", id+1199, _, _, SetTask_Repeat);
} 
//----------------------------------------------------------------------------------------------
stop_flying(id)
{
	sh_reset_min_gravity(id);
	sh_reset_max_speed(id);
	
	gIsFlying[id] = false;
	remove_task(id+1199);
}
//----------------------------------------------------------------------------------------------
@Task_Flight(id)
{
	id -= 1199;
	
	if (!sh_is_active() || !is_user_connected(id)) {
		stop_flying(id);
		return;
	}
	
	if (get_user_gravity(id) != 0.000001)
		set_user_gravity(id, 0.000001);
}
//----------------------------------------------------------------------------------------------
#if defined SHOW_BULLETS
@Event_CurWeapon(id)
{
	if (!sh_is_active())
		return;
	
	static weapID, ammo, team;
	weapID = read_data(2);
	ammo = read_data(3);
	team = get_user_team(id);
	
	if (gLastWeapon[id] == 0)
		gLastWeapon[id] = weapID;
	
	if (gLastAmmo[id] > ammo && gLastWeapon[id] == weapID) {
		static origin[3], aimVec[3], velocityVec[3], length, speed;
		
		speed = 2400;
		
		get_user_origin(id, origin);
		get_user_origin(id, aimVec, Origin_CS_LastBullet);
		
		origin[2] -= 6;
		
		velocityVec[0] = aimVec[0] - origin[0];
		velocityVec[1] = aimVec[1] - origin[1];
		velocityVec[2] = aimVec[2] - origin[2];
		
		static Float:fVelocityVec[3];
		IVecFVec(velocityVec, fVelocityVec);
		length = floatround(vector_length(fVelocityVec));
		
		velocityVec[0] *= (speed / length);
		velocityVec[1] *= (speed / length);
		velocityVec[2] *= (speed / length);
		
		static players[MAX_PLAYERS], playerCount, player, i;
		get_players_ex(players, playerCount, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV);
		
		for (i = 0; i < playerCount; i++) {
			player = players[i];
			
			if (gHasNeoPowers[player])
				draw_bullets(player, team, origin, velocityVec);
		}
	}
	
	gLastAmmo[id] = ammo;
	gLastWeapon[id] = weapID;
}
//----------------------------------------------------------------------------------------------
draw_bullets(index, indexTeam, origin[3], velocityVec[3])
{
	if (!is_user_connected(index))
		return;
	
	message_begin(MSG_ONE, SVC_TEMPENTITY, origin, index);
	write_byte(TE_USERTRACER);
	write_coord(origin[0]); // start point
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(velocityVec[0]); // end point
	write_coord(velocityVec[1]);
	write_coord(velocityVec[2]);
	write_byte(10); // byte (life * 10)
	switch (indexTeam) {
		case CS_TEAM_CT: write_byte(3);
		case CS_TEAM_T: write_byte(1);
		default: write_byte(2);
	}
	write_byte(15); // byte (length * 10)
	message_end();
}
#endif
//----------------------------------------------------------------------------------------------
@Forward_CmdStart(id, handle)
{
	if (!sh_is_active() || !is_user_alive(id) || !gIsFlying[id])
		return FMRES_IGNORED;
	
	static Float:vAngle[3], Float:velocityVec[3];
	static buttons;
	
	buttons = get_uc(handle, UC_Buttons);
	
	if (buttons & IN_FORWARD && buttons & IN_MOVERIGHT && buttons & IN_JUMP) { // FORWARD + MOVERIGHT + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		vAngle[1] -= 45;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_FORWARD && buttons & IN_MOVERIGHT && buttons & IN_DUCK) { // FORWARD + MOVERIGHT + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		vAngle[1] -= 45;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_FORWARD && buttons & IN_MOVELEFT && buttons & IN_JUMP) { // FORWARD + MOVELEFT + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		vAngle[1] += 45;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_FORWARD && buttons & IN_MOVELEFT && buttons & IN_DUCK) { // FORWARD + MOVELEFT + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		vAngle[1] += 45;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_JUMP && buttons & IN_MOVERIGHT && buttons & IN_BACK) { // BACK + MOVERIGHT + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		vAngle[1] -= 135;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_BACK && buttons & IN_MOVERIGHT && buttons & IN_DUCK) { // BACK + MOVERIGHT + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		vAngle[1] -= 135;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_JUMP && buttons & IN_MOVELEFT && buttons & IN_BACK) { // BACK + MOVELEFT + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		vAngle[1] += 135;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_BACK && buttons & IN_MOVELEFT && buttons & IN_DUCK) { // BACK + MOVELEFT + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		vAngle[1] += 135;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVERIGHT && buttons & IN_FORWARD) { // MOVERIGHT  + FORWARD
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 0.0;
		vAngle[1] -= 45;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVERIGHT && buttons & IN_BACK) { // MOVERIGHT + BACK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 0.0;
		vAngle[1] -= 135;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVELEFT && buttons & IN_FORWARD) { // MOVELEFT + FORWARD
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 0.0;
		vAngle[1] += 45;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVELEFT && buttons & IN_BACK) { // MOVELEFT + BACK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 0.0;
		vAngle[1] += 135;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_FORWARD && buttons & IN_JUMP) { // FORWARD + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_FORWARD && buttons & IN_DUCK) { // FORWARD + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_BACK && buttons & IN_JUMP) { // BACK + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= -CvarFlySpeed;
		velocityVec[1] *= -CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_BACK && buttons & IN_DUCK) { // BACK + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= -CvarFlySpeed;
		velocityVec[1] *= -CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVERIGHT && buttons & IN_JUMP) { // MOVERIGHT + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		vAngle[1] -= 90;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVERIGHT && buttons & IN_DUCK) { // MOVERIGHT + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		vAngle[1] -= 90;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVELEFT && buttons & IN_JUMP) { // MOVELEFT + JUMP
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = -45.0;
		vAngle[1] += 90;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVELEFT && buttons & IN_DUCK) { // MOVELEFT + DUCK
		pev(id, pev_v_angle, vAngle);
		
		vAngle[0] = 45.0;
		vAngle[1] += 90;
		
		angle_vector(vAngle, ANGLEVECTOR_FORWARD, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_FORWARD) { // FORWARD
		velocity_by_aim(id, CvarFlySpeed, velocityVec);
	} else if (buttons & IN_BACK) { // BACK
		velocity_by_aim(id, -CvarFlySpeed , velocityVec);
	} else if (buttons & IN_DUCK) { // DUCK
		velocityVec[0] = 0.0;
		velocityVec[1] = 0.0;
		velocityVec[2] = float(-CvarFlySpeed);
	} else if (buttons & IN_JUMP) { // JUMP
		velocityVec[0] = 0.0;
		velocityVec[1] = 0.0;
		velocityVec[2] = float(CvarFlySpeed);
	} else if (buttons & IN_MOVERIGHT) { // MOVERIGHT
		pev(id, pev_v_angle, vAngle);
		
		angle_vector(vAngle, ANGLEVECTOR_RIGHT, velocityVec);

		velocityVec[0] *= CvarFlySpeed;
		velocityVec[1] *= CvarFlySpeed;
		velocityVec[2] *= CvarFlySpeed;
	} else if (buttons & IN_MOVELEFT) { // MOVELEFT
		pev(id, pev_v_angle, vAngle);

		angle_vector(vAngle, ANGLEVECTOR_RIGHT, velocityVec);

		velocityVec[0] *= -CvarFlySpeed;
		velocityVec[1] *= -CvarFlySpeed;
		velocityVec[2] *= -CvarFlySpeed;
	} else {
		velocityVec[0] = 0.0;
		velocityVec[1] = 0.0;
		velocityVec[2] = 0.0;
	}
	
	set_pev(id, pev_velocity, velocityVec);
	
	if (pev(id, pev_sequence) != 8 && !(pev(id, pev_flags) & FL_ONGROUND) && (velocityVec[0] != 0.0 || velocityVec[1] != 0.0))
		set_pev(id, pev_sequence, 8);

	return FMRES_IGNORED;
}
//----------------------------------------------------------------------------------------------
