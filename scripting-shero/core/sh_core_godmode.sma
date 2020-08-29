/* AMX Mod X script.
*
*   [SH] Core: Godmode (sh_core_godmode.sma)
*
*****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <sh_core_main>

#pragma semicolon 1

new gPlayerGodTimer[MAX_PLAYERS + 1];

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Godmode", SH_VERSION_STR, SH_AUTHOR_STR);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_godmode");
	
	register_native("sh_set_godmode", "@Native_SetGodmode");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	set_task_ex(1.0, "@Task_GodmodeCheck", _, _, _, SetTask_Repeat);
}
//----------------------------------------------------------------------------------------------
public client_putinserver(id)
{
	gPlayerGodTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	gPlayerGodTimer[id] = -1;
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerGodTimer[id] = -1;
	set_user_godmode(id, 0);
}
//----------------------------------------------------------------------------------------------
//native sh_set_godmode(id, Float:howLong)
@Native_SetGodmode()
{
	if (!sh_is_active())
		return;

	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	new Float:howLong = get_param_f(2);

	if (howLong > gPlayerGodTimer[id]) {
		sh_debug_message(id, 5, "Has God Mode for %f seconds", howLong);
		sh_set_rendering(id, 0, 0, 128, 16, kRenderFxGlowShell); // Remove the godmode glow, make heroes set it??
		set_user_godmode(id, 1);
		gPlayerGodTimer[id] = floatround(howLong);
	}
}
//----------------------------------------------------------------------------------------------
@Task_GodmodeCheck()
{
	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeDead | GetPlayers_ExcludeHLTV);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		// Switches are faster but we don't want to do anything with -1
		switch (gPlayerGodTimer[player]) {
			case -1: { /*Do nothing*/ }
			case 0: {
				gPlayerGodTimer[player] = -1;
				set_user_godmode(player, 0);
				sh_set_rendering(player);
			}
			default: {
				--gPlayerGodTimer[player];
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
