/* AMX Mod X script.
*
*   Global Monitor (global_monitor.sma)
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
*
*	Description:
*		This plugin will display a hud message to the user showing their true
*		 current health and armor just above chat messages. Might possibly
*		 add other things into the message in the future, suggestions?
*
*	Why:
*		When a users health is over 255 in the HUD it loops over again
*		 starting from 0. When a users armor is over 999 it does not show the
*		 correct number rather it shows a hud symbol and the last few digits.
*
*	Who:
*		This plugin is intended for servers that have plugins that make
*		 it possible to have more than 255 hp or more than 999 armor.
*
*	Known Issues:
*		If lots of hud messages are being displayed at the same time the monitor
*		 may flash briefly, but does not happen enough to be concerned.
*		For bots get_user_maxspeed displays nonsensical values so their maxspeed
*		 is artifically set to display 0.
*
****************************************************************************
*
*	CVARs:
*		monitor_toggle "1"	// Enable/disable monitor hud
*
*	Credits:
*		- OneEyed for the basis of an entity as a task
*
*	Changelog:
*	v1.7 - Sycri - 08/31/20
*	 - Added ability for players to aim at another player and see their information
*	 - Added ability to see not just current velocity but also maxspeed
*	 - Removed ability for spectators to view levels and xp
*	 - Removed dependency on SuperHero mod
*	 - Replaced FM_Think with Ham_Think
*	 - Rewrote the code using Engine instead of Fakemeta
*
*	v1.6 - Jelle - 07/15/13
*	 - Fixed problem where plugin would only show up to 255 health
*	 - Replace HUD removed as that is no possible anymore
*
*	v1.5 - vittu - 10/28/10
*	 - Fixed possible issue with get_players array size.
*
*	v1.4 - vittu - 10/19/09
*	 - Changed to make each item optional
*	 - Added option to show when godmode is on
*	 - Added option to show information of player being spectated (similar to wc3ft)
*	 (Update requires use of SuperHero Mod 1.2.0 or above, also made the code ugly.)
*
*	v1.3 - vittu - 07/06/07
*	 - Fixed bug forgot to make sure entity was valid in think forward
*	 - Added requested option to show Gravity and Speed, set as disabled define because it gets checked constantly
*
*	v1.2 - vittu - 06/13/07
*	 - Conversion to Fakemeta
*	 - Optimization of code all around, much improved
*
*	v1.1 - vittu - 06/11/06
*	 - Used a hud sync object instead of taking up a single hud channel (suggested by jtp10181)
*	 - Added option to remove the hud's hp/ap and place message there (suggested by Freecode)
*
*	v1.0 - vittu - 06/05/06
*	 - Initial Release
*
*	To-Do:
*		- Maybe add a file to allow user to save location of message
*
****************************************************************************/

/****** Changeable defines requie recompile *******/


/********* Uncomment the ones you want to display **********/
#define MONITOR_HP
#define MONITOR_AP
#define MONITOR_GRAVITY
#define MONITOR_SPEED
#define MONITOR_GODMODE
#define MONITOR_SPEC
#define MONITOR_AIMING


/************* Do Not Edit Below Here **************/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

#if defined MONITOR_HP || defined MONITOR_SPEC
	new gUserHealth[MAX_PLAYERS + 1];
#endif

#if defined MONITOR_AP || defined MONITOR_SPEC
	new gUserArmor[MAX_PLAYERS + 1];
#endif

#if defined MONITOR_SPEED || defined MONITOR_SPEC
	new Float:gUserMaxSpeed[MAX_PLAYERS + 1];
#endif

new gMonitorHudSync;

new CvarToggle;

