// SuperHero Main Include File
// Version 1.3.0

#if defined _sh_core_main_included
  #endinput
#endif
#define _sh_core_main_included

#include <amxmodx>
#include <engine>
#include <sh_core_main_const>

#pragma reqlib sh_core_main
#if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib sh_core_main
#endif


//----------------------------------------------------------------------------------------------
// IMPORTANT FUNCTIONS - WHAT EVENTS CAN THE SUPERHEROES REGISTER FOR?
//----------------------------------------------------------------------------------------------


/**************************
 *        FORWARDS        *
 **************************/

/**
 * Called when a hero is added or dropped.
 * See sh_core_main_const.inc for mode types.
 *
 * @param id			The index of the client.
 * @param heroID		The index of the hero.
 * @param mode			The heroID is being added or dropped.
 * @noreturn
 */
forward sh_hero_init(id, heroID, mode);

/**
 * Called when a +/-power is executed.
 * See sh_core_main_const.inc for key types.
 *
 * @param id			The index of the client.
 * @param heroID		The index of the hero.
 * @param key			The heroID power key function, key down or key up.
 * @noreturn
 */
forward sh_hero_key(id, heroID, key);

/**
 * Called post player spawn.
 *
 * @param id			The index of the client.
 * @param bool:newRound		True if client spawned because of a new round, else false.
 * @noreturn
 */
forward sh_client_spawn(id, bool:newRound);

/**
 * Called whenever a client dies.
 *
 * @param victim		The index of the victim.
 * @param attacker		The index of the attacker.
 * @param headshot		Equals 1 if death is by a headshot else 0.
 * @param wpnDescription	Name of the weapon that killed the victim.
 * @noreturn
 */
forward sh_client_death(victim, attacker, headshot, const wpnDescription[]);

/**
 * Called every new round (start of freezetime).
 *
 * @noreturn
 */
forward sh_round_new();

/**
 * Called at the approximate time that a round is started.
 * (0.1 seconds after the end of freezetime).
 *
 * @noreturn
 */
forward sh_round_start();

/**
 * Called at the end of every round (and on sv_restart).
 *
 * @noreturn
 */
forward sh_round_end();


/**************************
 *        NATIVES         *
 **************************/

/**
 * Whether or not there is a game in progress.
 * In round is between end of freezetime and end of round.
 *
 * @return		True if game is in round, false otherwise.
 */
native bool:sh_is_inround();

/**
 * Returns current freezetime status (new round to round start).
 * Freezetime is between the start and end mp_freezetime time.
 *
 * @return		True if game is in freezetime, false otherwise.
 */
native bool:sh_is_freezetime();

/**
 * Returns server's registered hero count.
 *
 * @note		The earliest this is guaranteed to be accurate is during plugin_cfg().
 *
 * @return		The number of registered heroes on the server.
 */
native sh_get_num_heroes();

/**
 * Returns server's max level.
 *
 * @note		The earliest this is guaranteed to be accurate is during plugin_cfg(). It needs
 *				the max level to be properly set or it will return 0.
 *
 * @return		The max number of levels of the server.
 */
native sh_get_num_lvls();

/**
 * Gets the XP given for killing a player of this level.
 *
 * @param level		The level number to check.
 * @return		The XP given for killing a player of this level, otherwise -1 if not a valid level.
 */
native sh_get_kill_xp(level);

/**
 * Gets the XP required for the level.
 *
 * @param level		The level number to check.
 * @return		The XP needed for the level, otherwise -1 if not a valid level.
 */
native sh_get_lvl_xp(level);

/**
 * Gets hero's index from the client's power slot.
 *
 * @param id		The index of the client.
 * @param powerID	The index of the power.
 * @return		The hero's index, otherwise -1 if not a valid client id or power id.
 */
native sh_get_user_hero(id, powerID);

/**
 * Gets the client's current level.
 *
 * @param id		The index of the client.
 * @return		The current level of the client, otherwise -1 if not a valid id.
 */
native sh_get_user_lvl(id);

/**
 * Sets the client's current level.
 *
 * @param id		The index of the client.
 * @param level		The level to set on the client.
 * @return		The level set on the client, otherwise -1 if not a valid level.
 */
native sh_set_user_lvl(id, level);

/**
 * Returns the client's power count.
 *
 * @param id		The index of the client.
 * @return		The current amount of powers of the client, otherwise -1 if not a valid id.
 */
native sh_get_user_powers(id);

/**
 * Gets the client's current XP.
 *
 * @param id		The index of the client.
 * @return		The current XP of the client.
 */
native sh_get_user_xp(id);

/**
 * Sets or Adds to the client's current XP.
 *
 * @param id		The index of the client.
 * @param xp		The xp to set/add on the client.
 * @param addtoxp	False to set client xp to the xp specified, true to add xp to client's current xp.
 * @return		1 if success, -1 if invalid client.
 */
