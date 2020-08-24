// GOHAN! - from Dragon Ball Z, Goku and Chi Chi's first son.

/* CVARS - copy and paste to shconfig.cfg

//Gohan
gohan_level 10
gohan_health 150		//default 150
gohan_gravity 0.40		//default 0.40 = low gravity
gohan_speed 800			//How fast he is with all weapons
gohan_healpoints 10		//The # of HP healed per second
gohan_healmax 400		//Max # HP gohan can heal to

*/

/*
* v1.2 - vittu - 6/19/05
*      - Minor code clean up.
*
* v1.1 - vittu - 3/13/05
*      - recoded from ArtofDrowning07 cleaned up code
*      - new cvar from ArtofDrowning07, gohan_healmax, you
*         can choose how much goten will heal to now
*/

#include <amxmodx>
#include <amxmisc>
#include <sh_core_main>
#include <sh_core_hpap>
#include <sh_core_speed>
#include <sh_core_gravity>

// GLOBAL VARIABLES
new gHeroID;
new const gHeroName[] = "Gohan";

new bool:gHasGohan[MAX_PLAYERS + 1];

new CvarHealPoints, CvarHealMax;
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Gohan", "1.3", "sharky");
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = create_cvar("gohan_level", "10", .has_min = true, .min_val = 0.0);
	new pcvarHealth = create_cvar("gohan_health", "150");
	new pcvarGravity = create_cvar("gohan_gravity", "0.40");
	new pcvarSpeed = create_cvar("gohan_speed", "800");
	bind_pcvar_num(create_cvar("gohan_healpoints", "10", .has_min = true, .min_val = 0.0), CvarHealPoints);
	bind_pcvar_num(create_cvar("gohan_healmax", "400"), CvarHealMax);
	
	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel);
	sh_set_hero_info(gHeroID, "Super Power-Up", "Start with more HP, gain even more each second. Jump higher, run faster!");
	sh_set_hero_hpap(gHeroID, pcvarHealth);
	sh_set_hero_speed(gHeroID, pcvarSpeed);
	sh_set_hero_grav(gHeroID, pcvarGravity);
	
	// GOHAN LOOP
	set_task_ex(1.0, "@Task_GohanLoop", _, _, _, SetTask_Repeat);
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if (gHeroID != heroID)
		return;
	
	gHasGohan[id] = mode ? true : false;
	
	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED");
}
//----------------------------------------------------------------------------------------------
@Task_GohanLoop()
{
	if (!sh_is_active())
		return;
	
	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);
	
	for (i = 0; i < playerCount; ++i) {
		player = players[i];
		
		if (gHasGohan[player])
			sh_add_hp(player, CvarHealPoints, CvarHealMax);
	}
}
//----------------------------------------------------------------------------------------------