public plugin_init()
{
	register_plugin("Global Monitor", "1.7", "Sycri");

#if defined MONITOR_HP || defined MONITOR_SPEC
	register_event_ex("Health", "@Event_Health", RegisterEvent_Single);
#endif

#if defined MONITOR_AP || defined MONITOR_SPEC
	register_event_ex("Battery", "@Event_Battery", RegisterEvent_Single);
#endif

	RegisterHamPlayer(Ham_Spawn, "@Forward_PlayerSpawn_Post", 1);

#if defined MONITOR_SPEED || defined MONITOR_SPEC
	RegisterHamPlayer(Ham_AddPlayerItem, "@Forward_AddPlayerItem_Post", 1);
	RegisterHamPlayer(Ham_Player_ResetMaxSpeed, "@Forward_Player_ResetMaxSpeed_Post", 1);
#endif

	gMonitorHudSync = CreateHudSyncObj();

	new monitor = create_entity("info_target");
	if (monitor) {
		entity_set_float(monitor, EV_FL_nextthink, get_gametime() + 0.1);
		RegisterHamFromEntity(Ham_Think, monitor, "@Forward_Monitor_Think");
	}

	bind_pcvar_num(create_cvar("monitor_toggle", "1"), CvarToggle);
}

#if defined MONITOR_HP || defined MONITOR_SPEC
@Event_Health(id)
{
	if (!CvarToggle || !is_user_alive(id))
		return;

#if !defined MONITOR_SPEC
	if (is_user_bot(id))
		return;
#endif

	gUserHealth[id] = get_user_health(id);
}
#endif

#if defined MONITOR_AP || defined MONITOR_SPEC
@Event_Battery(id)
{
	if (!CvarToggle || !is_user_alive(id))
		return;

#if !defined MONITOR_SPEC
	if (is_user_bot(id))
		return;
#endif

	gUserArmor[id] = read_data(1);
}
#endif

