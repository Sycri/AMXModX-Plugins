/*================================================================================
	
	-----------------------------
	-*- [ZP] Ambience Effects -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check zp_readme.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_core_const>

#pragma semicolon 1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

#define FOG_VALUE_MAX_LENGTH 16

new gAmbienceRain = 0;
new gAmbienceSnow = 0;
new gAmbienceFog = 1;
new gAmbienceFogDensity[FOG_VALUE_MAX_LENGTH] = "0.0018";
new gAmbienceFogColor[FOG_VALUE_MAX_LENGTH] = "128 128 128";

new const gAmbienceEnts[][] = { "env_fog", "env_rain", "env_snow" };

new gForwardSpawn;

public plugin_init()
{
	register_plugin("[ZP] Ambience Effects", ZP_VERSION_STRING, "ZP Dev Team");

	unregister_forward(FM_Spawn, gForwardSpawn);
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG DENSITY", gAmbienceFogDensity, charsmax(gAmbienceFogDensity)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG DENSITY", gAmbienceFogDensity);
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG COLOR", gAmbienceFogColor, charsmax(gAmbienceFogColor)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG COLOR", gAmbienceFogColor);
	
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "FOG", gAmbienceFog))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "FOG", gAmbienceFog);
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "SNOW", gAmbienceSnow))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "SNOW", gAmbienceSnow);
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RAIN", gAmbienceRain))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RAIN", gAmbienceRain);
	
	if (gAmbienceFog)
	{
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"));
		if (pev_valid(ent)) {
			fm_set_kvd(ent, "density", gAmbienceFogDensity, "env_fog");
			fm_set_kvd(ent, "rendercolor", gAmbienceFogColor, "env_fog");
		}
	}
	if (gAmbienceRain)
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"));
	if (gAmbienceSnow)
		engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"));
	
	// Prevent gameplay entities from spawning
	gForwardSpawn = register_forward(FM_Spawn, "@Forward_Spawn");
}

// Entity Spawn Forward
@Forward_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	// Get classname
	new classname[32];
	pev(entity, pev_classname, classname, charsmax(classname));
	
	// Check whether it needs to be removed
	for (new i = 0; i < sizeof gAmbienceEnts; ++i) {
		if (equal(classname, gAmbienceEnts[i])) {
			engfunc(EngFunc_RemoveEntity, entity);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

// Set an entity's key value (from fakemeta_util)
stock fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname);
	set_kvd(0, KV_KeyName, key);
	set_kvd(0, KV_Value, value);
	set_kvd(0, KV_fHandled, 0);

	dllfunc(DLLFunc_KeyValue, entity, 0);
}
