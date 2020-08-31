/* AMX Mod X script.
*
*	[SH] Core: Shield Restrict (sh_core_shieldrestrict.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>

#pragma semicolon 1

new gSuperHeroCount;

new bool:gHeroShieldRestrict[SH_MAXHEROS];

new bool:gShieldRestrict[MAX_PLAYERS + 1];

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Shield Restrict", SH_VERSION_STR, SH_AUTHOR_STR);
	
	RegisterHam(Ham_Touch, "weapon_shield", "@Forward_Shield_Touch_Pre");
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_shieldrestrict");

	register_native("sh_set_hero_shield", "@Native_SetHeroShield");
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	gSuperHeroCount = sh_get_num_heroes();
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	gShieldRestrict[id] = false;
}
//----------------------------------------------------------------------------------------------
// This is called when a user is buying anything (including shield)
public CS_OnBuy(id, item)
{
	if (!sh_is_active())
		return PLUGIN_CONTINUE;
	
	if (gShieldRestrict[id] && item == CSI_SHIELD) {
		console_print(id, "[SH] You are not allowed to buy a SHIELD due to a hero selection you have made");
		client_print(id, print_center, "You are not allowed to buy a SHIELD due to a hero selection you have made");
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	// Reset Shield Restriction if needed for this hero
	if (gHeroShieldRestrict[heroID]) {
		//If this is called by an added hero they must be restricted
		if (mode == SH_HERO_ADD) {
			gShieldRestrict[id] = true;
		} else {
			new heroIndex, bool:restricted = false;
			new powerCount = sh_get_user_powers(id);
			for (new i = 1; i <= powerCount; ++i) {
				heroIndex = sh_get_user_hero(id, i);
				// Test crash guard
				if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
					continue;

				if (gHeroShieldRestrict[heroIndex]) {
					restricted = true;
					break;
				}
			}
			gShieldRestrict[id] = restricted;
		}

		//If they are alive make sure they don't have a shield already
		if (gShieldRestrict[id] && is_user_alive(id)) {
			if (cs_get_user_shield(id))
				engclient_cmd(id, "drop", "weapon_shield");
		}
	}
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_shield(heroID, bool:restricted = false)
@Native_SetHeroShield()
{
	new heroIndex = get_param(1);
	
	//Have to access sh_get_num_heroes() directly because doing this during plugin_init()
	if (heroIndex < 0 || heroIndex >= sh_get_num_heroes())
		return;
		
	new restricted = get_param(2); //Shield Restricted?
	
	sh_debug_message(0, 3, "Create Hero-> HeroID: %d - Shield Restricted: %s", heroIndex, restricted ? "TRUE" : "FALSE");
	
	gHeroShieldRestrict[heroIndex] = restricted ? true : false;
}
//----------------------------------------------------------------------------------------------
@Forward_Shield_Touch_Pre(item, id)
{
	if (!sh_is_active())
		return HAM_IGNORED;
	
	if (!is_user_alive(id))
		return HAM_IGNORED;
		
	if (gShieldRestrict[id])
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
