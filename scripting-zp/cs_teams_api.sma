/*================================================================================
	
	--------------------------
	-*- [CS] Teams API 1.3 -*-
	--------------------------
	
	- Allows easily setting a player's team in CS and CZ
	- Lets you decide whether to send the TeamInfo message to update scoreboard
	- Prevents server crashes when changing all teams at once
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>

#define TEAMCHANGE_DELAY 0.1

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" };

new Float:gTeamMsgTargetTime;
new gmsgTeamInfo, gmsgScoreInfo;

public plugin_init()
{
	register_plugin("[CS] Teams API", "1.3", "WiLS");

	register_event_ex("HLTV", "@Event_HLTV", RegisterEvent_Global, "1=0", "2=0"); // New Round
	
	gmsgTeamInfo = get_user_msgid("TeamInfo");
	gmsgScoreInfo = get_user_msgid("ScoreInfo");
}

public plugin_natives()
{
	register_library("cs_teams_api")

	register_native("cs_set_player_team", "@Native_SetPlayerTeam");
}

@Native_SetPlayerTeam(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id)) {
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id);
		return false;
	}
	
	new CsTeams:team = CsTeams:get_param(2);
	
	if (team < CS_TEAM_UNASSIGNED || team > CS_TEAM_SPECTATOR) {
		log_error(AMX_ERR_NATIVE, "[CS] Invalid team %d", _:team);
		return false;
	}
	
	fm_cs_set_user_team(id, team, bool:get_param(3));
	return true;
}

public client_disconnected(id)
{
	remove_task(id);
}

// New Round
@Event_HLTV()
{
	// CS automatically sends TeamInfo messages
	// at roundstart for all players
	for (new id = 1; id <= MaxClients; ++id)
		remove_task(id);
}

// Set a Player's Team
stock fm_cs_set_user_team(id, CsTeams:team, bool:update)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != 2)
		return;
	
	// Already belongs to the team
	if (cs_get_user_team(id) == team)
		return;
	
	// Remove previous team message task
	remove_task(id);
	
	// Set team offset
	set_ent_data(id, "CBasePlayer", "m_iTeam", _:team);
	
	// Send message to update team?
	if (update)
		fm_user_team_update(id);
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(id)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, gmsgTeamInfo);
	ewrite_byte(id) // player
	ewrite_string(CS_TEAM_NAMES[_:cs_get_user_team(id)]); // team
	emessage_end();
	
	// Fix for AMXX/CZ bots which update team paramater from ScoreInfo message
	emessage_begin(MSG_BROADCAST, gmsgScoreInfo);
	ewrite_byte(id); // id
	ewrite_short(pev(id, pev_frags)); // frags
	ewrite_short(cs_get_user_deaths(id)); // deaths
	ewrite_short(0); // class?
	ewrite_short(_:cs_get_user_team(id)); // team
	emessage_end();
}

// Update Player's Team on all clients (adding needed delays)
stock fm_user_team_update(id)
{
	static Float:currentTime;
	currentTime = get_gametime();

	if (currentTime - gTeamMsgTargetTime >= TEAMCHANGE_DELAY) {
		set_task(0.1, "fm_cs_set_user_team_msg", id);
		gTeamMsgTargetTime = currentTime + TEAMCHANGE_DELAY;
	} else {
		set_task((gTeamMsgTargetTime + TEAMCHANGE_DELAY) - currentTime, "fm_cs_set_user_team_msg", id);
		gTeamMsgTargetTime = gTeamMsgTargetTime + TEAMCHANGE_DELAY;
	}
}
