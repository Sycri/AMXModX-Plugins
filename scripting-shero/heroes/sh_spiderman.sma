// SPIDERMAN! - BASED ON SPACEDUDE'S NINJA HOOK

/* CVARS - copy and paste to shconfig.cfg

//Spiderman
spiderman_level 0
spiderman_moveacc 140		//How quickly he can move while on the hook
spiderman_reelspeed 400		//How fast hook line reels in
spiderman_hookstyle 2		//1=spacedude, 2=spacedude auto reel (spiderman), 3=cheap kids real	(batgirl)
spiderman_teamcolored 1		//1=teamcolored web lines 0=white web lines
spiderman_maxhooks 60		//Max ammout of hooks allowed (-1 is an unlimited ammount)

*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cstrike>
#include <sh_core_main>
#include <sh_core_gravity>

#pragma semicolon 1

// GLOBAL VARIABLES
#define HOOKBEAMLIFE  100
#define HOOK_DELTA_T  0.1  // units per second

new gHeroID;
new const gHeroName[] = "Spider-Man";

new bool:gHooked[MAX_PLAYERS + 1];
new gHookLocation[MAX_PLAYERS + 1][3];
new gHookLength[MAX_PLAYERS + 1];
new Float:gHookCreated[MAX_PLAYERS + 1];
new gHooksLeft[MAX_PLAYERS + 1];

new Float:CvarMoveAcc, Float:CvarReelSpeed;
new CvarHookStyle, CvarMaxHooks, CvarTeamColored;
new CvarPointerGravity;

new const gSoundWeb[] = "bullchicken/bc_bite2.wav";
new gSpriteWeb;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Spider-Man", SH_VERSION_STR, "{HOJ} Batman/JTP10181");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("spiderman_level", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_float(create_cvar("spiderman_moveacc", "140", .has_min = true, .min_val = 0.0), CvarMoveAcc);
	bind_pcvar_float(create_cvar("spiderman_reelspeed", "400", .has_min = true, .min_val = 0.0), CvarReelSpeed);
	bind_pcvar_num(create_cvar("spiderman_hookstyle", "2"), CvarHookStyle);
	bind_pcvar_num(create_cvar("spiderman_maxhooks", "60"), CvarMaxHooks);
	bind_pcvar_num(create_cvar("spiderman_teamcolored", "1"), CvarTeamColored);

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Web Swing", "Shoot Web to Swing - Jump Reels In, Duck Reels Out");
	sh_set_hero_bind(gHeroID);
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundWeb);
	gSpriteWeb = precache_model("sprites/zbeam4.spr");
}
//----------------------------------------------------------------------------------------------
public OnConfigsExecuted()
{
	bind_pcvar_num(get_cvar_pointer("sv_gravity"), CvarPointerGravity);
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

	if (gHooked[id])
		spiderman_hook_off(id);

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gHooksLeft[id] = CvarMaxHooks;

	if (gHooked[id])
		spiderman_hook_off(id);
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim)
{
	if (is_user_alive(victim) || !is_user_connected(victim))
		return;

	if (gHooked[victim])
		spiderman_hook_off(victim);
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if (gHeroID != heroID)
		return;

	switch (key) {
		case SH_KEYDOWN: {
			if (sh_is_freezetime() || gHooked[id] || !is_user_alive(id))
				return;

			new hooksleft = gHooksLeft[id];

			if (hooksleft == 0) {
				sh_sound_deny(id);
				return;
			}

			if (hooksleft > 0)
				gHooksLeft[id] = --hooksleft;

			if (-1 < hooksleft < 6)
				client_print(id, print_center, "You have %d web swing%s left", hooksleft, hooksleft == 1 ? "" : "s");

			gHooked[id] = true;
			set_user_info(id, "ROPE", "1");

			new parm[2], userOrigin[3];
			parm[0] = id;
			parm[1] = CvarHookStyle;

			get_user_origin(id, userOrigin);
			//Would a trace line be better?
			get_user_origin(id, gHookLocation[id], Origin_AimEndEyes);
			gHookLength[id] = get_distance(gHookLocation[id], userOrigin);

			set_user_gravity(id, 0.001);

			beamentpoint(id);

			emit_sound(id, CHAN_STATIC, gSoundWeb, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_task_ex(HOOK_DELTA_T, "@Task_CheckWeb", id, parm, 2, SetTask_Repeat);
		}
		case SH_KEYUP: {
			if (gHooked[id])
				spiderman_hook_off(id);
		}
	}
}
//----------------------------------------------------------------------------------------------
@Task_CheckWeb(parm[])
{
	new id = parm[0];

	//new style = parm[1]
	switch(parm[1]) {
		case 1: spiderman_physics(id, false);
		case 2: spiderman_physics(id, true);
		default: spiderman_cheapReel(id);
	}
}
//----------------------------------------------------------------------------------------------
spiderman_physics(index, bool:autoReel)
{
	if (!gHooked[index])
		return;

	if (!is_user_alive(index)) {
		spiderman_hook_off(index);
		return;
	}

	if (gHookCreated[index] + HOOKBEAMLIFE / 10 <= get_gametime())
		beamentpoint(index);

	new userOrigin[3], null[3], A[3], D[3], buttonAdjust[3], buttonPress;
	new Float:vTowards_A, Float:DvTowards_A, Float:velocity[3];

	get_user_origin(index, userOrigin);
	entity_get_vector(index, EV_VEC_velocity, velocity);

	buttonPress = entity_get_int(index, EV_INT_button);

	if (buttonPress & IN_FORWARD)
		++buttonAdjust[0];
	if (buttonPress & IN_BACK)
		--buttonAdjust[0];

	if (buttonPress & IN_MOVERIGHT)
		++buttonAdjust[1];
	if (buttonPress & IN_MOVELEFT)
		--buttonAdjust[1];

	if (buttonPress & IN_JUMP)
		++buttonAdjust[2];
	if (buttonPress & IN_DUCK)
		--buttonAdjust[2];

	if (buttonAdjust[0] || buttonAdjust[1]) {
		new userLook[3], moveDirection[3];
		get_user_origin(index, userLook, Origin_AimEndClient);
		userLook[0] -= userOrigin[0];
		userLook[1] -= userOrigin[1];

		moveDirection[0] = buttonAdjust[0] * userLook[0] + userLook[1] * buttonAdjust[1];
		moveDirection[1] = buttonAdjust[0] * userLook[1] - userLook[0] * buttonAdjust[1];
		moveDirection[2] = 0;

		new moveDist = get_distance(null, moveDirection);
		new Float:accel = CvarMoveAcc * HOOK_DELTA_T;

		velocity[0] += moveDirection[0] * accel / moveDist;
		velocity[1] += moveDirection[1] * accel / moveDist;
	}

	if (buttonAdjust[2] < 0 || (buttonAdjust[2] && gHookLength[index] >= 60)) {
		gHookLength[index] -= floatround(buttonAdjust[2] * CvarReelSpeed * HOOK_DELTA_T);
	} else if (autoReel && !(buttonPress & IN_DUCK) && gHookLength[index] >= 200) {
		buttonAdjust[2] += 1;
		gHookLength[index] -= floatround(buttonAdjust[2] * CvarReelSpeed * HOOK_DELTA_T);
	}

	A[0] = gHookLocation[index][0] - userOrigin[0];
	A[1] = gHookLocation[index][1] - userOrigin[1];
	A[2] = gHookLocation[index][2] - userOrigin[2];

	new distA = get_distance(null, A);
	distA = distA ? distA : 1; // Avoid dividing by 0

	vTowards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / distA;
	DvTowards_A = float((get_distance(userOrigin, gHookLocation[index]) - gHookLength[index]) * 4);

	D[0] = A[0] * A[2] / distA;
	D[1] = A[1] * A[2] / distA;
	D[2] = -(A[1] * A[1] + A[0] * A[0]) / distA;

	new distD = get_distance(null, D);
	if (distD > 10) {
		new Float:acceleration = (-CvarPointerGravity * D[2] / distD) * HOOK_DELTA_T;
		velocity[0] += (acceleration * D[0]) / distD;
		velocity[1] += (acceleration * D[1]) / distD;
		velocity[2] += (acceleration * D[2]) / distD;
	}

	new Float:difference = DvTowards_A - vTowards_A;

	velocity[0] += (difference * A[0]) / distA;
	velocity[1] += (difference * A[1]) / distA;
	velocity[2] += (difference * A[2]) / distA;

	entity_set_vector(index, EV_VEC_velocity, velocity);
}
//----------------------------------------------------------------------------------------------
spiderman_cheapReel(index)
{
	// Cheat Web - just drags you where you shoot it...
	if (!gHooked[index])
		return;

	if (!is_user_alive(index)) {
		spiderman_hook_off(index);
		return;
	}

	new userOrigin[3], Float:velocity[3];
	get_user_origin(index, userOrigin);

	new distance = get_distance(gHookLocation[index], userOrigin);
	if (distance > 60) {
		new Float:inverseTime = CvarReelSpeed / distance;
		velocity[0] = (gHookLocation[index][0] - userOrigin[0]) * inverseTime;
		velocity[1] = (gHookLocation[index][1] - userOrigin[1]) * inverseTime;
		velocity[2] = (gHookLocation[index][2] - userOrigin[2]) * inverseTime;
	}

	entity_set_vector(index, EV_VEC_velocity, velocity);
}
//----------------------------------------------------------------------------------------------
spiderman_hook_off(index)
{
	gHooked[index] = false;

	set_user_info(index, "ROPE", "0");

	killbeam(index);

	if (is_user_connected(index))
		sh_reset_min_gravity(index);

	remove_task(index);
}
//----------------------------------------------------------------------------------------------
beamentpoint(index)
{
	if (!is_user_connected(index))
		return;

	new rgb[3] = {250, 250, 250};

	if (CvarTeamColored) {
		switch (cs_get_user_team(index)) {
			case CS_TEAM_T: rgb = {255, 0, 0};
			case CS_TEAM_CT: rgb = {0, 0, 255};
		}
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(index);
	write_coord(gHookLocation[index][0]);
	write_coord(gHookLocation[index][1]);
	write_coord(gHookLocation[index][2]);
	write_short(gSpriteWeb); // sprite index
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(HOOKBEAMLIFE); // life
	write_byte(10); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // r, g, b
	write_byte(rgb[1]); // r, g, b
	write_byte(rgb[2]); // r, g, b
	write_byte(150); // brightness
	write_byte(0); // speed
	message_end();

	gHookCreated[index] = get_gametime();
}
//----------------------------------------------------------------------------------------------
killbeam(index)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(index);
	message_end();
}
//----------------------------------------------------------------------------------------------
