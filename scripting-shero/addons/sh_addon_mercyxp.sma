/* AMX Mod X script.
*
*   [SH] Addon: MercyXP (sh_addon_mercyxp.sma)
*   Copyright (C) 2020 Sycri
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
*   In addition, as a special exception, the author gives permission to
*   link the code of this program with the Half-Life Game Engine ("HL
*   Engine") and Modified Game Libraries ("MODs") developed by Valve,
*   L.L.C ("Valve"). You must obey the GNU General Public License in all
*   respects for all of the code used other than the HL Engine and MODs
*   from Valve. If you modify this file, you may extend this exception
*   to your version of the file, but you are not obligated to do so. If
*   you do not wish to do so, delete this exception statement from your
*   version.
*
****************************************************************************
*
*				******** AMX Mod X 1.90 and above Only ********
*				***** SuperHero Mod 1.3.0 and above Only ******
*				*** Must be loaded after SuperHero Mod core ***
*
*	Description:
*		This plugin functions similarly to the MercyXP system found in
*		 SuperHero Mod 1.2.0 and before. It gives players a set amount of XP
*		 at new round if a player has not gained any XP and has not killed
*		 themselves or their teammates during the previous round.
*
*	CVARs: (Please see the shconfig.cfg for the CVAR settings)
*		sh_mercyxp "0"
*		sh_mercyxpmode "1"
*		sh_minplayersxp "2"
*
*	Credits:
*		- JTP10181: For the original MercyXP system found in SuperHero Mod 1.2.0 and before
*
*	Changelog:
*	v1.0 - Sycri - 08/31/20
*	 - Initial Release
*
****************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <sh_core_main>

#pragma semicolon 1

new gPlayerStartXP[MAX_PLAYERS + 1];
new bool:gBlockMercyXP[MAX_PLAYERS + 1];
new bool:gGiveMercyXP = true;
new gActivePlayerCount;

new CvarMercyXPMode, CvarMercyXP;
new CvarFreeForAll, CvarMinPlayersXP;
new CvarServerFreeForAll;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Addon: MercyXP", "1.0", "Sycri");

	register_event_ex("TextMsg", "@Event_TextMsg_GameJoin", RegisterEvent_Global, "2&#Game_join_");
	register_logevent("@LogEvent_RoundEnd", 2, "1=Round_End");
	register_logevent("@LogEvent_RoundRestart", 2, "1&Restart_Round_");
	
	bind_pcvar_num(create_cvar("sh_mercyxp", "0", .has_min = true, .min_val = 0.0), CvarMercyXP);
	bind_pcvar_num(create_cvar("sh_mercyxpmode", "1"), CvarMercyXPMode);
	
	bind_pcvar_num(get_cvar_pointer("sh_ffa"), CvarFreeForAll);

	if (cvar_exists("sh_minplayersxp"))
		bind_pcvar_num(get_cvar_pointer("sh_minplayersxp"), CvarMinPlayersXP);
	else
		bind_pcvar_num(create_cvar("sh_minplayersxp", "2"), CvarMinPlayersXP);
	
	if (cvar_exists("mp_freeforall")) // Support for ReGameDLL_CS
		bind_pcvar_num(get_cvar_pointer("mp_freeforall"), CvarServerFreeForAll);
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	gBlockMercyXP[id] = false;
}
//----------------------------------------------------------------------------------------------
//Called when a client types "kill" in the console (engine module)
public client_kill(id)
{
	gBlockMercyXP[id] = true;
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (gGiveMercyXP && sh_user_is_loaded(id) && !gBlockMercyXP[id]) {
		if (CvarMercyXPMode != 0 && gPlayerStartXP[id] >= sh_get_user_xp(id)) {
			new XPtoGive = 0;

			switch (CvarMercyXPMode) {
				case 1: {
					XPtoGive = CvarMercyXP;
				}
				case 2: {
					new playerLevel = sh_get_user_lvl(id);

					if (playerLevel <= CvarMercyXP)
						XPtoGive = sh_get_kill_xp(CvarMercyXP - playerLevel) / 2;
				}
			}

			if (XPtoGive != 0) {
				sh_set_user_xp(id, XPtoGive, true);
				sh_chat_message(id, _, "You were given %d MercyXP points", XPtoGive);
			}
		}
		gPlayerStartXP[id] = sh_get_user_xp(id);
	}

	gBlockMercyXP[id] = false;
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim, attacker)
{
	if (victim == attacker || !is_user_connected(attacker))
		return;
		
	if (cs_get_user_team(attacker) == cs_get_user_team(victim) && !CvarFreeForAll && !CvarServerFreeForAll)
		gBlockMercyXP[attacker] = true;
}
//----------------------------------------------------------------------------------------------
@Event_TextMsg_GameJoin()
{
	gBlockMercyXP[read_data(1)] = true;
}
//----------------------------------------------------------------------------------------------
@LogEvent_RoundRestart()
{
	//Round end is not called when round is set to restart, so lets just force it right away.
	@LogEvent_RoundEnd();
	gGiveMercyXP = false;
}
//----------------------------------------------------------------------------------------------
@LogEvent_RoundEnd()
{
	gGiveMercyXP = false;

	static players[32], playerCount, player, CsTeams:playerTeam, i;
	get_players_ex(players, playerCount, GetPlayers_ExcludeHLTV);
	gActivePlayerCount = 0;

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		playerTeam = cs_get_user_team(player);

		if (playerTeam == CS_TEAM_UNASSIGNED || playerTeam == CS_TEAM_SPECTATOR)
			continue;

		++gActivePlayerCount;

		if (!gBlockMercyXP[player])
			gGiveMercyXP = true;
	}

	if (gActivePlayerCount <= CvarMinPlayersXP)
		gGiveMercyXP = false;
}
//----------------------------------------------------------------------------------------------
