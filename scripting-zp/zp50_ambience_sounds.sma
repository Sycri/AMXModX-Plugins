/*================================================================================
	
	----------------------------
	-*- [ZP] Ambience Sounds -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <amx_settings_api>
#include <zp50_gamemodes>

#pragma semicolon 1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

#define TASK_AMBIENCESOUNDS 100

new Array:gAmbienceSoundsHandle;
new Array:gAmbienceDurationsHandle;

public plugin_init()
{
	register_plugin("[ZP] Ambience Sounds", ZP_VERSION_STRING, "ZP Dev Team");

	register_event_ex("30", "@Event_Intermission", RegisterEvent_Global);
}

public plugin_precache()
{
	gAmbienceSoundsHandle = ArrayCreate(1, 1);
	gAmbienceDurationsHandle = ArrayCreate(1, 1);
	
	new modeName[32], key[64];
	for (new i = 0; i < zp_gamemodes_get_count(); ++i) {
		zp_gamemodes_get_name(i, modeName, charsmax(modeName));
		
		new Array:ambienceSounds = ArrayCreate(64, 1);
		formatex(key, charsmax(key), "SOUNDS (%s)", modeName);
		amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambienceSounds);
		if (ArraySize(ambienceSounds) > 0) {
			// Precache ambience sounds
			new sound[128];
			for (new soundIndex = 0; soundIndex < ArraySize(ambienceSounds); ++soundIndex) {
				ArrayGetString(ambienceSounds, soundIndex, sound, charsmax(sound));

				if (equal(sound[strlen(sound)-4], ".mp3")) {
					format(sound, charsmax(sound), "sound/%s", sound);
					precache_generic(sound);
				} else {
					precache_sound(sound);
				}
			}
		} else {
			ArrayDestroy(ambienceSounds);
			amx_save_setting_string(ZP_SETTINGS_FILE, "Ambience Sounds", key, "");
		}
		ArrayPushCell(gAmbienceSoundsHandle, ambienceSounds);
		
		new Array:ambienceDurations = ArrayCreate(1, 1);
		formatex(key, charsmax(key), "DURATIONS (%s)", modeName);
		amx_load_setting_int_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambienceDurations);
		if (ArraySize(ambienceDurations) <= 0) {
			ArrayDestroy(ambienceDurations);
			amx_save_setting_string(ZP_SETTINGS_FILE, "Ambience Sounds", key, "");
		}
		ArrayPushCell(gAmbienceDurationsHandle, ambienceDurations);
	}
}

// Event Map Ended
@Event_Intermission()
{
	// Remove ambience sounds task
	remove_task(TASK_AMBIENCESOUNDS);
}

public zp_fw_gamemodes_end()
{
	// Stop ambience sounds
	remove_task(TASK_AMBIENCESOUNDS);
}

public zp_fw_gamemodes_start()
{
	// Start ambience sounds after a mode begins
	remove_task(TASK_AMBIENCESOUNDS);
	set_task(2.0, "@Task_AmbienceSoundEffects", TASK_AMBIENCESOUNDS);
}

// Ambience Sound Effects Task
@Task_AmbienceSoundEffects(taskid)
{
	// Play a random sound depending on game mode
	new currentGameMode = zp_gamemodes_get_current();
	new Array:soundsHandle = ArrayGetCell(gAmbienceSoundsHandle, currentGameMode);
	new Array:durationsHandle = ArrayGetCell(gAmbienceDurationsHandle, currentGameMode);
	
	// No ambience sounds loaded for this mode
	if (soundsHandle == Invalid_Array || durationsHandle == Invalid_Array)
		return;
	
	// Get random sound from array
	new sound[64], rand, duration;
	rand = random_num(0, ArraySize(soundsHandle) - 1);
	ArrayGetString(soundsHandle, rand, sound, charsmax(sound));
	duration = ArrayGetCell(durationsHandle, rand);
	
	// Play it on clients
	PlaySoundToClients(sound);
	
	// Set the task for when the sound is done playing
	set_task(float(duration), "@Task_AmbienceSoundEffects", TASK_AMBIENCESOUNDS);
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound) - 4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(0, "spk ^"%s^"", sound);
}
