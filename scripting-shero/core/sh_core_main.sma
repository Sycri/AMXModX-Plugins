/* AMX Mod X script.
*
*	[SH] Core: Main (sh_core_main.sma)
*
*	This plugin is part of SuperHero Mod and is distributed under the
*	terms of the GNU General Public License. Check sh_readme.txt for details.
*
*****************************************************************************/

// XP Saving Method
// **Make sure only ONE is uncommented**
//#define SAVE_METHOD 1		//Saves XP to vault.ini (Note: Use also for non-save xp to avoid loading extra modules)
#define SAVE_METHOD 2		//Saves XP to superhero nVault (default)
//#define SAVE_METHOD 3		//Saves XP to a MySQL database

//By default, plugins have 4KB of stack space.
//This gives the plugin a little more memory to work with (6144 or 24KB is sh default)
// #pragma dynamic 6144

//Sets the size of the memory table to hold data until the next save
#define gMemoryTableSize 64

//Amount of heroes at a time to display in the amx_help style console listing
#define HEROAMOUNT 10

//Lets includes detect if the core is loading them or a hero
#define SHCORE

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <sh_core_main>
#include <sh_core_objectives>
#include <sh_core_speed>

#pragma semicolon 1

new const SH_PLUGIN_STR[] = "[SH] Core: Main";

// Parms Are: Hero, Power Description, Help Info, Needs A Bind?, Level Available At
enum enumHeros { hero[25], superpower[50], help[128], requiresKeys, availableLevel };

// The Big Array that holds all of the heroes, superpowers, help, and other important info
new gSuperHeros[SH_MAXHEROS][enumHeros];
new gSuperHeroCount = 0;

// Hero level that is binded to a CVAR
new gHeroLevel[SH_MAXHEROS];

// Player bool variables (using bit-fields for lower memory footprint and better CPU performance)
#define flag_get(%1,%2)			(%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2)		(flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2)			%1 |= (1 << (%2 & 31))
#define flag_clear(%1,%2)		%1 &= ~(1 << (%2 & 31))

new gNewRoundSpawn;
new gIsPowerBanned;
new gInMenu;
new gReadXPNextRound;
new gFirstRound;
new gInPowerDown[SH_MAXBINDPOWERS + 1];
new gChangedHeroes;

// Player variables used by various functions
// Player IDs start at 1 which means we have to use MAX_PLAYERS + 1
new gPlayerPowers[MAX_PLAYERS + 1][SH_MAXLEVELS + 1];     // List of all Powers - Slot 0 is the superpower count
new gPlayerBinds[MAX_PLAYERS + 1][SH_MAXBINDPOWERS + 1];  // What superpowers are the bind keys bound
new gPlayerFlags[MAX_PLAYERS + 1];
new gPlayerMenuOffset[MAX_PLAYERS + 1];
new gPlayerMenuChoices[MAX_PLAYERS + 1][SH_MAXHEROS + 1]; // This will be filled in with # of heroes available
new gMaxPowersLeft[MAX_PLAYERS + 1][SH_MAXLEVELS + 1];
new gPlayerLevel[MAX_PLAYERS + 1];
new gPlayerXP[MAX_PLAYERS + 1];
//new Float:gLastKeydown[MAX_PLAYERS + 1]

// XP variables
new gXPLevel[SH_MAXLEVELS + 1]; // Required to reach a level
new gXPGiven[SH_MAXLEVELS + 1]; // Given per kill of a player of that level

// Other miscellaneous global variables
new gHelpHudMsg[340];
new gmsgStatusText;
new bool:gRoundStarted;
new bool:gBetweenRounds;
new gNumLevels = 0;
new gMenuID = 0;
new gHelpHudSync, gHeroHudSync;
new bool:gMonsterModRunning;

// Memory Table Variables
new gMemoryTableCount = 33;
new gMemoryTableKeys[gMemoryTableSize][32];					// Table for storing xp lines that need to be flushed to file...
new gMemoryTableNames[gMemoryTableSize][32];				// Stores players name for a key
new gMemoryTableXP[gMemoryTableSize];						// How much XP does a player have?
new gMemoryTableFlags[gMemoryTableSize];					// User flags for other settings (see below)
new gMemoryTablePowers[gMemoryTableSize][SH_MAXLEVELS + 1];	// 0=# of powers, 1=hero index, etc...

// Config Files
new gSHConfigDir[128], gBanFile[128], gSHConfig[128], gHelpMotd[128];

// CVARs Bound To Variables
new CvarSuperHeros, CvarAliveDrop, CvarAutoBalance, CvarCmdProjector;
new CvarDebugMessages, CvarEndRoundSave, Float:CvarHSMult, CvarLoadImmediate, CvarLvlLimit;
new CvarMaxBinds, CvarMaxPowers, CvarMenuMode, CvarSaveXP;
new CvarSaveBy, CvarXPSaveDays, CvarFreeForAll;
new CvarFriendlyFire, CvarLan, CvarServerFreeForAll;

// PCVARs
new sh_minlevel;

// Forwards
new fwd_HeroInit, fwd_HeroKey, fwd_Spawn, fwd_Death;
new fwd_RoundStart, fwd_RoundEnd, fwd_NewRound;

// Level up sound
new const gSoundLevel[] = "plats/elevbell1.wav";

//==============================================================================================
// XP Saving Method, do not modify this here, please see the top of the file.
#if SAVE_METHOD == 1
	#include <superherovault>	//Saves XP to vault.ini
#endif

#if SAVE_METHOD == 2
	#include <superheronvault>	//Saves XP to superhero nVault (default)
#endif

#if SAVE_METHOD == 3
	#include <superheromysql>	//Saves XP to a MySQL database
#endif
//==============================================================================================