native sh_set_user_xp(id, xp, bool:addtoxp = false);

/**
 * Adds to the client's current XP in the amount equal to if client killed victim.
 * As if client killed victim with sh_extra_damage, client recives the xp for that kill.
 *
 * @param id		The index of the client.
 * @param victim	The index of the client to calculate kill xp amount to add to id.
 * @param multiplier	Amount to multiply the kill xp by.
 * @noreturn
 */
native sh_add_kill_xp(id, victim, Float:multiplier = 1.0);

//------------
// Hero Creation/Property Natives
//------------
// IMPORTANT: Make sure these are set AFTER cvars are registered

/**
 * Creates the hero and returns the heroID. (Required)
 *
 * @note	This must be the first property set as it returns the hero index to be used for the rest.
 *
 * @param heroName	The name of the Hero. (max 24 characters)
 * @param pcvarMinLevel	The pcvar value for minmum Level required CVAR for the hero.
 * @return		The hero's index, -1 on failure.
 */
native sh_create_hero(const heroName[], pcvarMinLevel);

/**
 * Sets the hero's power description and help info. (Required)
 *
 * @param heroID	The index of the hero.
 * @param powerInfo	The short info for the heroes power, used in the power select menu. (max 49 characters)
 * @param powerHelp	The long description for the heroes power, hud message displayed when users chooses the hero. (max 127 characters)
 * @noreturn
 */
native sh_set_hero_info(heroID, const powerInfo[] = "", const powerHelp[] = "");

/**
 * Sets the hero to use a +power bind key. (Optional)
 * Use only if hero requires a bound key.
 *
 * @param heroID	The index of the hero.
 * @noreturn
 */
native sh_set_hero_bind(heroID);

//------------

/**
 * Gets hero's index.
 *
 * @param heroName	The name of the hero. (name must be exact spelling and case tense)
 * @return		The hero's index, -1 on failure.
 */
native sh_get_hero_id(const heroName[]);

/**
 * Gets hero's name.
 *
 * @param heroID	The index of the hero.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return		True if hero exists, otherwise false.
 */
native bool:sh_get_hero_name(heroID, name[], len);

/**
 * Checks if the client has the hero.
 *
 * @param id		The index of the client.
 * @param heroID	The index of the hero.
 * @return		True if client has hero, otherwise false.
 */
native bool:sh_user_has_hero(id, heroID);

/**
 * Checks if the client has had his XP loaded.
 *
 * @note		If CVAR sh_savexp is set to 0, then XP will not be saved
 * 				and any already connected clients after spawning next time
 * 				will have this native return true.
 *
 * @param id		The index of the client.
 * @return		True if client has had his XP loaded, otherwise false.
 */
native bool:sh_user_is_loaded(id);

/**
 * Sends a chat message thru core to append colored [SH] to front of message.
 * If heroID is supplied hero's name will be colored in parentheses ie "[SH](Batman) message displayed here"
 *
 * @note		Max characters for message without heroID supplied is 186.
 * 				Max characters for message with heroID supplied is
 * 				between 183 and 160 depending on size of hero's name.
 *
 * @param id		The index of the client.
 * @param heroID	The index of the hero, appends hero name to message. Set -1 to not append a hero name.
 * @param message	The chat message itself.
 * @noreturn
 */
native sh_chat_message(id, heroID = -1, const message[], any:...);

/**
 * Pass messages for debugging or set level to 0 and will always print message to log.
 *
 * @note		Adds "DEBUG: " to begining of message, may confuse some users if not an error.
 *
 * @param id		The index of the client.
 * @param level		The sh_debug_messages CVAR level to show the message at.
 * @param message	The message itself.
 * @noreturn
 */
native sh_debug_message(id, level, const message[],  any:...);


/**************************
 *         STOCKS         *
 **************************/

/**
 * Checks if SuperHero is currently on or off.
 *
 * @return		True if SuperHero mod is active, otherwise false.
 */
stock bool:sh_is_active()
{
	static sv_superheros;

	if (!sv_superheros)
		sv_superheros = get_cvar_pointer("sv_superheros");

	return (sv_superheros ? (get_pcvar_num(sv_superheros) ? true : false) : false);
}

/**
 * Checks if friendly fire is currently on or off.
 *
 * @return		True if friendly fire is on, otherwise false.
 */
stock bool:sh_friendlyfire_on()
{
	static mp_friendlyfire;

	if (!mp_friendlyfire)
		mp_friendlyfire = get_cvar_pointer("mp_friendlyfire");

	return (get_pcvar_num(mp_friendlyfire) ? true : false);
}

/**
 * Checks max players setting of server, better than using SH_MAXSLOTS most times.
 *
 * @return		Max players of server.
 */
