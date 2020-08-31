/* AMX Mod X script.
*
*   [SH] Addon: Monitor (sh_addon_monitor.sma)
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
*		This plugin is intended for SuperHero Mod servers that have heroes that
*		 make it possible to have more then 255 hp or more then 999 armor.
*
*	Known Issues:
*		If using the REPLACE_HUD option, clients radar is also removed from the
*		 hud. If lots of hud messages are being displayed at the same time the
*		 monitor may flash briefly, but does not happen enough to be concerned.
*
****************************************************************************
*
*	CVARs:
*		None
*
*	Credits:
*		- OneEyed for the basis of an entity as a task
*
*	Changelog:
*	v1.7 - Sycri - 08/31/20
*	 - Added a check to verify user's xp has loaded to show level spec info
*	 - Readded HUD removement as it is now possible
*	 - Replaced FM_Think with Ham_Think
*	 - Rewrote the code using Engine instead of Fakemeta
*	 (Update requires use of SuperHero Mod 1.3.0 or above.)
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
*		- Possibly add other features instead of just HP/AP display, ie. secondary message showing info of user you aim at
*		- Maybe add a file to allow user to save location of message
*
****************************************************************************/

/****** Changeable defines requie recompile *******/


/********* Uncomment to replace HUD hp/ap **********/
// #define REPLACE_HUD

/********* Uncomment the ones you want to display **********/
#define MONITOR_HP
#define MONITOR_AP
#define MONITOR_GRAVITY
#define MONITOR_SPEED
#define MONITOR_GODMODE
#define MONITOR_SPEC


/************* Do Not Edit Below Here **************/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <sh_core_main>

#pragma semicolon 1

#if defined MONITOR_HP || defined MONITOR_SPEC
	new gUserHealth[MAX_PLAYERS + 1];
#endif

#if defined MONITOR_AP || defined MONITOR_SPEC
	new gUserArmor[MAX_PLAYERS + 1];
#endif

#if defined MONITOR_SPEC
	new gServerMaxLevel;
#endif

#if defined REPLACE_HUD
	new gmsgHideWeapon;
	#define HIDE_HUD_HEALTH (1 << 3)
#endif

new gMonitorHudSync;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Addon: Monitor", "1.7", "Sycri");

#if defined MONITOR_HP || defined MONITOR_SPEC
	register_event_ex("Health", "@Event_Health", RegisterEvent_Single);
#endif

#if defined MONITOR_AP || defined MONITOR_SPEC
	register_event_ex("Battery", "@Event_Battery", RegisterEvent_Single);
#endif

#if defined REPLACE_HUD
	gmsgHideWeapon = get_user_msgid("HideWeapon");
	register_message(gmsgHideWeapon, "@Message_HideWeapon");
#endif

	gMonitorHudSync = CreateHudSyncObj();

	new monitor = create_entity("info_target");
	if (monitor) {
		entity_set_float(monitor, EV_FL_nextthink, get_gametime() + 0.1);
		RegisterHamFromEntity(Ham_Think, monitor, "@Forward_Monitor_Think");
	}
}
//----------------------------------------------------------------------------------------------
#if defined MONITOR_SPEC
public plugin_cfg()
{
	gServerMaxLevel = sh_get_num_lvls();
}
#endif
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if (!sh_is_active() || !is_user_alive(id))
		return;

#if !defined MONITOR_SPEC
	if (is_user_bot(id))
		return;
#endif

	// Check varibles initially when spawned, mainly so hp doesn't start at 0
#if defined MONITOR_HP || defined MONITOR_SPEC
	gUserHealth[id] = get_user_health(id);
#endif
#if defined MONITOR_AP || defined MONITOR_SPEC
	gUserArmor[id] = get_user_armor(id);
#endif

#if defined REPLACE_HUD
#if defined MONITOR_SPEC
	if (!is_user_bot(id)) {
#endif
		// Remove HP and AP from screen, however radar is removed aswell
		message_begin(MSG_ONE_UNRELIABLE, gmsgHideWeapon, _, id);
		write_byte(HIDE_HUD_HEALTH);
		message_end();
#if defined MONITOR_SPEC
	}