//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Check to make sure this plugin isn't loaded already
	if (is_plugin_loaded(SH_PLUGIN_STR) > 0)
		set_fail_state("You can only load the ^"SuperHero Core^" once, please check your plugins-shero.ini");

	// Plugin Info
	register_plugin(SH_PLUGIN_STR, SH_VERSION_STR, SH_AUTHOR_STR);
	register_cvar("SuperHeroMod_Version", SH_VERSION_STR, FCVAR_SERVER | FCVAR_SPONLY);
	set_cvar_string("SuperHeroMod_Version", SH_VERSION_STR); // Update incase new version loaded while still running

	debugMsg(0, 1, "plugin_init - Version: %s", SH_VERSION_STR);

	// Menus
	gMenuID = register_menuid("Select Super Power");
	new menukeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0;
	register_menucmd(gMenuID, menukeys, "selectedSuperPower");

	// CVARS
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	bind_pcvar_num(create_cvar("sv_superheros", "1"), CvarSuperHeros);
	bind_pcvar_num(create_cvar("sh_alivedrop", "0"), CvarAliveDrop);
	bind_pcvar_num(create_cvar("sh_autobalance", "0"), CvarAutoBalance);
	bind_pcvar_num(create_cvar("sh_cmdprojector", "1"), CvarCmdProjector);
	bind_pcvar_num(create_cvar("sh_endroundsave", "1"), CvarEndRoundSave);
	bind_pcvar_float(create_cvar("sh_hsmult", "1.0", .has_min = true, .min_val = 1.0), CvarHSMult);
	bind_pcvar_num(create_cvar("sh_loadimmediate", "0"), CvarLoadImmediate);
	bind_pcvar_num(create_cvar("sh_lvllimit", "1"), CvarLvlLimit);
	bind_pcvar_num(create_cvar("sh_maxbinds", "3", .has_max = true, .max_val = float(SH_MAXBINDPOWERS)), CvarMaxBinds);
	bind_pcvar_num(create_cvar("sh_maxpowers", "20", .has_max = true, .max_val = float(SH_MAXHEROS)), CvarMaxPowers);
	bind_pcvar_num(create_cvar("sh_menumode", "1"), CvarMenuMode);
	sh_minlevel = create_cvar("sh_minlevel", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("sh_savexp", "1"), CvarSaveXP);
	bind_pcvar_num(create_cvar("sh_saveby", "1"), CvarSaveBy);
	bind_pcvar_num(create_cvar("sh_xpsavedays", "14", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 365.0), CvarXPSaveDays);
	bind_pcvar_num(create_cvar("sh_ffa", "0"), CvarFreeForAll);

	// Server cvars checked by core
	bind_pcvar_num(get_cvar_pointer("mp_friendlyfire"), CvarFriendlyFire);
	bind_pcvar_num(get_cvar_pointer("sv_lan"), CvarLan);

	if (cvar_exists("mp_freeforall")) // Support for ReGameDLL_CS
		bind_pcvar_num(get_cvar_pointer("mp_freeforall"), CvarServerFreeForAll);

	// API - Register a bunch of forwards that heroes can use
	fwd_HeroInit = CreateMultiForward("sh_hero_init", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL); // id, heroID, mode
	fwd_HeroKey = CreateMultiForward("sh_hero_key", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL); // id, heroID, key
	fwd_Spawn = CreateMultiForward("sh_client_spawn", ET_IGNORE, FP_CELL, FP_CELL); // id, newSpawn
	fwd_Death = CreateMultiForward("sh_client_death", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_STRING); //victim, attacker, wpnindex, hitplace, TK
	fwd_NewRound = CreateMultiForward("sh_round_new", ET_IGNORE);
	fwd_RoundStart = CreateMultiForward("sh_round_start", ET_IGNORE);
	fwd_RoundEnd = CreateMultiForward("sh_round_end", ET_IGNORE);

	// Init saving method commands/cvars/variables
	saving_init();

	// Setup config file paths
	setupConfig();

	// Events to Capture
	register_event("DeathMsg", "event_DeathMsg", "a");
	register_event("HLTV", "event_HLTV", "a", "1=0", "2=0"); // New Round
	register_logevent("round_Start", 2, "1=Round_Start");
	register_logevent("round_End", 2, "1=Round_End");
	register_logevent("round_Restart", 2, "1&Restart_Round_");

	// Must use post or else is_user_alive will return false when dead player respawns
	// Must use RegisterHamPlayer for special bots to hook
	RegisterHamPlayer(Ham_Spawn, "ham_PlayerSpawn_Post", 1);

	// Client Commands
	register_clcmd("superpowermenu", "cl_superpowermenu", ADMIN_ALL, "superpowermenu");
	register_clcmd("clearpowers", "cl_clearpowers", ADMIN_ALL, "clearpowers");
	register_clcmd("say", "cl_say");
	register_clcmd("fullupdate", "cl_fullupdate");

	// Power Commands, using a loop so it adjusts with SH_MAXBINDPOWERS
	for (new x = 1; x <= SH_MAXBINDPOWERS; ++x) {
		new powerDown[10], powerUp[10];
		formatex(powerDown, charsmax(powerDown), "+power%d", x);
		formatex(powerUp, charsmax(powerUp), "-power%d", x);

		register_clcmd(powerDown, "powerKeyDown");
		register_clcmd(powerUp, "powerKeyUp");
	}

	// Console commands for client or from server console
	register_concmd("playerlevels", "showLevelsCon", ADMIN_ALL, "<nick | @team | @ALL | #userid>");
	register_concmd("playerskills", "showSkillsCon", ADMIN_ALL, "<nick | @team | @ALL | #userid>");
	register_concmd("herolist", "showHeroListCon", ADMIN_ALL, "[search] [start] - Lists/Searches available heroes in console");

	// Hud Syncs for help and hero info, need 2 since help can be on at same time
	gHelpHudSync = CreateHudSyncObj();
	gHeroHudSync = CreateHudSyncObj();

	// Global Variables...
	gmsgStatusText = get_user_msgid("StatusText");

	// Set the game description
	register_forward(FM_GetGameDescription, "@Forward_GetGameDescription");

	// Block player names from overwriting StatusText sent by core
	register_message(gmsgStatusText, "msg_StatusText");

	// Load the config file here and again later
	// Initial load for core configs
	loadConfig();
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	// Default Sounds
	precache_sound(gSoundDeny);
	precache_sound(gSoundLevel);

	// Create this cvar in precache incase a hero wants to create a debug msg during precache
	bind_pcvar_num(create_cvar("sh_debug_messages", "0"), CvarDebugMessages);
}
//----------------------------------------------------------------------------------------------
public plugin_natives()
{
	register_library("sh_core_main");

	register_native("sh_create_hero", "@Native_CreateHero");
	register_native("sh_set_hero_info", "@Native_SetHeroInfo");
	register_native("sh_set_hero_bind", "@Native_SetHeroBind");
	register_native("sh_get_num_heroes", "@Native_GetNumHeroes");
	register_native("sh_get_num_lvls", "@Native_GetNumLvls");
	register_native("sh_get_kill_xp", "@Native_GetKillXP");
	register_native("sh_get_lvl_xp", "@Native_GetLvlXP");
	register_native("sh_get_user_hero", "@Native_GetUserHero");
	register_native("sh_get_user_lvl", "@Native_GetUserLvl");
	register_native("sh_set_user_lvl", "@Native_SetUserLvl");
	register_native("sh_get_user_powers", "@Native_GetUserPowers");
	register_native("sh_get_user_xp", "@Native_GetUserXP");
	register_native("sh_set_user_xp", "@Native_SetUserXP");
	register_native("sh_add_kill_xp", "@Native_AddKillXP");
	register_native("sh_get_hero_id", "@Native_GetHeroID");
	register_native("sh_get_hero_name", "@Native_GetHeroName");
	register_native("sh_user_has_hero", "@Native_UserHasHero");
	register_native("sh_user_is_loaded", "@Native_UserIsLoaded");
	register_native("sh_chat_message", "@Native_ChatMessage");
	register_native("sh_debug_message", "@Native_DebugMessage");
	register_native("sh_is_freezetime", "@Native_IsFreezeTime");
	register_native("sh_is_inround", "@Native_IsInRound");
}
//----------------------------------------------------------------------------------------------
@Forward_GetGameDescription()
{
	if (!CvarSuperHeros)
		return FMRES_IGNORED;

	new mod_name[9];
	get_modname(mod_name, charsmax(mod_name));
	if (equal(mod_name, "cstrike"))
		forward_return(FMV_STRING, "CS - SuperHero Mod");
	else
		forward_return(FMV_STRING, "CZ - SuperHero Mod");

	return FMRES_SUPERCEDE;
}
//----------------------------------------------------------------------------------------------
public plugin_cfg()
{
	// GIVES TIME FOR SERVER.CFG AND LISTENSERVER.CFG TO LOAD UP THEIR VARIABLES
	// AMX COMMANDS AND CONSOLE COMMAND

	debugMsg(0, 1, "Starting plugin_cfg() function");

	// Load the Config file, secondary load for heroes
	loadConfig();

	// Setup the Admin Commands
	register_concmd("amx_shsetlevel", "adminSetLevel", ADMIN_LEVEL_A, "<name|^"steamid^"|#userid|@TEAM|@ALL> <level> - Sets SuperHero level on Players");
	register_concmd("amx_shsetxp", "adminSetXP", ADMIN_LEVEL_A, "<name|^"steamid^"|#userid|@TEAM|@ALL> <xp> - Sets Players XP");
	register_concmd("amx_shaddxp", "adminSetXP", ADMIN_LEVEL_A, "<name|^"steamid^"|#userid|@TEAM|@ALL> <xp> - Adds XP to Players");
	register_concmd("amx_shban", "adminBanXP", ADMIN_LEVEL_A, "<name|^"steamid^"|#userid> - Bans a player from using Powers");
	register_concmd("amx_shunban", "adminUnbanXP", ADMIN_LEVEL_A, "<name|^"steamid^"|#userid|^"ip^"> - Unbans a player from using Powers");
#if SAVE_METHOD != 2
	register_concmd("amx_shimmunexp", "adminImmuneXP", ADMIN_LEVEL_A, "<name|^"steamid^"|#userid> <0=OFF|1=ON> - Sets/Unsets player immune from sh_savedays XP prune only");
#endif

	register_concmd("amx_shresetxp", "adminEraseXP", ADMIN_RCON, "- Erases ALL saved XP (may take some time with a large vault file)");

	// Setup XPGiven and XP
	readINI();

	// Clean out old XP data
	cleanXP(false);

	// Setup the Help MOTD
	setupHelpMotd();

	// Init CMD_PROJECTOR
	buildHelpHud();

	// Tasks
	set_task_ex(1.0, "loopMain", _, _, _, SetTask_Repeat);
	set_task(3.0, "setHeroLevels");

	if (cvar_exists("monster_spawn"))
		gMonsterModRunning = true;
}
//----------------------------------------------------------------------------------------------
setupConfig()
{
	// Set Up Config Files
	get_configsdir(gSHConfigDir, charsmax(gSHConfigDir));
	add(gSHConfigDir, charsmax(gSHConfigDir), "/shero", 6);

	// Attempt to create directory if it does not exist
	if (!dir_exists(gSHConfigDir))
		mkdir(gSHConfigDir);

	formatex(gBanFile, charsmax(gBanFile), "%s/nopowers.cfg", gSHConfigDir);
	formatex(gSHConfig, charsmax(gSHConfig), "%s/shconfig.cfg", gSHConfigDir);
}
//----------------------------------------------------------------------------------------------
setupHelpMotd()
{
	formatex(gHelpMotd, charsmax(gHelpMotd), "%s/shmotd.txt", gSHConfigDir);

	if (!file_exists(gHelpMotd))
		//Create the file if it doesn't exist
		createHelpMotdFile(gHelpMotd);
}
//----------------------------------------------------------------------------------------------
loadConfig()
{
	//Load SH Config File
	if (file_exists(gSHConfig)) {
		//Message Not run thru debug system since people are morons and think it's an error cause it says "DEBUG"
		static count;
		++count;
		log_amx("Exec: (%d) Loading shconfig.cfg (message should be seen twice)", count);

		server_cmd("exec %s", gSHConfig);

		//Force the server to flush the exec buffer
		server_exec();

		//Note: I do not believe this is an issue anymore disabling until known otherwise - vittu
		//Exec the config again due to issues with it not loading all the time
		//server_cmd("exec %s", gSHConfig)
	} else {
		debugMsg(0, 0, "**WARNING** SuperHero Config File not found, correct location: %s", gSHConfig);
	}
}
//----------------------------------------------------------------------------------------------
public loopMain()
{
	//Might be better to create an ent think loop
	if (!CvarSuperHeros)
		return;

	//Show the CMD Projector
	showHelpHud();
}
//----------------------------------------------------------------------------------------------
public setHeroLevels()
{
	debugMsg(0, 1, "Reloading Levels for %d Heroes", gSuperHeroCount);

	for (new i = 0; i < gSuperHeroCount && i <= SH_MAXHEROS; ++i)
		gSuperHeros[i][availableLevel] = gHeroLevel[i];
}
//----------------------------------------------------------------------------------------------
//native sh_is_inround()
bool:@Native_IsInRound()
{
	return gBetweenRounds ? false : true;
}
//----------------------------------------------------------------------------------------------
//native sh_is_freezetime()
bool:@Native_IsFreezeTime()
{
	return gRoundStarted ? false : true;
}
//----------------------------------------------------------------------------------------------
//native sh_get_num_heroes()
@Native_GetNumHeroes()
{
	return gSuperHeroCount;
}
//----------------------------------------------------------------------------------------------
//native sh_get_num_lvls()
@Native_GetNumLvls()
{
	return gNumLevels;
}
//----------------------------------------------------------------------------------------------
//native sh_get_kill_xp(level)
@Native_GetKillXP()
{
	new level = get_param(1);

	//stupid check - but checking prevents crashes
	if (level < 0 || level > gNumLevels)
		return -1;

	return gXPGiven[level];
}
//----------------------------------------------------------------------------------------------
//native sh_get_lvl_xp(level)
@Native_GetLvlXP()
{
	new level = get_param(1);

	//stupid check - but checking prevents crashes
	if (level < 0 || level > gNumLevels)
		return -1;

	return gXPLevel[level];
}
//----------------------------------------------------------------------------------------------
//native sh_get_user_hero(id, powerID)
@Native_GetUserHero()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return -1;

	new powerIndex = get_param(2);

	if (0 < powerIndex <= getPowerCount(id))
		return gPlayerPowers[id][powerIndex];

	return -1;
}
//----------------------------------------------------------------------------------------------
//native sh_get_user_lvl(id)
@Native_GetUserLvl()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return -1;

	//Check if data has loaded yet
	// if (flag_get_boolean(gReadXPNextRound, id))
		// return -1;

	return gPlayerLevel[id];
}
//----------------------------------------------------------------------------------------------
//native sh_get_user_powers(id)
@Native_GetUserPowers()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return -1;

	return getPowerCount(id);
}
//----------------------------------------------------------------------------------------------
//native sh_set_user_lvl(id, setlevel)
@Native_SetUserLvl()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return -1;

	new setlevel = get_param(2);

	if (setlevel < 0 || setlevel > gNumLevels)
		return -1;

	gPlayerXP[id] = gXPLevel[setlevel];
	displayPowers(id, false);

	return setlevel;
}
//----------------------------------------------------------------------------------------------
//native sh_get_user_xp(id)
@Native_GetUserXP()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return -1;

	return gPlayerXP[id];
}
//----------------------------------------------------------------------------------------------
//native sh_set_user_xp(id, xp, bool:addtoxp = false)
@Native_SetUserXP()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return -1;

	new xp = get_param(2);

	// Add to XP or set a value
	if (get_param(3))
		localAddXP(id, xp);
	else
		// Set to xp, by finding what must be added to users current xp
		localAddXP(id, (xp - gPlayerXP[id]));

	displayPowers(id, false);

	return 1;
}
//----------------------------------------------------------------------------------------------
//native sh_chat_message(id, heroID = -1, const msg[], any:...)
@Native_ChatMessage()
{
	new id = get_param(1);

	if (id < 0 || id > MaxClients)
		return;

	if (is_user_bot(id))
		return;

	// Chat max is 191(w/null) to pass into it, "[SH] " is 5 char min added to message
	new output[186];
	vdformat(output, charsmax(output), 3, 4);

	if (output[0] == '^0')
		return;

	chatMessage(id, get_param(2), output);
}
//----------------------------------------------------------------------------------------------
// Thanks to teame06's ColorChat method which this is based on
chatMessage(id, heroIndex = -1, const msg[], any:...)
{
	if (id < 0 || id > MaxClients)
		return;

	if (is_user_bot(id))
		return;

	// Now we build our message
	static message[191], heroName[27];
	new len;
	message[0] = '^0';
	heroName[0] = '^0';

	// Set first bit
	message[0] = 0x03; //Team colored
	++len;

	// Do we need to set a hero name to the message
	if (-1 < heroIndex < gSuperHeroCount)
		// Set hero name in parentheses
		formatex(heroName, charsmax(heroName), "(%s)",  gSuperHeros[heroIndex][hero]);

	len += formatex(message[len], charsmax(message) - len, "[SH]%s^x01 ", (heroName[0] == '^0') ? "" : heroName);

	vformat(message[len], charsmax(message) - len, msg, 4);

	client_print_color(id, print_team_grey, message);
}
//----------------------------------------------------------------------------------------------
//native sh_debug_message(id, level, const message[], any:...)
@Native_DebugMessage()
{
	new level = get_param(2);

	if (CvarDebugMessages < level && level != 0)
		return;

	new id = get_param(1);

	new output[512];
	vdformat(output, charsmax(output), 3, 4);

	if (output[0] == '^0')
		return;

	debugMsg(id, level, output);
}
//----------------------------------------------------------------------------------------------
debugMsg(id, level, const message[], any:...)
{
	if (CvarDebugMessages < level && level != 0)
		return;

	new output[512];
	vformat(output, charsmax(output), message, 4);

	if (output[0] == '^0')
		return;

	if (0 < id <= MaxClients) {
		new name[32], userid, authid[32], team[32];
		get_user_name(id, name,  charsmax(name));
		userid = get_user_userid(id);
		get_user_authid(id, authid,  charsmax(authid));
		get_user_team(id, team,  charsmax(team));
		if (equal(team, "UNASSIGNED"))
			copy(team, charsmax(team), "");

		if (userid > 0)
			format(output, charsmax(output), "^"%s<%d><%s><%s>^" %s", name, userid, authid, team, output);
	}

	log_amx("DEBUG: %s", output);
}
//----------------------------------------------------------------------------------------------
//native sh_get_hero_id(const heroName[])
@Native_GetHeroID()
{
	new pHero[25];
	get_string(1, pHero, charsmax(pHero));

	return getHeroID(pHero);
}
//----------------------------------------------------------------------------------------------
getHeroID(const heroName[])
{
	for (new x = 0; x < gSuperHeroCount; ++x) {
		if (equali(heroName, gSuperHeros[x][hero]))
			return x;
	}
	return -1;
}
//----------------------------------------------------------------------------------------------
//native sh_get_hero_name(heroID, name[], len)
bool:@Native_GetHeroName()
{
	new heroIndex = get_param(1);

	if (-1 < heroIndex < gSuperHeroCount) {
		set_string(2, gSuperHeros[heroIndex][hero], get_param(2));
		return true;
	}

	return false;
}
//----------------------------------------------------------------------------------------------
//native sh_user_has_hero(id, heroID)
bool:@Native_UserHasHero()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return false;

	new heroIndex = get_param(2);

	if (-1 < heroIndex < gSuperHeroCount)
		return playerHasPower(id, heroIndex);

	return false;
}
//----------------------------------------------------------------------------------------------
bool:playerHasPower(id, heroIndex)
{
	new playerPowerCount = getPowerCount(id);
	for (new x = 1; x <= playerPowerCount && x <= SH_MAXLEVELS; ++x) {
		if (gPlayerPowers[id][x] == heroIndex)
			return true;
	}
	return false;
}
//----------------------------------------------------------------------------------------------
//native sh_user_is_loaded(id)
bool:@Native_UserIsLoaded()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return false;

	return flag_get_boolean(gReadXPNextRound, id) ? false : true;
}
//---------------------------------------------------------------------------------------------
//native sh_create_hero(const heroName[], pcvarMinLevel)
@Native_CreateHero()
{
	//Heroes Name
	new pHero[25];
	get_string(1, pHero, charsmax(pHero));

	// Add Hero to Big Array!
	if (gSuperHeroCount >= SH_MAXHEROS) {
		debugMsg(0, 1, "Hero ^"%s^" Is Being Rejected, Exceeded SH_MAXHEROS", pHero);
		return -1;
	}

	new idx = gSuperHeroCount;

	new pcvarMinLevel = get_param(2);
	new heroLevel = get_pcvar_num(pcvarMinLevel);

	debugMsg(0, 3, "Create Hero-> HeroID: %d - %s - %d", gSuperHeroCount, pHero, heroLevel);

	copy(gSuperHeros[idx][hero], 24, pHero);
	bind_pcvar_num(pcvarMinLevel, gHeroLevel[idx]);
	gSuperHeros[idx][availableLevel] = heroLevel;

	++gSuperHeroCount;

	return idx;
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_info(heroID, const powerInfo[] = "", const powerHelp[] = "")
@Native_SetHeroInfo()
{
	new heroIndex = get_param(1);

	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return;

	new pPower[50], pHelp[128];
	get_string(2, pPower, charsmax(pPower)); //Short Power Description
	get_string(3, pHelp, charsmax(pHelp)); //Help Info

	debugMsg(0, 3, "Create Hero-> HeroID: %d - %s - %s", heroIndex, pPower, pHelp);

	copy(gSuperHeros[heroIndex][superpower], 49, pPower);
	copy(gSuperHeros[heroIndex][help], 127, pHelp);
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_bind(heroID)
@Native_SetHeroBind()
{
	new heroIndex = get_param(1);

	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return;

	debugMsg(0, 3, "Create Hero-> HeroID: %d - Bindable: ^"TRUE^"", heroIndex);

	gSuperHeros[heroIndex][requiresKeys] = true;
}
//----------------------------------------------------------------------------------------------
initHero(id, heroIndex, mode)
{
	// OK to pass this through when mod off... Let's heroes cleanup after themselves
	// init event is used to let hero know when a player has selected OR deselected a hero's power

	//Init the hero
	ExecuteForward(fwd_HeroInit, _, id, heroIndex, mode);

	flag_set(gChangedHeroes, id);
}
//----------------------------------------------------------------------------------------------
getPowerCount(id)
{
	// I'll make this a function for now in case I want to change power mapping strategy
	// i.e. drop a power menu
	return max(gPlayerPowers[id][0], 0);
}
//----------------------------------------------------------------------------------------------
getBindNumber(id, heroIndex)
{
	for (new x = 1; x <= CvarMaxBinds; ++x) {
		if (gPlayerBinds[id][x] == heroIndex)
			return x;
	}
	return 0;
}
//----------------------------------------------------------------------------------------------
menuSuperPowers(id, menuOffset)
{
	// Don't show menu if mod off or they're not connected
	if (!CvarSuperHeros || !is_user_connected(id) || flag_get_boolean(gReadXPNextRound, id))
		return PLUGIN_HANDLED;

	flag_clear(gInMenu, id);
	gPlayerMenuOffset[id] = 0;

	new bool:isBot = is_user_bot(id) ? true : false;

	if (flag_get_boolean(gIsPowerBanned, id)) {
		if (!isBot)
			client_print(id, print_center, "You are not allowed to have powers");

		return PLUGIN_HANDLED; // Just don't show the gui menu
	}

	new playerPowerCount = getPowerCount(id);
	new playerLevel = gPlayerLevel[id];

	// Don't show menu if they already have enough powers
	if (playerPowerCount >= playerLevel || playerPowerCount >= CvarMaxPowers)
		return PLUGIN_HANDLED;

	// Figure out how many powers a person should be able to have
	// Example: At level 10 a person can pick a max of 1 lvl 10 hero
	//		and a max of 2 lvl 9 heroes, and a max of 3 lvl 8 heors, etc...
	new LvlLimit = CvarLvlLimit;
	if (LvlLimit == 0)
		LvlLimit = SH_MAXLEVELS;

	for (new x = 0; x <= gNumLevels; ++x) {
		if (playerLevel >= x)
			gMaxPowersLeft[id][x] = playerLevel - x + LvlLimit;
		else
			gMaxPowersLeft[id][x] = 0;
	}

	// Now decrement the level powers that they've picked
	new heroIndex, heroLevel;

	for (new x = 1; x <= playerPowerCount && x <= SH_MAXLEVELS; ++x) {
		heroIndex = gPlayerPowers[id][x];
		if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
			continue;

		heroLevel = getHeroLevel(heroIndex);
		// Decrement all gMaxPowersLeft by 1 for the level hero they have and below
		for (new y = heroLevel; y >= 0; y--) {
			if (--gMaxPowersLeft[id][y] < 0)
				gMaxPowersLeft[id][y] = 0;

			//If none left on this level, there should be none left on any higher levels
			if (gMaxPowersLeft[id][y] <= 0 && y < SH_MAXLEVELS) {
				if (gMaxPowersLeft[id][y+1] != 0) {
					for (new z = y; z <= gNumLevels; z++)
						gMaxPowersLeft[id][z] = 0;
				}
			}
		}
	}

	// OK BUILD A LIST OF HEROES THIS PERSON CAN PICK FROM
	gPlayerMenuChoices[id][0] = 0; // <- 0 choices so far
	new count = 0, enabled = 0;
	new maxBinds = CvarMaxBinds;
	new menuMode = CvarMenuMode;
	new bool:thisEnabled;

	for (new x = 0; x < gSuperHeroCount; ++x) {
		heroIndex = x;
		heroLevel = getHeroLevel(heroIndex);
		thisEnabled = false;
		if (playerLevel >= heroLevel) {
			if (gMaxPowersLeft[id][heroLevel] > 0 && !(gPlayerBinds[id][0] >= maxBinds && gSuperHeros[heroIndex][requiresKeys]))
				thisEnabled = true;

			// Don't want to present this power if the player already has it!
			if (!playerHasPower(id, heroIndex) && (thisEnabled || (!isBot && menuMode > 0))) {
				gPlayerMenuChoices[id][0] = ++count;
				gPlayerMenuChoices[id][count] = heroIndex;

				if (thisEnabled)
					++enabled;
			}
		}
	}

	// Choose and give a random power to a bot
	if (isBot && count) {
		// Select a random power
		heroIndex = gPlayerMenuChoices[id][random_num(1, count)];

		// Bind Keys / Set Powers
		gPlayerPowers[id][0] = playerPowerCount + 1;
		gPlayerPowers[id][playerPowerCount + 1] = heroIndex;

		//Init This Hero!
		initHero(id, heroIndex, SH_HERO_ADD);
		displayPowers(id, true);

		//Don't show menu to bots and wait for next menu call before giving another power
		return PLUGIN_HANDLED;
	}

	// show menu super power
	new message[800];
	new temp[90];
	new keys = 0;

	//menuOffset Stuff
	if (menuOffset <= 0 || menuOffset > gPlayerMenuChoices[id][0])
		menuOffset = 1;
	
	gPlayerMenuOffset[id] = menuOffset;

	new total = min(CvarMaxPowers, playerLevel);
	formatex(message, 68, "\ySelect Super Power:%-16s\r(You've Selected %d/%d)^n^n", " ", playerPowerCount, total);

	// OK Display the Menu
	for (new x = menuOffset; x < menuOffset + 8; ++x) {
		// Only allow a selection from powers the player doesn't have
		if (x > gPlayerMenuChoices[id][0]) {
			add(message, charsmax(message), "^n");
			continue;
		}
		heroIndex = gPlayerMenuChoices[id][x];
		heroLevel = getHeroLevel(heroIndex);
		if (gMaxPowersLeft[id][heroLevel] <= 0 || (gPlayerBinds[id][0] >= maxBinds && gSuperHeros[heroIndex][requiresKeys]))
			add(message,charsmax(message),"\d");
		else
			add(message,charsmax(message),"\w");

		keys |= (1 << x - menuOffset); // enable this option
		formatex(temp, charsmax(temp), "%s (%d%s)", gSuperHeros[heroIndex][hero], heroLevel, gSuperHeros[heroIndex][requiresKeys] ? "b" : "");
		format(temp, charsmax(temp), "%d. %-20s- %s^n", x - menuOffset + 1, temp, gSuperHeros[heroIndex][superpower]);
		add(message, charsmax(message), temp);
	}

	if (gPlayerMenuChoices[id][0] > 8) {
		// Can only Display 8 heroes at a time
		add(message, charsmax(message), "\w^n9. More Heroes");
		keys |= MENU_KEY_9;
	} else {
		add(message, charsmax(message), "^n");
	}

	// Cancel
	add(message, charsmax(message), "\w^n0. Cancel");
	keys |= MENU_KEY_0;

	if ((count > 0 && enabled > 0) || flag_get_boolean(gInMenu, id)) {
		debugMsg(id, 8, "Displaying Menu - offset: %d - count: %d - enabled: %d", menuOffset, count, enabled);
		flag_set(gInMenu, id);
		show_menu(id, keys, message);
	}

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public selectedSuperPower(id, key)
{
	if (!flag_get_boolean(gInMenu, id) || !CvarSuperHeros)
		return PLUGIN_HANDLED;

	flag_clear(gInMenu, id);

	if (flag_get_boolean(gIsPowerBanned, id)) {
		client_print(id, print_center, "You are not allowed to have powers");
		return PLUGIN_HANDLED;
	}

	switch (key) {
		case 8: {
			// Next and Previous Super Hero Menus
			menuSuperPowers(id, gPlayerMenuOffset[id] + 8);
			return PLUGIN_HANDLED;
		}
		case 9: {
			// Cancel
			gPlayerMenuOffset[id] = 0;
			return PLUGIN_HANDLED;
		}
	}

	// Hero was Picked!
	new playerPowerCount = getPowerCount(id);
	if (playerPowerCount >= gNumLevels || playerPowerCount >= CvarMaxPowers)
		return PLUGIN_HANDLED;

	new heroIndex = gPlayerMenuChoices[id][key + gPlayerMenuOffset[id]];

	// Just a crash check
	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return PLUGIN_HANDLED;

	new heroLevel = getHeroLevel(heroIndex);
	new maxBinds = CvarMaxBinds;
	if ((gPlayerBinds[id][0] >= maxBinds && gSuperHeros[heroIndex][requiresKeys])) {
		chatMessage(id, _, "You cannot choose more than %d heroes that require binds", maxBinds);
		menuSuperPowers(id, gPlayerMenuOffset[id]);
		return PLUGIN_HANDLED;
	} else if (gMaxPowersLeft[id][heroLevel] <= 0) {
		chatMessage(id, _, "You cannot pick any more heroes from that level");
		menuSuperPowers(id, gPlayerMenuOffset[id]);
		return PLUGIN_HANDLED;
	}

	new message[256];
	if (!gSuperHeros[heroIndex][requiresKeys])
		formatex(message, charsmax(message), "AUTOMATIC POWER: %s^n%s", gSuperHeros[heroIndex][superpower], gSuperHeros[heroIndex][help]);
	else
		formatex(message, charsmax(message), "BIND KEY TO ^"+POWER%d^": %s^n%s", gPlayerBinds[id][0]+1, gSuperHeros[heroIndex][superpower], gSuperHeros[heroIndex][help]);

	// Show the Hero Picked
	set_hudmessage(100, 100, 0, -1.0, 0.2, 0, 1.0, 5.0, 0.1, 0.2, -1);
	ShowSyncHudMsg(id, gHeroHudSync, "%s", message);

	// Bind Keys / Set Powers
	gPlayerPowers[id][0] = playerPowerCount + 1;
	gPlayerPowers[id][playerPowerCount + 1] = heroIndex;

	//Init This Hero!
	initHero(id, heroIndex, SH_HERO_ADD);
	displayPowers(id, true);

	// Show the Menu Again if they don't have enough skills yet!
	menuSuperPowers(id, gPlayerMenuOffset[id]);

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
clearPower(id, level)
{
	new heroIndex = gPlayerPowers[id][level];

	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return;

	// Ok shift over any levels higher
	new playerPowerCount = getPowerCount(id);
	for (new x = level; x <= playerPowerCount && x <= SH_MAXLEVELS; ++x) {
		if (x != SH_MAXLEVELS)
			gPlayerPowers[id][x] = gPlayerPowers[id][x + 1];
	}

	new powers = gPlayerPowers[id][0]--;
	if (powers < 0)
		gPlayerPowers[id][0] = 0;

	//Clear out powers higher than powercount
	for (new x = powers + 1; x <= gNumLevels && x <= SH_MAXLEVELS; ++x)
		gPlayerPowers[id][x] = -1;

	// Disable this power
	initHero(id, heroIndex, SH_HERO_DROP);

	// Display Levels will have to rebind this heroes powers...
	gPlayerBinds[id][0] = 0;
}
//----------------------------------------------------------------------------------------------
public cl_clearpowers(id)
{
	if (!CvarSuperHeros) {
		console_print(id, "[SH] SuperHero Mod is currently disabled");
		return PLUGIN_HANDLED;
	}

	if (!CvarAliveDrop && is_user_alive(id)) {
		console_print(id, "[SH] You are not allowed to drop heroes while alive");
		chatMessage(id, _, "You are not allowed to drop heroes while alive");
		return PLUGIN_HANDLED;
	}

	// When Client Fires, there won't be a 2nd parm (dispStatusText), so let's just make it true
	clearAllPowers(id, true);
	console_print(id, "[SH] All your powers have been cleared successfully");

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
clearAllPowers(id, bool:dispStatusText)
{
	// OK to fire if mod is off since we want heroes to clean themselves up
	gPlayerPowers[id][0] = 0;
	gPlayerBinds[id][0] = 0;

	new heroIndex;
	new bool:userConnected = is_user_connected(id) ? true : false;

	// Clear the power before sending the drop init
	for (new x = 1; x <= gNumLevels && x <= SH_MAXLEVELS; ++x) {
		// Save heroid for init forward
		heroIndex = gPlayerPowers[id][x];

		// Clear All Power slots for player
		gPlayerPowers[id][x] = -1;

		// Only send drop on heroes user has
		if (heroIndex != -1 && userConnected)
			initHero(id, heroIndex, SH_HERO_DROP);  // Disable this power
	}

	if (dispStatusText && userConnected) {
		displayPowers(id, true);
		menuSuperPowers(id, gPlayerMenuOffset[id]);
	}
}
//----------------------------------------------------------------------------------------------
public cl_superpowermenu(id)
{
	menuSuperPowers(id, 0);
}
//----------------------------------------------------------------------------------------------
public ham_PlayerSpawn_Post(id)
{
	if (!CvarSuperHeros)
		return HAM_IGNORED;

	// The very first Ham_Spawn on a user will happen when he is
	// created, this user is not spawned alive into the game.
	// Alive check will block first Ham_Spawn call for clients.
	// Team check will block first Ham_Spawn call for bots. (bots pass alive check)
	if (!is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
		return HAM_IGNORED;

	//Prevents non-saved XP servers from having loading issues
	if (!CvarSaveXP)
		flag_clear(gReadXPNextRound, id);

	//Cancel the ultimate timer task on any new spawn
	//It is up to the hero to set the variable back to false
	remove_task(id + SH_COOLDOWN_TASKID, 1); // 1 = look outside this plugin

	//Prevents this whole function from being called if its not a new round
	if (!flag_get_boolean(gNewRoundSpawn, id)) {
		displayPowers(id, true);

		//Let heroes know someone just spawned mid-round
		ExecuteForward(fwd_Spawn, _, id, 0);

		return HAM_IGNORED;
	}

	// Read the XP!
	if (flag_get_boolean(gFirstRound, id))
		flag_clear(gFirstRound, id);
	else if (flag_get_boolean(gReadXPNextRound, id))
		readXP(id);

	//Display the XP and bind powers to their screen
	displayPowers(id, true);

	//Shows menu if the person is not in it already, always show for bots to choose powers
	if (!flag_get_boolean(gInMenu, id) && (is_user_bot(id) || !(gPlayerFlags[id] & SH_FLAG_NOAUTOMENU)))
		menuSuperPowers(id, gPlayerMenuOffset[id]);

	//Prevents resetHUD from getting called twice in a round
	flag_clear(gNewRoundSpawn, id);

	//Prevents People from going invisible randomly
	set_user_rendering(id);

	//Let heroes know someone just spawned from a new round
	ExecuteForward(fwd_Spawn, _, id, 1);

	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
//New Round
public event_HLTV()
{
	gRoundStarted = false;

	//Remove all Monster Mod monsters, stops them from attacking during freezetime
	if (gMonsterModRunning) {
		new flags, monster = -1;
		while ((monster = engfunc(EngFunc_FindEntityByString, monster, "classname", "func_wall")) != 0) {
			flags = pev(monster, pev_flags);
			if (flags & FL_MONSTER)
				set_pev(monster, pev_flags, flags | FL_KILLME);
		}
	}

	//Lets let all the heroes know
	ExecuteForward(fwd_NewRound, _);
}
//----------------------------------------------------------------------------------------------
public round_Start()
{
	if (!CvarSuperHeros)
		return;

	gBetweenRounds = false;

	set_task(0.1, "roundStartDelay");
}
//----------------------------------------------------------------------------------------------
public roundStartDelay()
{
	for (new x = 1; x <= MaxClients; ++x) {
		displayPowers(x, true);
		//Prevents People from going invisible randomly
		if (is_user_alive(x))
			set_user_rendering(x);
	}

	gRoundStarted = true;

	//Lets let all the heroes know
	ExecuteForward(fwd_RoundStart, _);
}
//----------------------------------------------------------------------------------------------
public round_Restart()
{
	// Round end is not called when round is set to restart, so lets just force it right away.
	round_End();
}
//----------------------------------------------------------------------------------------------
public round_End()
{
	gBetweenRounds = true;

	for (new id = 1; id <= MaxClients; id++) {
		flag_set(gNewRoundSpawn, id);

		if (!is_user_connected(id))
			continue;

		if (cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
			continue;

		flag_clear(gFirstRound, id);
	}

	//Save XP Data
	if (CvarEndRoundSave)
		set_task(2.0, "memoryTableWrite");

	//Lets let all the heroes know
	ExecuteForward(fwd_RoundEnd, _);
}
//----------------------------------------------------------------------------------------------
public cl_fullupdate(id)
{
	// This blocks "fullupdate" from resetting the HUD and doing bad things to heroes
	if (is_user_alive(id))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
public powerKeyDown(id)
{
	if (!CvarSuperHeros || !is_user_connected(id))
		return PLUGIN_HANDLED;

	// re-entrency check to prevent aliasing muliple powerkeys - currently untested
	//new Float:gametime = get_gametime();
	//if (gametime - gLastKeydown[id] < 0.2)
	//	return PLUGIN_HANDLED;
	//gLastKeydown[id] = gametime;

	new cmd[12], whichKey;
	read_argv(0, cmd, charsmax(cmd));
	whichKey = str_to_num(cmd[6]);

	if (whichKey > SH_MAXBINDPOWERS || whichKey <= 0)
		return PLUGIN_CONTINUE;

	debugMsg(id, 5, "power%d Pressed", whichKey);

	// Check if player is a VIP
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_POWERKEYS) {
		sh_sound_deny(id);
		chatMessage(id, _, "VIP's are not allowed to use +power keys");
		return PLUGIN_HANDLED;
	}

	// Make sure player isn't stunned
	if (sh_get_stun(id)) {
		sh_sound_deny(id);
		return PLUGIN_HANDLED;
	}

	// Make sure there is a power bound to this key!
	if (whichKey > gPlayerBinds[id][0]) {
		sh_sound_deny(id);
		return PLUGIN_HANDLED;
	}

	new heroIndex = gPlayerBinds[id][whichKey];
	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return PLUGIN_HANDLED;

	//Make sure they are not already using this keydown
	if (flag_get_boolean(gInPowerDown[whichKey], id))
		return PLUGIN_HANDLED;

	flag_set(gInPowerDown[whichKey], id);

	if (playerHasPower(id, heroIndex))
		ExecuteForward(fwd_HeroKey, _, id, heroIndex, SH_KEYDOWN);

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public powerKeyUp(id)
{
	if (!CvarSuperHeros || !is_user_connected(id))
		return PLUGIN_HANDLED;

	new cmd[12], whichKey;
	read_argv(0, cmd, charsmax(cmd));
	whichKey = str_to_num(cmd[6]);

	if (whichKey > SH_MAXBINDPOWERS || whichKey <= 0)
		return PLUGIN_CONTINUE;

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_POWERKEYS)
		return PLUGIN_HANDLED;

	// Make sure player isn't stunned (unless they were in keydown when stunned)
	if (sh_get_stun(id) && !flag_get_boolean(gInPowerDown[whichKey], id))
		return PLUGIN_HANDLED;

	//Set this key as NOT in use anymore
	flag_clear(gInPowerDown[whichKey], id);

	debugMsg(id, 5, "power%d Released", whichKey);

	// Make sure there is a power bound to this key!
	if (whichKey > gPlayerBinds[id][0])
		return PLUGIN_HANDLED;

	new heroIndex = gPlayerBinds[id][whichKey];
	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return PLUGIN_HANDLED;

	if (playerHasPower(id, heroIndex))
		ExecuteForward(fwd_HeroKey, _, id, heroIndex, SH_KEYUP);

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public msg_StatusText()
{
	if (!CvarSuperHeros)
		return PLUGIN_CONTINUE;

	// Block sending StatusText sent by engine
	// Stops name from overwriting StatusText set by plugin
	// Will not block StatusText sent by plugin
	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
writeStatusMessage(id, const message[64])
{
	// Crash Check, bots will crash server is message sent to them
	if (!is_user_connected(id) || is_user_bot(id))
		return;

	// Message is a max of 64 characters including null terminator
	// Place in unreliable stream, not a necessary message
	message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
	write_byte(0);
	write_string(message);
	message_end();
}
//----------------------------------------------------------------------------------------------
displayPowers(id, bool:setThePowers)
{
	if (!CvarSuperHeros || !is_user_connected(id))
		return;

	// To avoid recursion - displayPowers will call clearPowers<->Display Power Loop if we don't check for player powers
	if (flag_get_boolean(gIsPowerBanned, id)) {
		clearAllPowers(id, false); // Avoids Recursion with false
		writeStatusMessage(id, "[SH] You are banned from using powers");
		return;
	} else if (flag_get_boolean(gReadXPNextRound, id)) {
		debugMsg(id, 5, "XP will load next round");
		writeStatusMessage(id, "[SH] Your XP will be loaded next round");
		return;
	}

	debugMsg(id, 5, "Displaying and Setting Powers");

	// OK Test What Level this Fool is
	testLevel(id);

	new message[64], temp[64];
	new heroIndex, maxBinds, count, playerLevel, playerPowerCount;
	new menuid, mkeys;

	count = 0;
	playerLevel = gPlayerLevel[id];

	if (playerLevel < gNumLevels)
		formatex(message, charsmax(message), "LVL:%d/%d XP:(%d/%d)", playerLevel, gNumLevels, gPlayerXP[id], gXPLevel[playerLevel+1]);
	else
		formatex(message, charsmax(message), "LVL:%d/%d XP:(%d)", playerLevel, gNumLevels, gPlayerXP[id]);

	//Resets All Bind assignments
	maxBinds = CvarMaxBinds;
	for (new x = 1; x <= maxBinds; ++x)
		gPlayerBinds[id][x] = -1;

	playerPowerCount = getPowerCount(id);

	for (new x = 1; x <= gNumLevels && x <= playerPowerCount; ++x) {
		heroIndex = gPlayerPowers[id][x];
		if (-1 < heroIndex < gSuperHeroCount) {
			// 2 types of heroes - auto heroes and bound heroes...
			// Bound Heroes require special work...
			if (gSuperHeros[heroIndex][requiresKeys]) {
				++count;
				if (count <= 3) {
					if (message[0] != '^0')
						add(message, charsmax(message), " ");
					
					formatex(temp, charsmax(temp), "%d=%s", count, gSuperHeros[heroIndex]);
					add(message, charsmax(message), temp);
				}
				// Make sure this players keys are bound correctly
				if (count <= maxBinds) {
					gPlayerBinds[id][count] = heroIndex;
					gPlayerBinds[id][0] = count;
				} else {
					clearPower(id, x);
				}
			}
		}
	}

	if (is_user_alive(id))
		writeStatusMessage(id, message);

	// Update menu incase already in menu and levels changed
	// or user is no longer in menu
	get_user_menu(id, menuid, mkeys);
	if (menuid != gMenuID)
		flag_clear(gInMenu, id);
	else
		menuSuperPowers(id, gPlayerMenuOffset[id]);
}
//----------------------------------------------------------------------------------------------
//This function is the ONLY way this plugin should add/subtract XP to a player
//There are checks to prevent overflowing
//To take XP away just send the function a negative (-) number
localAddXP(id, xp)
{
	new playerXP = gPlayerXP[id];
	new newTotal = playerXP + xp;

	if (xp > 0 && newTotal < playerXP)
		// Max possible signed 32bit int
		gPlayerXP[id] = 2147483647;
	else if (xp < 0 && (newTotal < -1000000 || newTotal > playerXP))
		gPlayerXP[id] = -1000000;
	else
		gPlayerXP[id] = newTotal;
}
//----------------------------------------------------------------------------------------------
//native sh_add_kill_xp(id, victim, Float:multiplier = 1.0)
@Native_AddKillXP()
{
	new id = get_param(1);
	new victim = get_param(2);

	// Stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients || victim < 1 || victim > MaxClients)
		return;

	//new Float:mult = get_param_f(3);
	localAddXP(id, floatround(get_param_f(3) * gXPGiven[gPlayerLevel[victim]]));
	displayPowers(id, false);
}
//---------------------------------------------------------------------------------------------
// Must use death event since csx client_death does not catch worldspawn or suicides
public event_DeathMsg()
{
	new killer = read_data(1);
	new victim = read_data(2);
	new headshot = read_data(3);

	static wpnDescription[32];
	read_data(4, wpnDescription, charsmax(wpnDescription));

	// Run this even with sh off so forward can still run and clean up what it needs to
	ExecuteForward(fwd_Death, _, victim, killer, headshot, wpnDescription);

	if (!CvarSuperHeros)
		return;

	// Kill by extra damage will be skipped here since killer is self
	if (killer && killer != victim && victim) {
		if (cs_get_user_team(killer) == cs_get_user_team(victim) && !CvarFreeForAll && !CvarServerFreeForAll) {
			// Killed teammate
			localAddXP(killer, -gXPGiven[gPlayerLevel[killer]]);
		} else {
			if (headshot)
				localAddXP(killer, floatround(gXPGiven[gPlayerLevel[victim]] * CvarHSMult));
			else
				localAddXP(killer, gXPGiven[gPlayerLevel[victim]]);
		}

		displayPowers(killer, false);
	}

	displayPowers(victim, false);
}
//----------------------------------------------------------------------------------------------
public cl_say(id)
{
	static said[192];
	read_args(said, charsmax(said));
	remove_quotes(said);

	if (!CvarSuperHeros) {
		if (containi(said, "powers") != -1 || containi(said, "superhero") != -1)
			chatMessage(id, _, "SuperHero Mod is currently disabled");

		return PLUGIN_CONTINUE;
	}

	// If first character is "/" start command check after that character
	new pos;
	if (said[pos] == '/')
		++pos;

	if (equali(said[pos], "superherohelp") || equali(said[pos], "help")) {
		showHelp(id);
		return PLUGIN_CONTINUE;
	} else if (equali(said[pos], "herolist")) {
		showHeroList(id);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "playerskills", 12)) {
		showPlayerSkills(id, 1, said[pos + 13]);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "playerlevels", 12)) {
		showPlayerLevels(id, 1, said[pos + 13]);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "whohas", 6)) {
		if (said[pos + 7] == '^0') {
			chatMessage(id, _, "A partial hero name is required for that command");
			return PLUGIN_HANDLED;
		}
		showWhoHas(id, 1, said[pos + 7]);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "myheroes")) {
		showHeroes(id);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "clearpowers")) {
		if (!CvarAliveDrop && is_user_alive(id)) {
			chatMessage(id, _, "You are not allowed to drop heroes while alive");
			return PLUGIN_HANDLED;
		}
		clearAllPowers(id, true);
		chatMessage(id, _, "All your powers have been cleared successfully");
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "showmenu")) {
		menuSuperPowers(id, 0);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "automenu")) {
		chatMessage(id, _, "Automatically show Select Super Power menu %s", (gPlayerFlags[id] & SH_FLAG_NOAUTOMENU) ? "ENABLED" : "DISABLED");
		gPlayerFlags[id] ^= SH_FLAG_NOAUTOMENU;
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "drop", 4)) {
		dropPower(id, said);
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "helpon")) {
		if (CvarCmdProjector > 0)
			chatMessage(id, _, "Help HUD message enabled");

		gPlayerFlags[id] |= SH_FLAG_HUDHELP;
		return PLUGIN_HANDLED;
	} else if (equali(said[pos], "helpoff")) {
		if (CvarCmdProjector > 0)
			chatMessage(id, _, "Help HUD message disabled");

		gPlayerFlags[id] &= ~SH_FLAG_HUDHELP;
		return PLUGIN_HANDLED;
	} else if (containi(said, "powers") != -1 || containi(said, "superhero") != -1) {
		chatMessage(id, _, "For help with SuperHero Mod, say: /help");
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}
//----------------------------------------------------------------------------------------------
dropPower(id, const said[])
{
	if (!CvarAliveDrop && is_user_alive(id)) {
		chatMessage(id, _, "You are not allowed to drop heroes while alive");
		return;
	}

	new heroName[32];
	new heroIndex;
	new bool:found = false;

	new spaceIdx = contain(said, " ");
	if (spaceIdx > 0 && strlen(said) > spaceIdx + 2) {
		copy(heroName, charsmax(heroName), said[spaceIdx + 1]);
	} else {
		chatMessage(id, _, "Please provide at least two letters from the hero name you wish to drop");
		return;
	}

	debugMsg(id, 5, "Trying to Drop Hero: %s", heroName);

	new playerPowerCount = getPowerCount(id);
	for (new x = 1; x <= playerPowerCount && x <= SH_MAXLEVELS; ++x) {
		heroIndex = gPlayerPowers[id][x];
		if (-1 < heroIndex < gSuperHeroCount) {
			if (containi(gSuperHeros[heroIndex][hero], heroName) != -1) {
				debugMsg(id, 1, "Dropping Hero: %s", gSuperHeros[heroIndex][hero]);
				clearPower(id, x);
				chatMessage(id, _, "Dropped Hero: %s", gSuperHeros[heroIndex][hero]);
				found = true;
				break;
			}
		}
	}

	// Show the menu and the loss of power... or a message...
	if (found) {
		displayPowers(id, true);
		menuSuperPowers(id, gPlayerMenuOffset[id]);
	} else {
		chatMessage(id, _, "Could Not Find Power to Drop: %s", heroName);
	}
}
//----------------------------------------------------------------------------------------------
showHelp(id)
{
	if (!CvarSuperHeros)
		return;

	show_motd(id, gHelpMotd, "SuperHero Mod Help");
}
//----------------------------------------------------------------------------------------------
showHeroList(id)
{
	if (!CvarSuperHeros)
		return;

	new buffer[1501];
	new n = 0;

	n += copy(buffer[n], charsmax(buffer)-n, "<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n");

	n += copy(buffer[n], charsmax(buffer)-n, "TIP: Use ^"herolist^" in the console for better output and searchability.^n^n");
	n += copy(buffer[n], charsmax(buffer)-n, "Installed Heroes:^n^n");

	for (new x = 0; x < gSuperHeroCount; ++x)
		n += formatex(buffer[n], charsmax(buffer)-n, "%s (%d%s) - %s^n", gSuperHeros[x][hero], getHeroLevel(x), gSuperHeros[x][requiresKeys] ? "b" : "", gSuperHeros[x][superpower]);

	copy(buffer[n], charsmax(buffer)-n, "</pre></body></html>");

	show_motd(id, buffer, "SuperHero List");
}
//----------------------------------------------------------------------------------------------
showPlayerLevels(id, say, said[])
{
	if (!CvarSuperHeros)
		return;

	new players[MAX_PLAYERS], playerCount;

	if (equal(said, ""))
		copy(said, 30, "@ALL");

	new buffer[1501];
	new n = 0;

	if (say == 1) {
		n += copy(buffer[n], charsmax(buffer)-n, "<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n");
		n += copy(buffer[n], charsmax(buffer)-n, "Player Levels:^n^n");
	} else {
		console_print(id, "Player Levels:^n");
	}

	if (said[0] == '@') {
		if (equali("T", said[1]))
			copy(said[1], 31, "TERRORIST");

		if (equali("ALL", said[1]))
			get_players(players, playerCount);
		else
			get_players_ex(players, playerCount, GetPlayers_MatchTeam | GetPlayers_CaseInsensitive, said[1]);

		if (playerCount == 0) {
			console_print(id, "No clients in such team");
			return;
		}
	} else {
		players[0] = cmd_target(id, said, CMDTARGET_ALLOW_SELF);
		if (!players[0])
			return;
		
		playerCount = 1;
	}

	new pid, teamName[5], name[32];
	for (new team = 2; team >= 0; team--) {
		for (new x = 0; x < playerCount; ++x) {
			pid = players[x];
			if (get_user_team(pid) != team)
				continue;

			get_user_name(pid, name, charsmax(name));

			teamName[0] = '^0';
			switch (get_user_team(pid)) {
				case 1: copy(teamName, charsmax(teamName), "T :");
				case 2: copy(teamName, charsmax(teamName), "CT:");
				default: copy(teamName, charsmax(teamName), "S :");
			}

			if (say == 1)
				n += formatex(buffer[n], charsmax(buffer)-n, "%s%-24s (Level %d)(XP = %d)^n", teamName, name, gPlayerLevel[pid], gPlayerXP[pid]);
			else
				console_print(id, "%s%-24s (Level %d)(XP = %d)", teamName, name, gPlayerLevel[pid], gPlayerXP[pid]);
		}
	}

	if (say == 1) {
		copy(buffer[n], charsmax(buffer)-n, "</pre></body></html>");

		show_motd(id, buffer, "Players SuperHero Levels");
	} else {
		console_print(id, "");
	}
}
//----------------------------------------------------------------------------------------------
showPlayerSkills(id, say, said[])
{
	if (!CvarSuperHeros)
		return;

	new players[MAX_PLAYERS], playerCount;
	new name[32];

	if (equal(said,""))
		copy(said, 31, "@ALL");

	new buffer[1501];
	new n = 0;
	new tn = 0;
	new temp[512];

	if (say == 1) {
		n += copy(buffer[n], charsmax(buffer) - n, "<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n");

		n += copy(buffer[n], charsmax(buffer) - n, "Player Skills:^n^n");
	} else {
		console_print(id, "Player Skills:^n");
	}

	if (said[0] == '@') {
		if (equali("T",said[1]))
			copy(said[1], 31,"TERRORIST");

		if (equali("ALL", said[1]))
			get_players(players, playerCount);
		else
			get_players_ex(players, playerCount, GetPlayers_MatchTeam | GetPlayers_CaseInsensitive, said[1]);

		if (playerCount == 0) {
			console_print(id, "No clients in such team");
			return;
		}
	} else {
		players[0] = cmd_target(id, said, CMDTARGET_ALLOW_SELF);
		if (!players[0])
			return;

		playerCount = 1;
	}

	new pid, teamName[5], idx, heroIndex, playerPowerCount;
	for (new team = 2; team >= 0; team--) {
		for (new x = 0; x < playerCount; ++x) {
			tn = 0;
			pid = players[x];
			if (get_user_team(pid) != team)
				continue;

			get_user_name(pid, name, charsmax(name));

			teamName[0] = '^0';
			switch (get_user_team(pid)) {
				case 1: copy(teamName, charsmax(teamName), "T :");
				case 2: copy(teamName, charsmax(teamName), "CT:");
				default: copy(teamName, charsmax(teamName), "S: ");
			}
			tn += formatex(temp[tn], charsmax(temp) - tn, "%s%-24s (Level %d)(XP = %d)", teamName, name, gPlayerLevel[pid], gPlayerXP[pid]);
			if (say == 0) {
				console_print(id, "%s", temp);
				tn = 0;
				tn += copy(temp[tn], charsmax(temp)-tn, "   ");
			}
			playerPowerCount = getPowerCount(pid);
			for (idx = 1; idx <= playerPowerCount; ++idx) {
				heroIndex = gPlayerPowers[pid][idx];
				tn += formatex(temp[tn], charsmax(temp) - tn, "| %s ", gSuperHeros[heroIndex][hero]);
				if (idx % 6 == 0) {
					if (say == 1) {
						tn += copy(temp[tn], charsmax(temp) - tn, "|^n   ");
					} else {
						tn += copy(temp[tn], charsmax(temp) - tn, "|");
						console_print(id, "%s", temp);
						tn = 0;
						tn += copy(temp[tn], charsmax(temp) - tn, "   ");
					}
				}
			}

			if (say == 1) {
				copy(temp[tn], charsmax(temp) - tn, "^n^n");
				n += copy(buffer[n], charsmax(buffer) - n, temp);
			} else {
				if (gPlayerPowers[pid][0] > 0)
					copy(temp[tn], charsmax(temp) - tn, "|");

				console_print(id, "%s", temp);
			}
		}
	}

	if (say == 1) {
		copy(buffer[n], charsmax(buffer) - n, "</pre></body></html>");

		show_motd(id, buffer, "Players SuperHero Skills");
	} else {
		console_print(id, "");
	}
}
//----------------------------------------------------------------------------------------------
showWhoHas(id, say, said[])
{
	if (!CvarSuperHeros)
		return;

	new who[25];
	copy(who, charsmax(who), said);

	new heroIndex = -1;

	for (new i = 0; i < gSuperHeroCount; ++i) {
		if (containi(gSuperHeros[i][hero], who) != -1) {
			heroIndex = i;
			break;
		}
	}

	if (heroIndex < 0) {
		if (say == 1)
			chatMessage(id, _, "Could not find a hero that matches: %s", who);
		else
			console_print(id, "[SH] Could not find a hero that matches: %s", who);

		return;
	}

	new buffer[1501], n;

	if (say == 1)
		n += copy(buffer[n], charsmax(buffer) - n,"<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n");

	n += formatex(buffer[n], charsmax(buffer) - n, "WhoHas: %s^n^n", gSuperHeros[heroIndex][hero]);

	// Get a List of Players
	new players[MAX_PLAYERS], playerCount;
	get_players(players, playerCount);

	new pid, teamName[5], name[32];
	for (new team = 2; team >= 0; team--) {
		for (new x = 0; x < playerCount; ++x) {
			pid = players[x];
			if (get_user_team(pid) != team)
				continue;

			get_user_name(pid, name, charsmax(name));
			teamName[0] = '^0';
			if (!playerHasPower(pid, heroIndex))
				continue;

			switch (get_user_team(pid)) {
				case 1: copy(teamName, charsmax(teamName), "T :");
				case 2: copy(teamName, charsmax(teamName), "CT:");
				default: copy(teamName, charsmax(teamName), "S: ");
			}
			n += formatex(buffer[n], charsmax(buffer) - n, "%s%-24s (Level %d)(XP = %d)^n", teamName, name, gPlayerLevel[pid], gPlayerXP[pid]);
		}
	}

	if (say == 1) {
		copy(buffer[n], charsmax(buffer) - n, "</pre></body></html>");

		new title[32];
		formatex(title, charsmax(title), "SuperHero WhoHas: %s", who);
		show_motd(id, buffer, title);
	} else {
		console_print(id, "%s", buffer);
	}
}
//----------------------------------------------------------------------------------------------
public adminSetLevel(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;

	if (!CvarSuperHeros) {
		console_print(id, "[SH] SuperHero Mod is currently disabled");
		return PLUGIN_HANDLED;
	}

	if (read_argc() > 3) {
		console_print(id, "[SH] Too many arguments supplied. Do not use a space in the name.");
		console_print(id, "[SH] You only need to put in a partial name to use this command.");
		return PLUGIN_HANDLED;
	}

	new arg2[4];
	read_argv(2, arg2, charsmax(arg2));

	if (!isdigit(arg2[0])) {
		console_print(id, "[SH] Second argument must be a XP level.");
		console_print(id, "Usage:  amx_shsetlevel <nick | @team | @ALL | #userid> <level> - Sets SuperHero level on players");
		return PLUGIN_HANDLED;
	}

	new setlevel = str_to_num(arg2);

	if (setlevel < 0 || setlevel > gNumLevels) {
		console_print(id, "[SH] Invalid Level - Valid Levels = 0 - %d", gNumLevels);
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, charsmax(arg));

	new authid2[32], name2[32];
	get_user_name(id, name2, charsmax(name2));
	get_user_authid(id, authid2, charsmax(authid2));

	if (arg[0] == '@') {
		new players[MAX_PLAYERS], playerCount;
		if (equali("T", arg[1]))
			copy(arg[1], charsmax(arg)-1, "TERRORIST");

		if (equali("ALL", arg[1]))
			get_players(players, playerCount);
		else
			get_players_ex(players, playerCount, GetPlayers_MatchTeam | GetPlayers_CaseInsensitive, arg[1]);

		if (!playerCount) {
			console_print(id, "No clients in such team");
			return PLUGIN_HANDLED;
		}

		new user;
		for (new a = 0; a < playerCount; a++) {
			user = players[a];
			gPlayerXP[user] = gXPLevel[setlevel];
			displayPowers(user, false);
		}

		show_activity(id, name2, "set level %d on %s players", setlevel, arg[1]);

		console_print(id, "[SH] Set level %d on %s players", setlevel, arg[1]);

		log_amx("[SH] ^"%s<%d><%s><>^" set level %d on %s players", name2, get_user_userid(id), authid2, setlevel, arg[1]);
	} else {
		new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);
		if (!player)
			return PLUGIN_HANDLED;

		gPlayerXP[player] = gXPLevel[setlevel];
		displayPowers(player, false);

		new name[32], authid[32];
		get_user_name(player, name, charsmax(name));
		get_user_authid(player, authid, charsmax(authid));

		show_activity(id, name2, "set level %d on %s", setlevel, name);

		console_print(id, "[SH] Client ^"%s^" has been set to level %d", name, setlevel);

		log_amx("[SH] ^"%s<%d><%s><>^" set level %d on ^"%s<%d><%s><>^"", name2, get_user_userid(id), authid2, setlevel, name, get_user_userid(player), authid);
	}

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public adminSetXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;

	if (!CvarSuperHeros) {
		console_print(id, "[SH] SuperHero Mod is currently disabled");
		return PLUGIN_HANDLED;
	}

	if (read_argc() > 3) {
		console_print(id, "[SH] Too many arguments supplied. Do not use a space in the name.");
		console_print(id, "[SH] You only need to put in a partial name to use this command.");
		return PLUGIN_HANDLED;
	}

	new arg2[12];
	read_argv(2, arg2, charsmax(arg2));

	if (!(isdigit(arg2[0]) || (equal(arg2[0], "-", 1) && isdigit(arg2[1])))) {
		console_print(id, "[SH] Second argument must be a XP value.");
		return PLUGIN_HANDLED;
	}

	new xp = str_to_num(arg2);

	new cmd[32], arg[32];
	new bool:giveXP = false;
	read_argv(0, cmd, charsmax(cmd));
	read_argv(1, arg, charsmax(arg));

	if (equali(cmd, "amx_shaddxp"))
		giveXP = true;

	new name2[32], authid2[32];
	get_user_name(id, name2, charsmax(name2));
	get_user_authid(id, authid2, charsmax(authid2));

	if (arg[0] == '@') {
		new players[MAX_PLAYERS], playerCount;
		if (equali("T", arg[1]))
			copy(arg[1], charsmax(arg)-1, "TERRORIST");

		if (equali("ALL", arg[1]))
			get_players(players, playerCount);
		else
			get_players_ex(players, playerCount, GetPlayers_MatchTeam | GetPlayers_CaseInsensitive, arg[1]);

		if (!playerCount) {
			console_print(id, "No clients in such team");
			return PLUGIN_HANDLED;
		}

		new user;
		for (new a = 0; a < playerCount; a++) {
			user = players[a];
			if (giveXP)
				localAddXP(user, xp);
			else
				gPlayerXP[user] = xp;

			displayPowers(user, false);
		}

		show_activity(id, name2, "%s %d XP on %s players", giveXP ? "added" : "set", xp, arg[1]);

		console_print(id, "[SH] %s %d XP on %s players", giveXP ? "Added" : "Set", xp, arg[1]);

		log_amx("[SH] ^"%s<%d><%s><>^" %s %d XP on %s players", name2, get_user_userid(id), authid2, giveXP ? "added" : "set", xp, arg[1]);
	} else {
		new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);
		if (!player)
			return PLUGIN_HANDLED;

		if (giveXP)
			localAddXP(player, xp);
		else
			gPlayerXP[player] = xp;

		displayPowers(player, false);

		new name[32], authid[32];
		get_user_name(player, name, charsmax(name));
		get_user_authid(player, authid, charsmax(authid));

		show_activity(id, name2, "%s %d XP on %s", giveXP ? "added" : "set", xp, name);

		console_print(id, "[SH] Client ^"%s^" has been %s %d XP", name, giveXP ? "given" : "set to", xp);

		log_amx("[SH] ^"%s<%d><%s><>^" %s %d XP on ^"%s<%d><%s><>^"", name2, get_user_userid(id), authid2, giveXP ? "added" : "set", xp, name, get_user_userid(player), authid);
	}

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public adminBanXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	if (read_argc() > 2) {
		console_print(id, "[SH] Too many arguments supplied. Do not use a space in the name.");
		console_print(id, "[SH] You only need to put in a partial name to use this command.");
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, charsmax(arg));

	new player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY);
	if (!player)
		return PLUGIN_HANDLED;

	new name[32], authid[32], bankey[32];
	new userid = get_user_userid(player);
	get_user_name(player, name, charsmax(name));
	get_user_authid(player, authid, charsmax(authid));

	if (flag_get_boolean(gIsPowerBanned, player)) {
		console_print(id, "[SH] Client is already SuperHero banned: ^"%s<%d><%s>^"", name, userid, authid);
		return PLUGIN_HANDLED;
	}

	if (!getSaveKey(player, bankey)) {
		console_print(id, "[SH] Unable to find valid Ban Key to write to file for client: ^"%s<%d><%s>^"", name, userid, authid);
		return PLUGIN_HANDLED;
	}

	// "a" will create a file if it does not exist but not overwrite it if it does
	new banFile = fopen(gBanFile, "at");

	if (!banFile) {
		debugMsg(0, 0, "Failed to open nopowers.cfg, please verify file/folder permissions");
		console_print(id, "[SH] Failed to open/create nopowers.cfg to save ban");
		return PLUGIN_HANDLED;
	}

	// Add a first line of description if file was just created
	if (-1 < file_size(gBanFile, 1) < 2)
		fputs(banFile, "//List of SteamIDs / IPs Banned from using powers^n");

	fprintf(banFile, "%s^n", bankey);

	fclose(banFile);

	new name2[32], authid2[32];
	get_user_name(id, name2, charsmax(name2));
	get_user_authid(id, authid2, charsmax(authid2));

	flag_set(gIsPowerBanned, player);
	clearAllPowers(player, false); // Avoids Recursion with false
	writeStatusMessage(player, "You are banned from using powers");

	show_activity(id, name2, "banned %s from using superhero powers", name);

	chatMessage(player, _, "You have been banned from using superhero powers");

	log_amx("[SH] ^"%s<%d><%s><>^" banned ^"%s<%d><%s><>^" from using superhero powers", name2, get_user_userid(id), authid2, name, userid, authid);

	console_print(id, "[SH] Successfully SuperHero banned ^"%s<%d><%s><>^"", name, userid, authid);

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public adminUnbanXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	if (read_argc() > 2) {
		console_print(id, "[SH] Too many arguments supplied. Do not use a space in the name.");
		console_print(id, "[SH] You only need to put in a partial name to use this command.");
		return PLUGIN_HANDLED;
	}

	if(!file_exists(gBanFile) ) {
		console_print(id, "[SH] There is no ban file to modify");
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, charsmax(arg));

	new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);

	new name2[32], authid2[32], bankey[32];
	get_user_name(id, name2, charsmax(name2));
	get_user_authid(id, authid2, charsmax(authid2));

	if (player) {
		new name[32], authid[32];
		get_user_name(player, name, charsmax(name));
		get_user_authid(player, authid, charsmax(authid));
		new userid = get_user_userid(player);

		if (!flag_get_boolean(gIsPowerBanned, player)) {
			console_print(id, "[SH] Client is not SuperHero banned: ^"%s<%d><%s><>^"", name, userid, authid);
			return PLUGIN_HANDLED;
		}

		if (!getSaveKey(player, bankey)) {
			console_print(id, "[SH] Unable to find valid Ban Key to remove from file for client: ^"%s<%d><%s>^"", name, userid, authid);
			return PLUGIN_HANDLED;
		}

		if (!removeBanFromFile(id, bankey))
			return PLUGIN_HANDLED;

		flag_clear(gIsPowerBanned, player);
		displayPowers(player, false);

		show_activity(id, name2, "unbanned %s from using superhero powers", name);

		console_print(id, "[SH] Successfully SuperHero unbanned ^"%s<%d><%s><>^"", name, userid, authid);

		log_amx("[SH] ^"%s<%d><%s><>^" un-banned ^"%s<%d><%s><>^" from using superhero powers", name2, get_user_userid(id), authid2,name, userid, authid);
	} else {
		// Assume attempting to unban by steamid or IP
		copy(bankey, charsmax(bankey), arg);
		console_print(id, "[SH] Attemping to unban using argument: %s", bankey);

		if (!removeBanFromFile(id, bankey))
			return PLUGIN_HANDLED;

		console_print(id, "[SH] Successfully SuperHero unbanned: %s", bankey);
		console_print(id, "[SH] WARNING: If this user is connected they need to reconnect to use powers");

		log_amx("[SH] ^"%s<%d><%s><>^" un-banned ^"%s^" from using superhero powers", name2, get_user_userid(id), authid2, bankey);
	}

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
removeBanFromFile(adminID, const bankey[32])
{
	new tempFile[128];
	formatex(tempFile, charsmax(tempFile), "%s~", gBanFile);

	new banFile = fopen(gBanFile, "rt");
	new tempBanFile = fopen(tempFile, "wt");

	if (!banFile || !tempBanFile) {
		debugMsg(0, 0, "Failed to open nopowers.cfg, please verify file/folder permissions");
		console_print(adminID, "[SH] Unable to edit nopowers.cfg ban file");
		return 0;
	}

	new bool:found;
	new data[128];

	while (!feof(banFile)) {
		fgets(banFile, data, charsmax(data));
		trim(data);

		// Blank line skip copying it
		if (data[0] == '^0')
			continue;

		if (equali(data, bankey)) {
			found = true;
			continue;
		}

		fprintf(tempBanFile, "%s^n", data);
	}

	fclose(banFile);
	fclose(tempBanFile);

	delete_file(gBanFile);

	if (!rename_file(tempFile, gBanFile, 1)) {
		debugMsg(0, 0, "Error renaming file: %s -> %s", tempFile, gBanFile);
		console_print(adminID, "[SH] Unable to rename ban file");
		return 0;
	}

	if (!found) {
		console_print(adminID, "[SH] ^"%s^" not found in nopowers.cfg", bankey);
		return 0;
	}

	return 1;
}
//----------------------------------------------------------------------------------------------
#if SAVE_METHOD != 2
public adminImmuneXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED;

	if (!CvarSaveXP) {
		console_print(id, "[SH] Immunity from sh_savedays XP prune can not be set in non-saved XP mode.");
		return PLUGIN_HANDLED;
	}

	new numOfArg = read_argc();

	if (numOfArg > 3) {
		console_print(id, "[SH] Too many arguments supplied. Do not use a space in the name.");
		console_print(id, "[SH] You only need to put in a partial name to use this command.");
		return PLUGIN_HANDLED;
	}

	new arg[32];
	read_argv(1, arg, charsmax(arg));

	new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);
	if (!player)
		return PLUGIN_HANDLED;

	new name[32], authid[32], bankey[32];
	new userid = get_user_userid(player);
	get_user_name(player, name, charsmax(name));
	get_user_authid(player, authid, charsmax(authid));

	if (!getSaveKey(player, bankey)) {
		console_print(id, "[SH] Unable to find valid Save Key for client: ^"%s<%d><%s>^"", name, userid, authid);
		return PLUGIN_HANDLED;
	}

	if (numOfArg == 2) {
		// No on/off just supply what setting is at
		console_print(id, "[SH] Immunity from sh_savedays XP prune is %s on client: ^"%s<%d><%s><>^"", (gPlayerFlags[player] & SH_FLAG_XPIMMUNE) ? "ENABLED" : "DISABLED", name, userid, authid);
		return PLUGIN_HANDLED;
	}

	new arg2[4], mode;
	read_argv(2, arg2, charsmax(arg2));

	if (equali(arg2, "on"))
		mode = 1;
	else if (equali(arg2, "off"))
		mode = 0;
	else
		mode = str_to_num(arg2);

	switch (mode) {
		case 0: {
			if (!(gPlayerFlags[player] & SH_FLAG_XPIMMUNE)) {
				console_print(id, "[SH] Client is already nonimmune to sh_savedays XP prune: ^"%s<%d><%s>^"", name, userid, authid);
				return PLUGIN_HANDLED;
			}
			gPlayerFlags[player] &= ~SH_FLAG_XPIMMUNE;
			chatMessage(player, _, "Your immunity from inactive user XP deletion has been removed");
		}
		case 1: {
			if (gPlayerFlags[player] & SH_FLAG_XPIMMUNE) {
				console_print(id, "[SH] Client is already immune from sh_savedays XP prune: ^"%s<%d><%s>^"", name, userid, authid);
				return PLUGIN_HANDLED;
			}
			gPlayerFlags[player] |= SH_FLAG_XPIMMUNE;

			chatMessage(player, _, "You have been given immunity from inactive user XP deletion");
		}
		default: {
			console_print(id, "[SH] Invalid 3rd parameter: %s", arg2);
			return PLUGIN_HANDLED;
		}
	}

	// Update saved data now for safety
	memoryTableUpdate(player);

	new name2[32], authid2[32];
	get_user_name(id, name2, charsmax(name2));
	get_user_authid(id, authid2, charsmax(authid2));

	show_activity(id, name2, "%s %s immune from inactive user XP deletion", mode ? "Set" : "Unset", name); 

	log_amx("[SH] ^"%s<%d><%s><>^" %s immunity ^"%s<%d><%s><>^" from sh_savedays XP prune", name2, get_user_userid(id), authid2, mode ? "set" : "unset", name, userid, authid);

	console_print(id, "[SH] Successfully %s immunity from sh_savedays XP prune on client ^"%s<%d><%s><>^"", mode ? "set" : "unset", name, userid, authid);

	return PLUGIN_HANDLED;
}
#endif
//----------------------------------------------------------------------------------------------
public adminEraseXP(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	console_print(id, "[SH] Please wait while the XP is erased");

	for (new x = 1; x <= MaxClients; ++x) {
		gPlayerXP[x] = 0;
		gPlayerLevel[x] = 0;
		writeStatusMessage(x, "All XP has been ERASED");
		clearAllPowers(x, true);
	}

	cleanXP(true);

	new name[32], authid[32];
	get_user_name(id, name, charsmax(name));
	get_user_authid(id, authid, charsmax(authid));

	show_activity(id, name, "Erased ALL Saved XP");

	console_print(id, "[SH] All Saved XP has been Erased Successfully");

	log_amx("[SH] ^"%s<%d><%s><>^" erased all the XP", name, get_user_userid(id), authid);

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
showHeroes(id)
{
	if (!CvarSuperHeros)
		return PLUGIN_CONTINUE;

	new buffer[1501];
	new n = 0;
	new heroIndex, bindNum, x;
	new bindNumtxt[128], name_lvl[128];

	n += copy(buffer[n], charsmax(buffer) - n, "<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n");

	n += copy(buffer[n], charsmax(buffer) - n, "Your Heroes Are:^n^n");
	new playerPowerCount = getPowerCount(id);
	for (x = 1; x <= playerPowerCount; ++x) {
		heroIndex = gPlayerPowers[id][x];
		bindNum = getBindNumber(id, heroIndex);
		bindNumtxt[0] = '^0';

		if (bindNum > 0)
			formatex(bindNumtxt, charsmax(bindNumtxt), "- POWER #%d", bindNum);

		formatex(name_lvl, charsmax(name_lvl), "%s (%d)", gSuperHeros[heroIndex][hero], getHeroLevel(heroIndex));
		n += formatex(buffer[n], charsmax(buffer) - n, "%d) %-18s- %s %s^n", x, name_lvl, gSuperHeros[heroIndex][superpower], bindNumtxt);
	}

	copy(buffer[n], charsmax(buffer) - n, "</pre></body></html>");

	show_motd(id, buffer, "Your SuperHero Heroes");
	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public showSkillsCon(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	if (!CvarSuperHeros) {
		console_print(id, "[SH] SuperHero Mod is currently disabled");
		return PLUGIN_HANDLED;
	}

	new arg1[32];
	read_argv(1, arg1, charsmax(arg1));

	showPlayerSkills(id, 0, arg1);
	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public showLevelsCon(id,level,cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	if (!CvarSuperHeros) {
		console_print(id, "[SH] SuperHero Mod is currently disabled");
		return PLUGIN_HANDLED;
	}

	new arg1[32];
	read_argv(1, arg1, charsmax(arg1));

	showPlayerLevels(id, 0, arg1);
	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public showHeroListCon(id)
{
	if (!CvarSuperHeros) {
		console_print(id, "[SH] SuperHero Mod is currently disabled");
		return PLUGIN_HANDLED;
	}

	console_print(id, "^n----- Hero Listing -----");
	new argx[20];
	read_argv(1, argx, charsmax(argx));
	new start, end;
	if (!isdigit(argx[0]) && !equal("", argx)) {
		new tmp[8], n = 1;
		read_argv(2, tmp, charsmax(tmp));
		start = str_to_num(tmp);
		if (start < 0)
			start = 0;
		if (start != 0)
			start--;
		end = start + HEROAMOUNT;
		for (new x = 0; x < gSuperHeroCount; ++x) {
			if ((containi(gSuperHeros[x][hero], argx) != -1) || (containi(gSuperHeros[x][help], argx) != -1)) {
				if (n > start && n <= end)
					console_print(id, "%3d: %s (%d%s) - %s", n, gSuperHeros[x][hero], getHeroLevel(x), gSuperHeros[x][requiresKeys] ? "b" : "", gSuperHeros[x][help]);

				++n;
			}
		}

		if (start + 1 > n - 1)
			console_print(id, "----- Highest Entry: %d -----", n - 1);
		else if (n - 1 == 0)
			console_print(id, "----- No Matches for Your Search -----");
		else if (n - 1 < end)
			console_print(id, "----- Entries %d - %d of %d -----", start + 1, n - 1, n - 1);
		else
			console_print(id, "----- Entries %d - %d of %d -----", start + 1, end, n - 1);

		if (end < n - 1)
			console_print(id, "----- Use 'herolist %s %d' for more -----", argx, end + 1);
	} else {
		new arg1[8];
		start = read_argv(1, arg1, charsmax(arg1)) ? str_to_num(arg1) : 1;
		if (--start < 0)
			start = 0;
		if (start >= gSuperHeroCount)
			start = gSuperHeroCount - 1;
		end = start + HEROAMOUNT;
		if (end > gSuperHeroCount)
			end = gSuperHeroCount;
		for (new i = start; i < end; ++i)
			console_print(id, "%3d: %s (%d%s) - %s", i + 1, gSuperHeros[i][hero], getHeroLevel(i), gSuperHeros[i][requiresKeys] ? "b" : "", gSuperHeros[i][help]);

		console_print(id, "----- Entries %d - %d of %d -----", start + 1, end, gSuperHeroCount);
		if (end < gSuperHeroCount)
			console_print(id, "----- Use 'herolist %d' for more -----", end + 1);
	}
	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
showHelpHud()
{
	if (!CvarSuperHeros)
		return;

	static GetPlayersFlags:flags;
	flags = GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV; // show to live or dead non-bots
	switch (CvarCmdProjector) {
		case 1: flags |= GetPlayers_ExcludeAlive; // show to dead non-bots only
		default: return; // off 
	}

	set_hudmessage(230, 100, 10, 0.80, 0.28, 0, 1.0, 1.0, 0.9, 0.9);

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players_ex(players, playerCount, flags);

	for (i = 0; i < playerCount; ++i) {
		player = players[i];

		if (gPlayerFlags[player] & SH_FLAG_HUDHELP)
			ShowSyncHudMsg(player, gHelpHudSync, "%s", gHelpHudMsg);
	}
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	// Don't want any left over residuals
	initPlayer(id);
}
//----------------------------------------------------------------------------------------------
public client_disconnected(id)
{
	// Don't want any left over residuals
	initPlayer(id);
}
//----------------------------------------------------------------------------------------------
public client_putinserver(id)
{
	if (id < 1 || id > MaxClients)
		return;

	// Don't want to mess up already loaded XP
	if (!flag_get_boolean(gReadXPNextRound, id) && CvarSaveXP)
		return;

	// Load up XP if LongTerm is enabled
	if (CvarSaveXP) {
		// Mid-round loads allowed?
		if (CvarLoadImmediate)
			readXP(id);
		else
			flag_set(gReadXPNextRound, id);
	} else if (CvarAutoBalance) {
		// If autobalance is on - promote this player by avg XP
		gPlayerXP[id] = getAverageXP();
	}
}
//----------------------------------------------------------------------------------------------
getAverageXP()
{
	new count = 0;
	new Float:sum = 0.0;

	for (new i = 1; i <= MaxClients; ++i) {
		if (is_user_connected(i) && gPlayerXP[i] > 0) {
			++count;
			sum += gPlayerXP[i];
		}
	}

	if (count > 0)
		return floatround(sum / count);

	return 0;
}
//----------------------------------------------------------------------------------------------
initPlayer(id)
{
	if (id < 1 || id > MaxClients)
		return;

	gPlayerXP[id] = 0;
	gPlayerPowers[id][0] = 0;
	gPlayerBinds[id][0] = 0;
	setLevel(id, 0);
	gPlayerFlags[id] = SH_FLAG_HUDHELP;
	flag_set(gFirstRound, id);
	flag_set(gNewRoundSpawn, id);
	flag_clear(gIsPowerBanned, id);
	if (CvarSaveXP)
		flag_set(gReadXPNextRound, id);
	else
		flag_clear(gReadXPNextRound, id);

	clearAllPowers(id, false);
}
//----------------------------------------------------------------------------------------------
getHeroLevel(heroIndex)
{
	return gSuperHeros[heroIndex][availableLevel];
}
//----------------------------------------------------------------------------------------------
getPlayerLevel(id)
{
	new newLevel = 0;

	for (new i = gNumLevels; i >= 0 ; --i) {
		if (gXPLevel[i] <= gPlayerXP[id]) {
			newLevel = i;
			break;
		}
	}

	// Now make sure this level is between the ranges
	new minLevel = clamp(get_pcvar_num(sh_minlevel), 0, gNumLevels);

	if (newLevel < minLevel && !flag_get_boolean(gReadXPNextRound, id)) {
		newLevel = minLevel;
		gPlayerXP[id] = gXPLevel[newLevel];
	}

	return min(newLevel, gNumLevels);
}
//----------------------------------------------------------------------------------------------
// Use to set CVAR Variable to the proper level - If a Hero needs to know a level at least it's possible
setLevel(id, newLevel)
{
	// MAKE SURE THE VAR IS SET CORRECTLY...
	gPlayerLevel[id] = newLevel;
}
//----------------------------------------------------------------------------------------------
testLevel(id)
{
	new newLevel, oldLevel, playerPowerCount;
	oldLevel = gPlayerLevel[id];
	newLevel = getPlayerLevel(id);

	// Play a Sound on Level Change!
	if (oldLevel != newLevel) {
		setLevel(id, newLevel);
		if (newLevel != 0)
			client_cmd(id, "spk %s", gSoundLevel);
	}

	// Make sure player is allowed to have the heroes in their list
	if (newLevel < oldLevel) {
		new heroIndex;
		playerPowerCount = getPowerCount(id);
		for (new x = 1; x <= gNumLevels && x <= playerPowerCount; ++x) {
			heroIndex = gPlayerPowers[id][x];
			if (-1 < heroIndex < gSuperHeroCount) {
				if (getHeroLevel(heroIndex) > gPlayerLevel[id]) {
					clearPower(id, x);
					--x;
				}
			}
		}
	}

	// Uh oh - Rip away a level from powers if they loose a level
	playerPowerCount = getPowerCount(id);
	if (playerPowerCount > newLevel) {
		for (new x = newLevel + 1; x <= playerPowerCount && x <= SH_MAXLEVELS; ++x)
			clearPower(id, x); // Keep clearing level above cuz levels shift!

		gPlayerPowers[id][0] = newLevel;
	}

	// Go ahead and write this so it's not lost - hopefully no server crash!
	memoryTableUpdate(id);
}
//----------------------------------------------------------------------------------------------
public readXP(id)
{
	if (!CvarSaveXP)
		return;

	// Players XP already loaded, no need to do this again
	if (!flag_get_boolean(gReadXPNextRound, id))
		return;

	static savekey[32];

	// Get Key
	if (!getSaveKey(id, savekey)) {
		debugMsg(id, 1, "Invalid KEY found will try to Load XP again: ^"%s^"", savekey);
		set_task(5.0, "readXP", id);
		return;
	}

	// Set if player is banned from powers or not
	checkBan(id, savekey);

	debugMsg(id, 1, "Loading XP using key: ^"%s^"", savekey);

	// Check Memory Table First
	if (memoryTableRead(id, savekey))
		debugMsg(id, 8, "XP Data loaded from memory table");
	else if (loadXP(id, savekey))
		debugMsg(id, 8, "XP Data loaded from Vault, nVault, or MySQL save");
	else // XP not able to load, will try again next round
		return;

	flag_clear(gReadXPNextRound, id);
	memoryTableUpdate(id);
	displayPowers(id, false);
}
//----------------------------------------------------------------------------------------------
getSaveKey(id, savekey[32])
{
	if (is_user_bot(id)) {
		static botName[32];
		get_user_name(id, botName, charsmax(botName));

		// Get Rid of BOT Tag

		// PODBot
		replace(botName, charsmax(botName), "[POD]", "");
		replace(botName, charsmax(botName), "[P*D]", "");
		replace(botName, charsmax(botName), "[P0D]", "");

		// CZ Bots
		replace(botName, charsmax(botName), "[BOT] ", "");

		// Attempt to get rid of the skill tag so we save with bots true name
		new lastchar = strlen(botName) - 1;
		if (botName[lastchar] == ')') {
			for (new x = lastchar - 1; x > 0; --x) {
				if (botName[x] == '(') {
					botName[x - 1] = 0;
					break;
				}
				if (!isdigit(botName[x]))
					break;
			}
		}
		if (botName[0] != '^0') {
			replace_string(botName, charsmax(botName), " ", "_");
			formatex(savekey, charsmax(savekey), "[BOT]%s", botName);
		}
	} else {	
		switch (CvarSaveBy) {
			//Forced save XP by name
			case 0: {
				get_user_name(id, savekey, charsmax(savekey));
			}

			//Auto Detect, save XP by SteamID or IP if LAN (default)
			case 1: {
				// Hack for STEAM's retardedness with listen servers
				if (id == 1 && !is_dedicated_server()) {
					copy(savekey, charsmax(savekey), "loopback");
				} else if (CvarLan) {
					get_user_ip(id, savekey, charsmax(savekey), 1); // by ip without port
				} else {
					get_user_authid(id, savekey, charsmax(savekey)); // by steamid

					//Check both STEAM_ID_ and VALVE_ID_
					if (equal(savekey[9], "LAN"))
						get_user_ip(id, savekey, charsmax(savekey), 1); // by ip without port
					else if (equal(savekey[9], "PENDING"))
						return false; // steamid not loaded yet, try again
				}
			}

			//Forced save XP by IP
			case 2: {
				get_user_ip(id, savekey, charsmax(savekey), 1);
			}
		}
	}

	// Check to make sure we got something useable
	if (savekey[0] == '^0')
		return false;

	return true;
}
//----------------------------------------------------------------------------------------------
checkBan(id, const bankey[32])
{
	if (!file_exists(gBanFile) || flag_get_boolean(gIsPowerBanned, id))
		return;

	new bool:idBanned, data[32];

	debugMsg(id, 4, "Checking for ban using key: ^"%s^"", bankey);

	new banFile = fopen(gBanFile, "rt");

	if (!banFile) {
		debugMsg(0, 0, "Failed to open nopowers.cfg, please verify file/folder permissions");
		return;
	}

	while (!feof(banFile) && !idBanned) {
		fgets(banFile, data, charsmax(data));
		trim(data);

		switch (data[0]) {
			case '^0', '^n', ';', '/', '\', '#': continue;
		}

		if (equali(data, bankey) ) {
			idBanned = true;
			flag_set(gIsPowerBanned, id);
			debugMsg(id, 1, "Ban loaded from banlist for this player");
		}
	}

	fclose(banFile);
}
//----------------------------------------------------------------------------------------------
memoryTableUpdate(id)
{
	if (!CvarSuperHeros || !CvarSaveXP)
		return;
	
	if (flag_get_boolean(gIsPowerBanned, id) || flag_get_boolean(gReadXPNextRound, id))
		return;

	// Update this XP line in Memory Table
	static savekey[32], x, powerCount;

	if (!getSaveKey(id, savekey))
		return;

	// Check to see if there's already another id in that slot... (disconnected etc.)
	if (gMemoryTableKeys[id][0] != '^0' && !equali(gMemoryTableKeys[id], savekey)) {
		if (gMemoryTableCount < gMemoryTableSize) {
			copy(gMemoryTableKeys[gMemoryTableCount], charsmax(gMemoryTableKeys[]), gMemoryTableKeys[id]);
			copy(gMemoryTableNames[gMemoryTableCount], charsmax(gMemoryTableNames[]), gMemoryTableNames[id]);
			gMemoryTableXP[gMemoryTableCount] = gMemoryTableXP[id];
			gMemoryTableFlags[gMemoryTableCount] = gMemoryTableFlags[id];
			powerCount = gMemoryTablePowers[id][0];

			for (x = 0; x <= powerCount && x <= SH_MAXLEVELS; ++x)
				gMemoryTablePowers[gMemoryTableCount][x] = gMemoryTablePowers[id][x];

			++gMemoryTableCount; // started with position 33
		}
	}

	// OK copy to table now - might have had to write 1 record...
	copy(gMemoryTableKeys[id], charsmax(gMemoryTableKeys[]), savekey);
	get_user_name(id, gMemoryTableNames[id], charsmax(gMemoryTableNames[]));
	gMemoryTableXP[id] = gPlayerXP[id];
	gMemoryTableFlags[id] = gPlayerFlags[id];

	powerCount = getPowerCount(id);
	for (x = 0; x <= powerCount && x <= SH_MAXLEVELS; ++x)
		gMemoryTablePowers[id][x] = gPlayerPowers[id][x];
}
//----------------------------------------------------------------------------------------------
memoryTableRead(id, const savekey[])
{
	if (!CvarSuperHeros)
		return false;

	static x, p, idLevel, powerCount, heroIndex;

	for (x = 1; x < gMemoryTableCount; ++x) {
		if (gMemoryTableKeys[x][0] != '^0' && equal(gMemoryTableKeys[x], savekey)) {
			gPlayerXP[id] = gMemoryTableXP[x];
			idLevel = gPlayerLevel[id] = getPlayerLevel(id);
			setLevel(id, idLevel);
			gPlayerFlags[id] = gMemoryTableFlags[id];

			// Load the Powers
			gPlayerPowers[id][0] = 0;
			powerCount = gPlayerPowers[id][0] = gMemoryTablePowers[x][0];
			for (p = 1; p <= idLevel && p <= powerCount; p++) {
				heroIndex = gPlayerPowers[id][p] = gMemoryTablePowers[x][p];
				initHero(id, heroIndex, SH_HERO_ADD);
			}

			// Null this out so if the id changed - there won't be multiple copies of this guy in memory
			if (id != x) {
				gMemoryTableKeys[x][0] = '^0';
				memoryTableUpdate(id);
			}

			// Notify that this was found in memory...
			return true;
		}
	}
	return false; // If not found in memory table...
}
//----------------------------------------------------------------------------------------------
public plugin_end()
{
	// SAVE EVERYTHING...
	log_message("[SH] Making final XP save before plugin unloads");
	memoryTableWrite();

	// Final cleanup in the saving include
	saving_end();
}
//----------------------------------------------------------------------------------------------
readINI()
{
	new levelINIFile[128];
	formatex(levelINIFile, charsmax(levelINIFile), "%s/superhero.ini", gSHConfigDir);

	if (!file_exists(levelINIFile))
		createINIFile(levelINIFile);

	new levelsFile = fopen(levelINIFile, "rt");

	if (!levelsFile) {
		debugMsg(0, 0, "Failed to open superhero.ini, please verify file/folder permissions");
		return;
	}

	// Only called once no need for static
	new data[1501], tag[20];
	new numLevels[6], loadCount = -1;
	new XP[1501], XPG[1501];
	new LeftXP[32], LeftXPG[32];

	while (!feof(levelsFile)) {
		fgets(levelsFile, data, charsmax(data));
		trim(data);

		if (data[0] == '^0' || equal(data, "##", 2))
			continue;

		if (equali(data, "NUMLEVELS", 9))
			parse(data, tag, charsmax(tag), numLevels, charsmax(numLevels));
		else if ((equal(data, "XPLEVELS", 8) && !CvarSaveXP) || (equal(data, "LTXPLEVELS", 10) && CvarSaveXP))
			copy(XP, charsmax(XP), data);
		else if ((equal(data, "XPGIVEN", 7) && !CvarSaveXP) || (equal(data, "LTXPGIVEN", 9) && CvarSaveXP))
			copy(XPG, charsmax(XPG), data);
	}
	fclose(levelsFile);

	if (numLevels[0] == '^0') {
		debugMsg(0, 0, "No NUMLEVELS Data was found, aborting INI Loading");
		return;
	} else if (XP[0] == '^0') {
		debugMsg(0, 0, "No XP LEVELS Data was found, aborting INI Loading");
		return;
	} else if (XPG[0] == '^0') {
		debugMsg(0, 0, "No XP GIVEN Data was found, aborting INI Loading");
		return;
	}

	debugMsg(0, 1, "Loading %s XP Levels", CvarSaveXP ? "Long Term" : "Short Term");

	gNumLevels = str_to_num(numLevels);

	// This prevents variables from getting overflown
	if (gNumLevels > SH_MAXLEVELS) {
		debugMsg(0, 0, "NUMLEVELS in superhero.ini is defined higher than MAXLEVELS in the include file. Adjusting NUMLEVELS to %d", SH_MAXLEVELS);
		gNumLevels = SH_MAXLEVELS;
	}

	// Get the data tag out of the way
	argbreak(XP, LeftXP, charsmax(LeftXP), XP, charsmax(XP));
	argbreak(XPG, LeftXPG, charsmax(LeftXPG), XPG, charsmax(XPG));

	while (XP[0] != '^0' && XPG[0] != '^0' && loadCount < gNumLevels) {
		++loadCount;

		argbreak(XP, LeftXP, charsmax(LeftXP), XP, charsmax(XP));
		argbreak(XPG, LeftXPG, charsmax(LeftXPG), XPG, charsmax(XPG));

		gXPLevel[loadCount] = str_to_num(LeftXP);
		gXPGiven[loadCount] = str_to_num(LeftXPG);

		switch (loadCount) {
			case 0: {
				if (gXPLevel[loadCount] != 0) {
					debugMsg(0, 0, "Level 0 must have an XP setting of 0, adjusting automatically");
					gXPLevel[loadCount] = 0;
				}
			}
			default: {
				if (gXPLevel[loadCount] < gXPLevel[loadCount - 1]) {
					debugMsg(0, 0, "Level %d is less XP than the level before it (%d < %d), adjusting NUMLEVELS to %d", loadCount, gXPLevel[loadCount], gXPLevel[loadCount - 1], loadCount - 1);
					gNumLevels = loadCount - 1;
					break;
				}
			}
		}

		debugMsg(0, 3, "XP Loaded - Level: %d  -  XP Required: %d  -  XP Given: %d", loadCount, gXPLevel[loadCount], gXPGiven[loadCount]);
	}

	if (loadCount < gNumLevels) {
		debugMsg(0, 0, "Ran out of levels to load, check your superhero.ini for errors. Adjusting NUMLEVELS to %d", loadCount);
		gNumLevels = loadCount;
	}

	// Add upper boundary after getting gNumLevels
	set_pcvar_bounds(sh_minlevel, CvarBound_Upper, true, float(gNumLevels));
}
//----------------------------------------------------------------------------------------------
createINIFile(const levelINIFile[])
{
	new levelsFile = fopen(levelINIFile, "wt");
	if (!levelsFile) {
		debugMsg(0, 0, "Failed to create superhero.ini, please verify file/folder permissions");
		return;
	}

	fputs(levelsFile, "## NUMLEVELS  - The total Number of levels to award players^n");
	fputs(levelsFile, "## XPLEVELS   - How much XP does it take to earn each level (0..NUMLEVELS)^n");
	fputs(levelsFile, "## XPGIVEN    - How much XP is given when a Level(N) player is killed (0..NUMLEVELS)^n");
	fputs(levelsFile, "## LTXPLEVELS - Same as XPLEVELS but for Long-Term mode (sh_savexp 1)^n");
	fputs(levelsFile, "## LTXPGIVEN  - Same as XPGIVEN but for Long-Term mode (sh_savexp 1)^n");

	// Straight from WC3 - but feel free to change it in the INI file...
	fputs(levelsFile, "NUMLEVELS  10^n");
	fputs(levelsFile, "XPLEVELS   0 100 300 600 1000 1500 2100 2800 3600 4500 5500^n");
	fputs(levelsFile, "XPGIVEN    60 80 100 120 140 160 180 200 220 240 260^n");
	fputs(levelsFile, "LTXPLEVELS 0 100 200 400 800 1600 3200 6400 12800 25600 51200^n");
	fputs(levelsFile, "LTXPGIVEN  6 8 10 12 14 16 20 24 28 32 40");

	fclose(levelsFile);
}
//----------------------------------------------------------------------------------------------
createHelpMotdFile(const helpMotdFile[])
{
	// Write as binary so if created on windows server the motd won't display double spaced
	new helpFile = fopen(helpMotdFile, "wb");
	if (!helpFile) {
		debugMsg(0, 0, "Failed to create sh_helpmotd.txt, please verify file/folder permissions");
		return;
	}

	fputs(helpFile, "<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><body><pre>^n");

	fputs(helpFile, "<b>How to get Heroes:</b>^n");
	fputs(helpFile, "As you kill opponents you gain Experience Points (XP), once you have^n");
	fputs(helpFile, "accumulated enough for a level up you will be able to choose a hero.^n");
	fputs(helpFile, "The higher the level of the person you kill the more XP you get.^n");
	fputs(helpFile, "The default starting point is level 0 and you cannot select any heroes.^n^n");

	fputs(helpFile, "<b>How to use Binds:</b>^n");
	fputs(helpFile, "To use some hero's powers you have to bind a key to:^n");
	fputs(helpFile, "	+power#^n^n");
	fputs(helpFile, "In order to bind a key you must open your console and use the bind command:^n");
	fputs(helpFile, "	bind ^"key^" ^"command^"^n^n");
	fputs(helpFile, "In this case the command is ^"+power#^". Here are some examples:^n");
	fputs(helpFile, "	bind f +power1		bind MOUSE3 +power2^n^n");

	fputs(helpFile, "<b>Available Say Commands:</b>^n");
	fputs(helpFile, "say /superherohelp	- This help menu^n");
	fputs(helpFile, "say /showmenu		- Displays Select Super Power menu^n");
	fputs(helpFile, "say /herolist		- Lets you see a list of heroes and powers^n");
	fputs(helpFile, "say /myheroes		- Displays your heroes^n");
	fputs(helpFile, "say /clearpowers	- Clears ALL powers^n");
	fputs(helpFile, "say /drop <hero>		- Drop one power so you can pick another^n");
	fputs(helpFile, "say /whohas <hero>		- Shows you who has a particular hero^n");
	fputs(helpFile, "say /playerskills [@ALL|@CT|@T|name] - Shows you what heroes other players have chosen^n");
	fputs(helpFile, "say /playerlevels [@ALL|@CT|@T|name] - Shows you what levels other players are^n^n");

	fputs(helpFile, "say /automenu	- Enable/Disable auto-show of Select Super Power menu^n");
	fputs(helpFile, "say /helpon	- Enable HUD Help message (by default only shown when dead)^n");
	fputs(helpFile, "say /helpoff	- Disable HUD Help message^n^n");

	fputs(helpFile, "Mod's Official Site: http://shero.alliedmods.net/");

	fputs(helpFile, "</pre></body></html>");

	fclose(helpFile);
}
//----------------------------------------------------------------------------------------------
buildHelpHud()
{
	// Max characters hud messages can be is 479
	// Message is 338 characters currently
	new n;
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "SuperHero Mod Help^n^n");

	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "How To Use Powers:^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "--------------------^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "Input bind into console^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "Example:^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "bind h +power1^n^n");

	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "Say Commands:^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "--------------------^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/help^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/clearpowers^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/showmenu^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/drop <hero>^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/herolist^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/playerskills^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/playerlevels^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/myheroes^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "/automenu^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "--------------------^n");
	n += copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "Enable This HUD:  /helpon^n");
	copy(gHelpHudMsg[n], charsmax(gHelpHudMsg) - n, "Disable This HUD: /helpoff");
}
//----------------------------------------------------------------------------------------------
