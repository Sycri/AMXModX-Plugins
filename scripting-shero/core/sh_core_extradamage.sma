/* AMX Mod X script.
*
*	[SH] Core: Extra Damage (sh_core_extradamage.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_objectives>
#include <sh_core_extradamage_const>

#pragma semicolon 1

new gmsgTextMsg;

new CvarFreeForAll;
new CvarServerFreeForAll;

new fwd_Damage;

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin("[SH] Core: Extra Damage", SH_VERSION_STR, SH_AUTHOR_STR);

	fwd_Damage = CreateMultiForward("sh_client_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL); //victim, attacker, damage, damagebits

	RegisterHamPlayer(Ham_TakeDamage, "@Forward_Player_TakeDamage_Post", 1);

	bind_pcvar_num(get_cvar_pointer("sh_ffa"), CvarFreeForAll);

	if (cvar_exists("mp_freeforall")) // Support for ReGameDLL_CS
		bind_pcvar_num(get_cvar_pointer("mp_freeforall"), CvarServerFreeForAll);

	gmsgTextMsg = get_user_msgid("TextMsg");
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_extradamage");

	register_native("sh_extra_damage", "@Native_ExtraDamage");
}
//----------------------------------------------------------------------------------------------
//native sh_extra_damage(victim, attacker, damage, const wpnDescription[], headshot = 0, dmgMode = SH_DMG_MULT, bool:dmgStun = false, bool:dmgFFmsg = true, const dmgOrigin[3] = {0,0,0});
@Native_ExtraDamage()
{
	new victim = get_param(1);

	if (!is_user_alive(victim) || get_user_godmode(victim))
		return;

	new attacker = get_param(2);

	if (!is_user_connected(attacker))
		return;

	if (attacker == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_EXTRADMG)
		return;

	new Float:damage = float(get_param(3));

	new mode = get_param(6);

	new CsArmorType:armorType;
	new armor = cs_get_user_armor(victim, armorType);

	if (mode == SH_DMG_MULT && damage > 0.0) {
		// *** Damage calculation due to armor from: multiplayer/dlls/player.cpp ***
		// *** Note: this is not exactly CS damage method because we do not have that sdk ***
		new Float:flArmor = (damage - (damage * SH_ARMOR_RATIO)) * SH_ARMOR_BONUS;

		// Does this use more armor than we have figured for?
		if (flArmor > float(armor))
			armor = 0;
		else
			armor = floatround(armor - flArmor);
		// *** End of damage-armor calculations ***
	}

	new ent = cs_create_entity("info_target");
	if (!ent)
		return;

	new wpnDescription[32];
	get_string(4, wpnDescription, charsmax(wpnDescription));
	cs_set_ent_class(ent, wpnDescription);

	new Float:dmgOrigin[3];
	get_array_f(9, dmgOrigin, 3);

	if (dmgOrigin[0] == 0.0 && dmgOrigin[1] == 0.0 && dmgOrigin[2] == 0.0)
		// Damage origin is attacker
		pev(attacker, pev_origin, dmgOrigin);

	set_pev(ent, pev_origin, dmgOrigin);

	new kevlar = get_ent_data(victim, "CBasePlayer", "m_iKevlar");
	new team = get_ent_data(victim, "CBasePlayer", "m_iTeam");
	new headshot = get_param(5);
	new CsTeams:attackerTeam = cs_get_user_team(attacker);
	new CsTeams:victimTeam = cs_get_user_team(victim);

	switch (mode) {
		// Don't reduce armor by CS engine and ignore it when doing damage
		case SH_DMG_KILL, SH_DMG_MULT: set_ent_data(victim, "CBasePlayer", "m_iKevlar", 0);
	}

	if (headshot)
		set_ent_data(victim, "CBasePlayer", "m_bHeadshotKilled", true);

	if (attacker != victim && attackerTeam == victimTeam) {
		// new bool:dmgFFmsg = get_param(8) ? true : false;
		if ((get_param(8) || CvarFreeForAll) && !CvarServerFreeForAll)
			set_msg_block(gmsgTextMsg, BLOCK_ONCE); // Block friendly fire (... attacked a teammate) message
		
		if (CvarFreeForAll && !CvarServerFreeForAll)
			set_ent_data(victim, "CBasePlayer", "m_iTeam", team == 1 ? 2 : 1);
	}

	ExecuteHam(Ham_TakeDamage, victim, ent, attacker, damage, DMG_GENERIC);

	if (attacker != victim && attackerTeam == victimTeam && CvarFreeForAll && !CvarServerFreeForAll)
		set_ent_data(victim, "CBasePlayer", "m_iTeam", team);

	if (is_user_alive(victim)) {
		switch (mode) {
			case SH_DMG_KILL: {
				set_ent_data(victim, "CBasePlayer", "m_iKevlar", kevlar); // Reset armor
			}
			case SH_DMG_MULT: {
				set_ent_data(victim, "CBasePlayer", "m_iKevlar", kevlar); // Reset armor
				cs_set_user_armor(victim, armor, armorType); // Reduce armor manually
			}
		}

		if (headshot)
			set_ent_data(victim, "CBasePlayer", "m_bHeadshotKilled", false); // Cleanup for next attacks

		// new bool:dmgStun = get_param(7) ? true : false
		if (!get_param(7))
			set_ent_data_float(victim, "CBasePlayer", "m_flVelocityModifier", 1.0); // No painshock/slowdown
	}

	engfunc(EngFunc_RemoveEntity, ent);
}
//----------------------------------------------------------------------------------------------
@Forward_Player_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!sh_is_active())
		return HAM_IGNORED;

	if (!is_user_alive(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;

	static Float:trueDamage;
	pev(victim, pev_dmg_take, trueDamage);

	ExecuteForward(fwd_Damage, _, victim, attacker, floatround(trueDamage), damagebits);
	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
