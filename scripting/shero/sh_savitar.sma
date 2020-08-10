// Savitar! - from Marvel, known as God of Motion.

/* CVARS - copy and paste to shconfig.cfg

//Savitar
savitar_level 10
savitar_speed 1000			//Savitar's speed. (Def=1000)
savitar_minspeed 700		//Minimum speed to generate lightning/become invisible. (Def=700)
savitar_forceknife 0		//When running, is Savitar forced to use his knife? (Def=0)
savitar_alpha 0				//Alpha level when running. 0 = invisible, 255 = full visibility. (Def=0)
savitar_colormode 1			//0=All Lightning will be custom 1=All Lightning will be team-based 2=Extra Lightning will be custom 3=Extra Lightning will be team-based (Def=1)
savitar_color "255 215 0"	//Custom color of the lightning when running. (Def=255 215 0)
savitar_mainlwidth 10		//Width of the Main Lightning when running. (Def=10)
savitar_extralwidth 3		//Width of the Extra Lightning when running. (Def=3)

*/

#define TASK_CHECK_SPEED 1599

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Savitar"
new bool:gHasSavitar[SH_MAXSLOTS+1]
new bool:gIsMoving[SH_MAXSLOTS+1]
new const gButtonsMove = IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP
new gPcvarMinSpeed, gPcvarForceKnife, gPcvarAlpha, gPcvarColorMode, gPcvarColor, gPcvarMainLWidth, gPcvarExtraLWidth
new gSpriteLightning
//----------------------------------------------------------------------------------------------
public plugin_init() {
	// Plugin Info
	register_plugin("SUPERHERO Savitar", "1.0", "Sycri")
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("savitar_level", "10")
	new pcvarSpeed = register_cvar("savitar_speed", "1000")
	gPcvarMinSpeed = register_cvar("savitar_minspeed", "700")
	gPcvarForceKnife = register_cvar("savitar_forceknife", "0")
	gPcvarAlpha = register_cvar("savitar_alpha", "0")
	gPcvarColorMode = register_cvar("savitar_colormode", "1")
	gPcvarColor = register_cvar("savitar_color", "255 215 0")
	gPcvarMainLWidth = register_cvar("savitar_mainlwidth", "10")
	gPcvarExtraLWidth = register_cvar("savitar_extralwidth", "3")
	
	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "God of Motion", "Run insanely fast, which makes you unseenable, while generating lightning behind yourself!")
	sh_set_hero_speed(gHeroID, pcvarSpeed)
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO!
	register_forward(FM_CmdStart, "fw_CmdStart")
}
//----------------------------------------------------------------------------------------------
public plugin_precache() {
	gSpriteLightning = precache_model("sprites/lgtning.spr")
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode) {
	if(gHeroID != heroID) return
	
	gHasSavitar[id] = mode ? true : false

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id) {
	remove_task(id+TASK_CHECK_SPEED)
	gIsMoving[id] = false
	remove_trail(id)
	sh_set_rendering(id)
}
//----------------------------------------------------------------------------------------------
public sh_client_death(id) {
	remove_task(id+TASK_CHECK_SPEED)
	gIsMoving[id] = false
	remove_trail(id)
	sh_set_rendering(id)
}
//----------------------------------------------------------------------------------------------
public fw_CmdStart(id, handle) {
	if(!sh_is_active() || !is_user_alive(id) || !gHasSavitar[id]) return FMRES_IGNORED
	
	static pressedButtons
	pressedButtons = get_uc(handle, UC_Buttons)
	
	if((pressedButtons & gButtonsMove) && !task_exists(id+TASK_CHECK_SPEED)) set_task(0.1, "check_speed", id+TASK_CHECK_SPEED, _, _, "b")
	return FMRES_IGNORED
}
//----------------------------------------------------------------------------------------------
public check_speed(id) {
	id -= TASK_CHECK_SPEED
	
	static Float:userVelocity[3]
	pev(id, pev_velocity, userVelocity)
	
	if(vector_length(userVelocity) >= get_pcvar_num(gPcvarMinSpeed)) {
		if(!gIsMoving[id]) {
			gIsMoving[id] = true
			create_trail(id)
			set_invisibility(id, get_pcvar_num(gPcvarAlpha))
		}
		
		if(get_user_weapon(id) != CSW_KNIFE && get_pcvar_num(gPcvarForceKnife)) sh_switch_weapon(id, CSW_KNIFE)
	}
	
	if(vector_length(userVelocity) < get_pcvar_num(gPcvarMinSpeed)) {
		remove_task(id+TASK_CHECK_SPEED)
		gIsMoving[id] = false
		remove_trail(id)
		sh_set_rendering(id)
	}
}
//----------------------------------------------------------------------------------------------
create_trail(id) {
	static color[3], color2[3]
	
	switch(get_pcvar_num(gPcvarColorMode)) {
		case 0: {
			static colorString[15], redString[5], greenString[5], blueString[5]
			get_pcvar_string(gPcvarColor, colorString, charsmax(colorString))
			parse(colorString, redString, charsmax(redString), greenString, charsmax(greenString), blueString, charsmax(blueString))
			
			color[0] = str_to_num(redString)
			color[1] = str_to_num(greenString)
			color[2] = str_to_num(blueString)
			color2[0] = str_to_num(redString)
			color2[1] = str_to_num(greenString)
			color2[2] = str_to_num(blueString)
		}
		case 1: {
			switch(cs_get_user_team(id)) {
				case CS_TEAM_CT: {
					color = {0, 0, 255}
					color2 = {0, 0, 255}
				}
				case CS_TEAM_T: {
					color = {255, 0, 0}
					color2 = {255, 0, 0}
				}
				default: {
					color = {0, 255, 0}
					color2 = {0, 255, 0}
				}
			}
		}
		case 2: {
			static colorString[15], redString[5], greenString[5], blueString[5]
			get_pcvar_string(gPcvarColor, colorString, charsmax(colorString))
			parse(colorString, redString, charsmax(redString), greenString, charsmax(greenString), blueString, charsmax(blueString))
			
			color2[0] = str_to_num(redString)
			color2[1] = str_to_num(greenString)
			color2[2] = str_to_num(blueString)
			
			switch(cs_get_user_team(id)) {
				case CS_TEAM_CT: {
					color = {0, 0, 255}
				}
				case CS_TEAM_T: {
					color = {255, 0, 0}
				}
				default: {
					color = {0, 255, 0}
				}
			}
		}
		case 3: {
			static colorString[15], redString[5], greenString[5], blueString[5]
			get_pcvar_string(gPcvarColor, colorString, charsmax(colorString))
			parse(colorString, redString, charsmax(redString), greenString, charsmax(greenString), blueString, charsmax(blueString))
			
			color[0] = str_to_num(redString)
			color[1] = str_to_num(greenString)
			color[2] = str_to_num(blueString)
			
			switch(cs_get_user_team(id)) {
				case CS_TEAM_CT: {
					color2 = {0, 0, 255}
				}
				case CS_TEAM_T: {
					color2 = {255, 0, 0}
				}
				default: {
					color2 = {0, 255, 0}
				}
			}
		}
	}
	
	// Main Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(id)
	write_short(gSpriteLightning)
	write_byte(10) // life
	write_byte(get_pcvar_num(gPcvarMainLWidth)) // line width
	write_byte(color[0])
	write_byte(color[1])
	write_byte(color[2])
	write_byte(125) // brightness
	message_end()
	
	// Extra Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(id)
	write_short(gSpriteLightning)
	write_byte(10) // life
	write_byte(get_pcvar_num(gPcvarExtraLWidth)) // line width
	write_byte(color2[0])
	write_byte(color2[1])
	write_byte(color2[2])
	write_byte(125) // brightness
	message_end()
}
//----------------------------------------------------------------------------------------------
remove_trail(id) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(id)
	message_end()
}
//----------------------------------------------------------------------------------------------
set_invisibility(id, alpha) {
	if(alpha < 100) {
		sh_set_rendering(id, 8, 8, 8, alpha, kRenderFxGlowShell, kRenderTransAlpha)
	}
	else {
		sh_set_rendering(id, 0, 0, 0, alpha, kRenderFxNone, kRenderTransAlpha)
	}
}
//----------------------------------------------------------------------------------------------