@Forward_PlayerSpawn_Post(id)
{
	if (!CvarToggle)
		return HAM_IGNORED;

	if (!is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
		return HAM_IGNORED;

#if !defined MONITOR_SPEC
	if (is_user_bot(id))
		return HAM_IGNORED;
#endif

	// Check varibles initially when spawned, mainly so hp doesn't start at 0
#if defined MONITOR_HP || defined MONITOR_SPEC
	gUserHealth[id] = get_user_health(id);
#endif
#if defined MONITOR_AP || defined MONITOR_SPEC
	gUserArmor[id] = get_user_armor(id);
#endif
	return HAM_IGNORED;
}

#if defined MONITOR_SPEED || defined MONITOR_SPEC
@Forward_AddPlayerItem_Post(id)
{
	if (!is_user_alive(id) || is_user_bot(id))
		return HAM_IGNORED;

	gUserMaxSpeed[id] = get_user_maxspeed(id);
	return HAM_IGNORED;
}

@Forward_Player_ResetMaxSpeed_Post(id)
{
	if (!is_user_alive(id) || is_user_bot(id))
		return HAM_IGNORED;

	gUserMaxSpeed[id] = get_user_maxspeed(id);
	return HAM_IGNORED;
}
#endif

@Forward_Monitor_Think(ent)
{
	if (CvarToggle) {
#if defined MONITOR_SPEED || defined MONITOR_SPEC
		static Float:velocity[3];
#endif
#if defined MONITOR_GRAVITY || defined MONITOR_SPEC
		static Float:gravity;
#endif
#if defined MONITOR_GODMODE
		static Float:takeDamage;
#endif
#if defined MONITOR_SPEC
		static specPlayer;
#endif
#if defined MONITOR_AIMING
		static aimPlayer;
		static aimPlayerName[32];
#endif
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED || defined MONITOR_GODMODE || defined MONITOR_AIMING
		static tmp[128], len;
#endif
		static players[MAX_PLAYERS], playerCount, player, i;
		get_players_ex(players, playerCount, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV);

		for (i = 0; i < playerCount; ++i) {
			player = players[i];

			if (is_user_alive(player)) {
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED || defined MONITOR_GODMODE || defined MONITOR_AIMING
				tmp[0] = '^0';
				len = 0;

#if defined MONITOR_HP
				len += formatex(tmp, charsmax(tmp), "HP %d", gUserHealth[player]);
#endif

#if defined MONITOR_AP
#if defined MONITOR_HP
				len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
				len += formatex(tmp[len], charsmax(tmp) - len, "AP %d", gUserArmor[player]);
#endif

#if defined MONITOR_GRAVITY
#if defined MONITOR_HP || defined MONITOR_AP
				len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
				gravity = entity_get_float(player, EV_FL_gravity);
				len += formatex(tmp[len], charsmax(tmp) - len, "G %d%%", floatround(gravity * 100.0));
#endif

#if defined MONITOR_SPEED
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY
				len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
				entity_get_vector(player, EV_VEC_velocity, velocity);
				len += formatex(tmp[len], charsmax(tmp) - len, "SPD %d (%d)", floatround(vector_length(velocity)), floatround(gUserMaxSpeed[player]));
#endif

#if defined MONITOR_GODMODE
				takeDamage = entity_get_float(player, EV_FL_takedamage);
							
				// GODMODE will only show if godmode is on
				if (takeDamage == DAMAGE_NO) {
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED
					len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
					len += formatex(tmp[len], charsmax(tmp) - len, "GODMODE");
				}
#endif

#if defined MONITOR_AIMING
				get_user_aiming(player, aimPlayer);
				if (is_user_alive(aimPlayer)) {
					get_user_name(aimPlayer, aimPlayerName, charsmax(aimPlayerName));
					len += formatex(tmp[len], charsmax(tmp), "^n^nName: %s^n", aimPlayerName);
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED || defined MONITOR_GODMODE
#if defined MONITOR_HP
					len += formatex(tmp[len], charsmax(tmp), "HP %d", gUserHealth[aimPlayer]);
#endif

#if defined MONITOR_AP
#if defined MONITOR_HP
					len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
					len += formatex(tmp[len], charsmax(tmp) - len, "AP %d", gUserArmor[aimPlayer]);
#endif

#if defined MONITOR_GRAVITY
#if defined MONITOR_HP || defined MONITOR_AP
					len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
					gravity = entity_get_float(aimPlayer, EV_FL_gravity);
					len += formatex(tmp[len], charsmax(tmp) - len, "G %d%%", floatround(gravity * 100.0));
#endif

#if defined MONITOR_SPEED
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY
					len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
					entity_get_vector(aimPlayer, EV_VEC_velocity, velocity);
					len += formatex(tmp[len], charsmax(tmp) - len, "SPD %d (%d)", floatround(vector_length(velocity)), gUserMaxSpeed[aimPlayer]);
#endif

#if defined MONITOR_GODMODE
					takeDamage = entity_get_float(aimPlayer, EV_FL_takedamage);
							
				// GODMODE will only show if godmode is on
					if (takeDamage == DAMAGE_NO) {
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED
						len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
						formatex(tmp[len], charsmax(tmp) - len, "GODMODE");
					}
#endif
#endif
				}
#endif

				set_hudmessage(255, 180, 0, 0.02, 0.73, 0, 0.0, 0.3, 0.0, 0.0);
				ShowSyncHudMsg(player, gMonitorHudSync, "%s", tmp);
#endif
			}
#if defined MONITOR_SPEC
			else {
				// Who is the id specing
				specPlayer = entity_get_int(player, EV_INT_iuser2);

				if (!specPlayer || player == specPlayer)
					continue;

				entity_get_vector(specPlayer, EV_VEC_velocity, velocity);
				gravity = entity_get_float(specPlayer, EV_FL_gravity);

				set_hudmessage(255, 255, 255, 0.018, 0.9, 2, 0.05, 0.1, 0.01, 3.0);
				ShowSyncHudMsg(player, gMonitorHudSync, "Health: %d  |  Armor: %d^nGravity: %d%%  |  Speed: %d (%d)", gUserHealth[specPlayer], gUserArmor[specPlayer], floatround(gravity * 100.0), floatround(vector_length(velocity)), floatround(gUserMaxSpeed[specPlayer]));
			}
#endif
		}
	}

	// Keep monitorloop active even if shmod is not, incase sh is turned back on
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);

	return HAM_IGNORED;
}
