//Invisible Man

/* CVARS - copy and paste to shconfig.cfg

//Invisible Man
invisman_level 0
invisman_alpha 50			//Min Alpha level when invisible. 0 = invisible, 255 = full visibility.
invisman_delay 5.0			//Seconds a player must be still to become fully invisibile
invisman_checkmove 1 		//0 = no movement check only shooting, 1 = check movement buttons, 2 or more = speed movement to check
invisman_checkonground 0	//Must player be on ground to be invisible (Default 0 = no, 1 = yes)

*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <csx>
#include <sh_core_main>

#pragma semicolon 1

const WEAPON_BUTTONS = IN_ATTACK | IN_ATTACK2 | IN_RELOAD | IN_USE;
const MOVEMENT_BUTTONS = IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP;

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Invisible Man";

new bool:gHasInvisibleMan[MAX_PLAYERS + 1];
new gIsInvisible[MAX_PLAYERS + 1];
new Float:gStillTime[MAX_PLAYERS + 1];

new CvarAlpha, CvarCheckOnGround;
new Float:CvarDelay, Float:CvarCheckMove;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Invisible Man", SH_VERSION_STR, "AssKicR");

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("invisman_level", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("invisman_alpha", "50", .has_min = true, .min_val = 0.0), CvarAlpha);
	bind_pcvar_float(create_cvar("invisman_delay", "5.0", .has_min = true, .min_val = 0.0), CvarDelay);
	bind_pcvar_float(create_cvar("invisman_checkmove", "1.0", .has_min = true, .min_val = 0.0), CvarCheckMove);
	bind_pcvar_num(create_cvar("invisman_checkonground", "0"), CvarCheckOnGround);

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Invisibility", "Makes you less visible and harder to see. Only works while standing/not shooting and not zooming.");

	// CHECK SOME BUTTONS
	set_task_ex(0.1, "@Task_InvisLoop", _, _, _, SetTask_Repeat);
}
//----------------------------------------------------------------------------------------------
public client_damage(attacker, victim)
{
	if (!sh_is_active() || !gHasInvisibleMan[victim])
		return;

	remove_invisibility(victim);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;

	switch (mode) {
		case SH_HERO_ADD: {
			gHasInvisibleMan[id] = true;
		}
		case SH_HERO_DROP: {
			gHasInvisibleMan[id] = false;
			remove_invisibility(id);
		}
	}

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	remove_invisibility(id);
}
//----------------------------------------------------------------------------------------------
@Task_InvisLoop()
{
	if (!sh_is_active() || sh_is_freezetime())
		return;

	static bool:setVisible;
	static buttons;
	static Float:velocity[3];
	static Float:sysTime;

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		if (!gHasInvisibleMan[player])
			continue;

		setVisible = false;

		if (CvarCheckOnGround && !(pev(player, pev_flags) & FL_ONGROUND))
			setVisible = true;

		buttons = pev(player, pev_button);

		// Always check these
		if (buttons & WEAPON_BUTTONS)
			setVisible = true;

		// Check movement? if greater then 1 check speed not keys
		switch (CvarCheckMove) {
			case 0.0: { /* 0 = no move check, do nothing */ }
			case 1.0: {
				if (buttons & MOVEMENT_BUTTONS)
					setVisible = true;
			}
			default: {
				//Check speed of player against the checkmove cvar
				pev(player, pev_velocity, velocity);
				if (vector_length(velocity) >= CvarCheckMove)
					setVisible = true;
			}
		}

		if (setVisible) {
			remove_invisibility(player);
		} else {
			// sysTime = get_systime();
			global_get(glb_time, sysTime);
			
			if (gStillTime[player] < 0.0)
				gStillTime[player] = sysTime;

			if (sysTime - CvarDelay >= gStillTime[player]) {
				if (gIsInvisible[player] != 100)
					client_print(player, print_center, "[SH]%s : 100%s cloaked", gHeroName, "%");
				
				gIsInvisible[player] = 100;
				set_invisibility(player, CvarAlpha);
			} else if (sysTime > gStillTime[player]) {
				new Float:percent = (sysTime - gStillTime[player]) / CvarDelay;
				new rPercent = floatround(percent * 100);
				
				client_print(player, print_center, "[SH]%s : %d%s cloaked", gHeroName, rPercent, "%");

				gIsInvisible[player] = rPercent;
				set_invisibility(player, floatround(255 - ((255 - CvarAlpha) * percent)));
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
set_invisibility(index, alpha)
{
	if (alpha < 100)
		sh_set_rendering(index, 8, 8, 8, alpha, kRenderFxGlowShell, kRenderTransAlpha);
	else // Using FxNone, color makes no difference, straight alpha transition
		sh_set_rendering(index, 0, 0, 0, alpha, kRenderFxNone, kRenderTransAlpha);
}
//----------------------------------------------------------------------------------------------
remove_invisibility(index)
{
	gStillTime[index] = -1.0;

	if (gIsInvisible[index] > 0) {
		sh_set_rendering(index);
		client_print(index, print_center, "[SH]%s: You are no longer cloaked", gHeroName);
	}

	gIsInvisible[index] = 0;
}
//----------------------------------------------------------------------------------------------