#define sh_maxplayers() MaxClients

/**
 * Plays sound to inform the client they can not comply with the current action.
 *
 * @param id		The index of the client.
 * @noreturn
 */
stock sh_sound_deny(id)
{
	// gSoundDeny precached by core
	client_cmd(id, "spk %s", gSoundDeny);
}

/**
 * Creates a screen fade on the client.
 *
 * @param id		The index of the client.
 * @param fadeTime	The time in seconds the fade lasts.
 * @param holdTime	The time in seconds the fade is held.
 * @param red		The red rgb color value of the fade. (0-255)
 * @param green		The green rgb color value of the fade. (0-255)
 * @param blue		The blue rgb color value of the fade. (0-255)
 * @param alpha		The alpha transparency value of the fade. (0-255)
 * @param type		The type of fade. (see sh_core_main_const.inc)
 * @noreturn
 */
stock sh_screen_fade(id, Float:fadeTime, Float:holdTime, red, green, blue, alpha, type = SH_FFADE_IN)
{
	static msgScreenFade;

	if (!msgScreenFade)
		msgScreenFade = get_user_msgid("ScreenFade");

	// Check unsigned short range
	new fade, hold;
	fade = clamp(floatround(fadeTime * float(1<<12)), 0, 0xFFFF);
	hold = clamp(floatround(holdTime * float(1<<12)), 0, 0xFFFF);

	message_begin(MSG_ONE_UNRELIABLE, msgScreenFade, _, id);
	write_short(fade);	// fade lasts this long duration
	write_short(hold);	// fade lasts this long hold time
	write_short(type);	// fade type (in / out)
	write_byte(red);	// fade red
	write_byte(green);	// fade green
	write_byte(blue);	// fade blue
	write_byte(alpha);	// fade alpha
	message_end();
}

/**
 * Creates a screen shake on the client.
 *
 * @param id		The index of the client.
 * @param amplitude	The amount of displacement of the shake.
 * @param duration	The period of time of the shake.
 * @param frequency	The rate at which displacement of the shake is repeated.
 * @noreturn
 */
stock sh_screen_shake(id, Float:amplitude, Float:duration, Float:frequency)
{
	static msgScreenShake;

	if (!msgScreenShake)
		msgScreenShake = get_user_msgid("ScreenShake");

	// Check unsigned short range
	new amp, dura, freq;
	amp = clamp(floatround(amplitude * float(1 << 12)), 0, 0xFFFF);
	dura = clamp(floatround(duration * float(1 << 12)), 0, 0xFFFF);
	freq = clamp(floatround(frequency * float(1 << 8)), 0, 0xFFFF);

	message_begin(MSG_ONE_UNRELIABLE, msgScreenShake, _, id);
	write_short(amp);	// amplitude
	write_short(dura);	// duration
	write_short(freq);	// frequency
	message_end();
}

/**
 * Set a render on an entity.
 * To set a typical glow set fx to kRenderFxGlowShell, the alpha amount of 16 is preferred.
 * To reset a glow or render on a client use sh_set_rendering(id).
 *
 * @note		For client's, lower visiblity takes preference unless it's a render reset.
 *
 * @param entity	The index of the entity.
 * @param r		The red color rgb value of the render. (0-255)
 * @param g		The green color rgb value of the render. (0-255)
 * @param b		The blue color rgb value of the render. (0-255)
 * @param amount	The alpha transparency value of the render. (0-255)
 * @param fx		The fx type of the render. (see amxconst.inc)
 * @param render	The type of render. (see amxconst.inc)
 * @return		1 on success, 0 on failure.
 */
stock sh_set_rendering(entity, r = 255, g = 255, b = 255, amount = 16, fx = kRenderFxNone, render = kRenderNormal)
{
	if (!is_valid_ent(entity))
		return 0;

	new Float:alpha = float(amount);

	// This check is only to favor invisibility of a player over any other render expect a reset
	if (entity <= MaxClients) {
		// If client is in an alpha render do we need to block this render setting.
		if (entity_get_int(entity, EV_INT_rendermode) == kRenderTransAlpha) {

			// If just resetting render allow it to reset
			if (r != 255 || g != 255 || b != 255 || amount != 16 || fx != kRenderFxNone || render != kRenderNormal) {

				// Skip setting any other render type, allow user to stay in alpha render
				if (render != kRenderTransAlpha)
					return 0;

				// Only set alpha render if equal or less visible (equal to allow color changes etc.)
				if (alpha > entity_get_float(entity, EV_FL_renderamt))
					return 0;
			}
		}
	}

	new Float:renderColor[3];
	renderColor[0] = float(r);
	renderColor[1] = float(g);
	renderColor[2] = float(b);

	entity_set_int(entity, EV_INT_renderfx, fx);
	entity_set_vector(entity, EV_VEC_rendercolor, renderColor);
	entity_set_int(entity, EV_INT_rendermode, render);
	entity_set_float(entity, EV_FL_renderamt, alpha);

	return 1;
}