#endif
#endif
}
//----------------------------------------------------------------------------------------------
#if defined MONITOR_HP || defined MONITOR_SPEC
@Event_Health(id)
{
	if (!sh_is_active() || !is_user_alive(id))
		return;

#if !defined MONITOR_SPEC
	if (is_user_bot(id))
		return;
#endif

	gUserHealth[id] = get_user_health(id);
}
#endif
//----------------------------------------------------------------------------------------------
#if defined MONITOR_AP || defined MONITOR_SPEC
@Event_Battery(id)
{
	if (!sh_is_active() || !is_user_alive(id))
		return;

#if !defined MONITOR_SPEC
	if (is_user_bot(id))
		return;
#endif

	gUserArmor[id] = read_data(1);
}
#endif
//----------------------------------------------------------------------------------------------
#if defined REPLACE_HUD
@Message_HideWeapon()
{
	if (!sh_is_active())
		return;

	// Block HP/AP/Radar if not being blocked, must block all 3 can not individually be done
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDE_HUD_HEALTH);
}
#endif
//----------------------------------------------------------------------------------------------
@Forward_Monitor_Think(ent)
{
	if (sh_is_active()) {
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
		static specPlayer, specPlayerLevel;
#endif

#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED || defined MONITOR_GODMODE || defined MONITOR_SPEC
		static tmp[128], len;
#endif

		static players[MAX_PLAYERS], playerCount, player, i;
		get_players_ex(players, playerCount, GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV);

		for (i = 0; i < playerCount; ++i) {
			player = players[i];
			tmp[0] = '^0';
			len = 0;

			if (is_user_alive(player)) {
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED || defined MONITOR_GODMODE
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
				len += formatex(tmp[len], charsmax(tmp) - len, "SPD %d", floatround(vector_length(velocity)));
#endif

#if defined MONITOR_GODMODE
				takeDamage = entity_get_float(player, EV_FL_takedamage);
							
				// GODMODE will only show if godmode is on
				if (takeDamage == DAMAGE_NO) {
#if defined MONITOR_HP || defined MONITOR_AP || defined MONITOR_GRAVITY || defined MONITOR_SPEED
					len += formatex(tmp[len], charsmax(tmp) - len, "  |  ");
#endif
					formatex(tmp[len], charsmax(tmp) - len, "GODMODE");
				}
#endif
				// Sets Y location
#if defined REPLACE_HUD
				set_hudmessage(255, 180, 0, 0.02, 0.97, 0, 0.0, 0.3, 0.0, 0.0);
#else
				set_hudmessage(255, 180, 0, 0.02, 0.73, 0, 0.0, 0.3, 0.0, 0.0);
#endif
				ShowSyncHudMsg(player, gMonitorHudSync, "[SH]  %s", tmp);
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

				if (sh_user_is_loaded(specPlayer)) {
					specPlayerLevel = sh_get_user_lvl(specPlayer);

					len += formatex(tmp, charsmax(tmp), "Level: %d/%d  |  XP: %d", specPlayerLevel, gServerMaxLevel, sh_get_user_xp(specPlayer));

					if (specPlayerLevel < gServerMaxLevel)
						formatex(tmp[len], charsmax(tmp) - len, "/%d", sh_get_lvl_xp(specPlayerLevel + 1));
				}

				set_hudmessage(255, 255, 255, 0.018, 0.9, 2, 0.05, 0.1, 0.01, 3.0);
				ShowSyncHudMsg(player, gMonitorHudSync, "[SH] %s^nHealth: %d  |  Armor: %d^nGravity: %d%%  |  Speed: %d", tmp, gUserHealth[specPlayer], gUserArmor[specPlayer], floatround(gravity * 100.0), floatround(vector_length(velocity)));
			}
#endif
		}
	}

	// Keep monitorloop active even if shmod is not, incase sh is turned back on
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1);

	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