/**
 * Checks a hull to see if it is empty.
 * Good for checking if a client is or can be stuck at an origin.
 *
 * @note		While not very useful hitent is passed byref.
 * 				hitent is the index of ent in hull if any was found, otherwise 0 is passed.
 *
 * @param id		The index of the client that is ignored in the hull that is checked.
 * @param origin	The origin of the hull to check.
 * @param hullType	The type of hull to check, HULL_HEAD for crouching or HULL_HUMAN for standing. (see hlsdk_const.inc)
 * @return		True if hull is empty, otherwise false.
 */
stock bool:sh_hull_vacant(id, const Float:origin[3], hullType = HULL_HEAD, &hitent = 0)
{
	// Thanks to VEN for his is_hull_vacant stock which this is based on

	// Find an open space and ignore id in that space
	trace_hull(origin, hullType, id, DONT_IGNORE_MONSTERS);

	// byref index of what was hit, multiple things may be in hull so may not return what you expect
	hitent = traceresult(TR_Hit);

	// Is the origin's hull empty for the hull type
	if (!traceresult(TR_StartSolid) && !traceresult(TR_AllSolid) && traceresult(TR_InOpen))
		return true;

	return false;
}

/**
 * Gets a velocity to or from an origin.
 * Usually used for movement of created entities or to push players away from an explosion.
 *
 * @note		+/- speed is limited by servers sv_maxvelocity setting (default 2000)
 *				For explosions, set inital[2] a bit above final[2] to give a bit of a upward lift
 *
 * @param initial	The start origin. Generally an entity's origin on which to set velocity on.
 * @param final		The end origin. Generally the point where velocity is set to or from.
 * @param speed		Speed of the velocity to set:
 *					- Positive value will set velocity TO final vector.
 *					- Negative value will set velocity FROM final vector.
 * @param velocity	The return velocity. If a velocity is passed in, the return will add to it.
 */
stock sh_get_velocity(const Float:initial[3], const Float:final[3], Float:speed, Float:velocity[3])
{
	// Lets make sure we are within range
	static Float:sv_maxvelocity;

	if (!sv_maxvelocity)
		sv_maxvelocity = get_cvar_pointer("sv_maxvelocity");

	new Float:maxSpeed = get_pcvar_float(sv_maxvelocity);

	// Time = Distance / Speed
	new Float:time = vector_distance(initial, final) / floatclamp(speed, -maxSpeed, maxSpeed);

	// Velocity = Distance / Time
	velocity[0] += (final[0] - initial[0]) / time;
	velocity[1] += (final[1] - initial[1]) / time;
	velocity[2] += (final[2] - initial[2]) / time;
}

//------------
// Simple Functions to Help with Power Cooldowns.
//------------
// NOTE: The core will cancel cooldown task on a new spawn for safety, but
//	   the hero itself must reset the gPlayerInCooldown variable to false.

/**
 * Global variable for cooldown status.
 *
 * @noreturn
 */
stock bool:gPlayerInCooldown[MAX_PLAYERS + 1];

/**
 * Sets a cooldown in a hero.
 *
 * @param id		The index of the client.
 * @param secs		The time in seconds the cooldown lasts before it is removed.
 * @noreturn
 */
stock sh_set_cooldown(id, Float:secs)
{
	gPlayerInCooldown[id] = true;

	set_task(secs, "sh_end_cooldown", id + SH_COOLDOWN_TASKID);

	sh_debug_message(id, 5, "Cooldown Timer Started");
}

/**
 * Ends the cooldown in a hero.
 * This must be a public function since it is called by a task, rest can be stocks.
 *
 * @note		Called by cooldown through a task, so you do not need to call this.
 * 				However, it can be used to remove a cooldown earlier than task called to end it.
 *
 * @param id		The index of the client + SH_COOLDOWN_TASKID.
 * @noreturn
 */
public sh_end_cooldown(id)
{
	// This is only here incase user wants to manually end cooldown
	// before task is over, does not matter if task is not going on.
	remove_task(id);

	id -= SH_COOLDOWN_TASKID;
	gPlayerInCooldown[id] = false;

	sh_debug_message(id, 5, "Cooldown Timer Ended");
}

//------------
// Odd Stocks for core, not useful to most.
//------------

/**
 * Prints heapsize. This is ONLY used to debug runtime 3 errors.
 *
 * @note		Unused but keep incase it is needed for debugging.
 *
 * @noreturn
 */
stock print_heapsize()
{
	server_print("[SH] HeapSize: %i", heapspace());
}
