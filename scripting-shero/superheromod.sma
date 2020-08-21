/* AMX Mod X script.
*
*   SuperHero Mod (superheromod.sma)
*
*****************************************************************************/

// XP Saving Method
// **Make sure only ONE is uncommented**
//#define SAVE_METHOD 1		//Saves XP to vault.ini (Note: Use also for non-save xp to avoid loading extra modules)
#define SAVE_METHOD 2		//Saves XP to superhero nVault (default)
//#define SAVE_METHOD 3		//Saves XP to a MySQL database

/****************************************************************************
*
*   Version 1.3.0 - Date: 08/10/2020
*
*   Original by {HOJ} Batman <johnbroderick@sbcglobal.net>
*
*   Formerly being maintained by the SuperHero Team
*   http://shero.alliedmods.net/index.php?page=credit
*
*   Currently being maintained by Sycri (Kristaps08)
*   https://github.com/Sycri/AMXXCollection
*
****************************************************************************
*
*  GOALS
*   1) keep # of binds small and determinable (i.e. no matter what new heroes come along)
*   2) reuse binds amongst heroes (so you don't have to keep rebinding)
*   3) modular heroes - can add and take away using plugins.ini and separate hero *.sma scripts
*
*  Admin Commands:
*
*    amx_shsetxp			- Allows admins to set a players XP to a specified amount
*    amx_shaddxp			- Allows admins to give a players a specified amount of XP
*    amx_shsetlevel			- Allows admins to set a players level to a specified number
*    amx_shban				- Allows admins to ban players from using powers
*    amx_shunban			- Allows admins to un-ban players from using powers
*    amx_shimmunexp			- Allows admins to set/unset players immune from save days XP reset (Unavailable for nVault)
*    amx_shresetxp			- Allows admins with ADMIN_RCON to reset all the saved XP
*
*  Client Command:
*
*    say /help				- Shows help window with all other client commands.
*
*  CVARs: Plase See the shconfig.cfg for the cvar settings
*
*                     ******** FUN Module REQUIRED ********
*                  ********  Fakemeta Module REQUIRED ********
*                 *******  Ham Sandwich Module REQUIRED *******
*                  ********  CStrike Module REQUIRED  ********
*                     ******** CSX Module REQUIRED ********
*
*  Changelog:
*
*  v1.3.0 - Sycri (Kristaps08) - 08/20/20
*	- Changed the function chatMessage so that it uses client_print_color
*	- Changed most cvars from get_pcvar_num to bind_pcvar_num so variables could be used directly
*	- Changed from RegisterHamFromEntity to RegisterHamPlayer for cleaner code
*	- Forced usage of semicolons for better clarity
*	- Removed SH_MAXSLOTS and replaced it with MAX_PLAYERS since the latter is in AMX Mod X core
*	- Removed all backwards compatibility
*	- Removed code that uses old syntax for MySQL 3.23
*	- Removed cvar sh_adminaccess in favor of cmdaccess.ini
*	- Removed repetitive checks in natives
*	- Removed variables which cache cvars since AMX Mod X 1.9.0 does it now itself
*	- Renamed nearly all functions for a unified style
*	- Replaced client command buy blocking with forward CS_OnBuy
*	- Replaced deprecated function client_disconnect with client_disconnected
*	- Replaced deprecated function strbreak with argbreak
*	- Replaced event CurWeapon with forward Ham_CS_Item_GetMaxSpeed for more reliable speed change
*	- Replaced forward FM_Touch with Ham_Touch since the former is less efficient
*	- Replaced register_cvar with create_cvar
*	- Replaced variable gServersMaxPlayers with MaxClients which is available in AMX Mod X since version 1.8.3
*	- Rewrote parts of the SuperHero Core and included heroes
*	- Separated SuperHero Core into multiple plugins
*
*  v1.2.1 - vittu - ??/??/??
*	- 
*	- Changed SH_ARMOR_RATIO to 0.5 since in cs armor seems to reduce damage by 50% not 80%
*	- Added native sh_set_hero_dmgmult for weapon multipliers to directly hook damage instead of faking damage with sh_extra_damage
*	- Added removal of all Monster Mod monsters on new round, stops monster freezetime attacks
*	- Added option to force save by IP or save by name with cvar sh_saveby
*	- Added option for Free For All servers to gain money/frags/xp on tk instead of losing money/frags/xp on tk with cvar sh_ffa
*	- Fixed shield restrict forcing drop of shield to actually drop shield not just active weapon
*	- Removed /savexp say command due to complaint of the xp removal it has done since version 1.17.4
*	- Converted superheromysql.inc to use sqlx instead of dbi and optimized a bit
*	- Fixed passing of some buffers into format routines
*	- Changed menu string size and made it smaller, it had too much overhead
*	- Added use of charsmax
*	- Removed unnecessary checks and static's in stocks
*	- Fixed Ham_Spawn's first Ham_Spawn call block method
*	- Fix for amb1961: superhero.ini was being read too late causing sh_minlevel and sh_mercyxp cvars to be set improperly by core
*
*  v1.2.0 - JTP10181/vittu - 08/17/08
*	  (took over where JTP10181 left off, mixture of both our work as follows below)
*	- Converted server messages in core plugin to register_natives, better for plugin communication and fixes overflow caused by too many heroes
*	- Converted from engine to fakemeta, integrated cstrike more, and utilized csx natives
*	- Converted to use pcvar system core and heroes
*	- Converted fully to new file system over inefficient write_file methods
*	- Added new natives, renamed old, and added some extra options that were not in old
*	- Added optional modes for reload that can be controlled server wide
*	- Added VIP support, bonus xp for vip assassination/rescue.
*	- Added optional blocks for VIP: power key usage, sh give weapons, ect.
*	- Added cvar for amount of players required to be in server for mercy/hostage/bomb/vip XP
*	- Added config file to disable sh giving of specified weapon based on map
*	- Added camera turn toward attacker on death from sh extradamage (thanks Emp`)
*	- Added damage inflictor to sh extradamage. External plugins might use this ie. ATAC3
*	- Added silence/burst reset to drop weapon reload mode
*	- Added bots choosing powers automatically
*	- Added grey colored chat to prefix chat messages as well as native for it
*	- Added /automenu say option to disable hero menu from showing up on spawn
*	- Added amx_shimmunexp admin command to set users immune from savedays deletion (NOT available for nVault)
*	- Fixed exploit with switching team to gain mercy xp
*	- Fixed sh setting sv_maxspeed when set higher than what sh requires, some heroes might need more than detected by sh
*	- Fixed StatusText info from being over written by name of user in crosshairs
*	- Fixed incorrect amounts in max bpammo and max clip stocks, converted to lookup tables instead of switch statements as well
*	- Fixed shero folder will now be created if it does not exist. Allows cfg files to be created if they do not exist (except shconfig.cfg)
*	- Fixed sh_hsmult to work with extradamage headshots, was not counted before
*	- Fixed clearpowers to send drop on only heroes user had not all heroes server has
*	- Fixed player console playerskills command cutting off hero names in some cases
*	- Fixed speed resetting to default speeds after zooming with a sniper rifle
*	- Fixed bug with keys reversing when HUD shows 0 health
*	- Fixed possible reliable channel overflow on clients from hero_inits running on ResetHUD causing a loop from weapon give
*		(Converted to Ham_Spawn post for better reliablity, this adds hamsandwich to be included by default)
*	- Changed the speed system to use actual weapon speeds when resetting to normal, instead of just setting 210
*	- Changed to track bomb by entity index, cleaner then by bomb holder
*	- Changed how single hostage bonus xp is given by detecting the amount of hostages on a map
*	- Changed hero default cvars lvl/hp/ap/grav/speed to be read by pcvar instead of a global, fixes issue with first map hero cvars not setting
*	- Changed shRemHealthPower, shRemArmorPower, shRemGravityPower, shRemSpeedPower, and shResetShield to be taken care of by the core when hero dropped
*	- Changed help motd into a file, shmotd.txt, and edited its content
*	- Removed Cheating-Death support since it is a dead project
*	- Removed amxmod support since it is a dead project
*	- Removed cvars sh_round_started and sh_cdrequired
*	- Removed suicides from hl logs caused by extradamage
*	- Renamed 3 default heroes Nightcrawler/Windwalker/Zues to Shadowcat/Black Panther/Grandmaster respectively
*	- Renamed cvar sh_bombhostxp to sh_objectivexp
*	- Renamed functions in core for better managability
*	- Recoded all default heroes to have a similar style of coding and optimized them
*       Thanks go to teame06, Emp, and jtpizzalover for their input from my constant badgering of this release.
*       Also, thanks to (msv_), ([S0|0]), and Galore ([G]S) clans for letting me test betas on their servers. - vittu
*
*  v1.18e - JTP10181 - 07/25/06
*	- Fixed runtime error in reloadAmmo caused by bad hero scripting
*	- Allowed addXP to take a Float for the multiplier
*	- Stunning a player now disables their +power keys also (thanks mydas for pointing this out)
*	- Renamed some functions to match the others
*	- Added nVault include file for AMXX only
*	- Fixed issue with Stun and God timers carrying to next round if user stayed alive (thanks vittu)
*	- Fixed bug in timer that made it skip the last second
*	- Fixed exploit in stun system
*	- Fixed bugs in admin commands with case sensitivity
*
*  v1.18d - JTP10181 - 08/27/05
*	- Fixed runtime errors with AMXX 1.55 and MySQL
*	- Fully tested with MySQL 4.1.14, MySQL 4.0.25 and MySQL 3.23.58
*	- Fixed mem leaks from not using dbi_free_result properly
*	- Added define to mysql include for old style syntax
*
*  v1.18c - JTP10181 - 07/31/05
*	- Added some more MercyXP abuse checking
*	- Fixed bug where players could have stale heroes from last player with the same index number
*
*  v1.18a - JTP10181 - 07/19/05
*	- Added check to extradamage for godmode on the target player
*	- Fixed bug in bot XP saving that could cause server lockups
*	- Fixed run time error 4 that occurred when saving the memory table
*
*  v1.18 - JTP10181 - 05/16/05
*	- Fixed bugs with the CVAR checking
*	- Changed speed system hack to be enabled for AMX 0.9.9+ also
*	- Fixed extradamage logging if you kill yourself
*	- Fixed issue with mysql saving XP if the client has a ` or ' in their name.
*	- Added a hack to fix XP saving for listen server admins
*	- Changed debug message logging so the message will always be shown even if server logging is off
*	- Fixed cooldown timer code to prevent a task from the last round interfering in the next round
*		(Requires the hero to be recompiled with new includes)
*	- Made it so when magneto strips a players weapons they vanish instead of ending up on the ground
*	- Extradamage function now does armor calculations and removes it accordingly
*	- Fixed issue with armor that superhero gives you was not being recognized by CS
*	- Fixed issue with server_exec causing the config not to exec for everyone
*	- Increased default SH_MAXLEVELS to 100, sick of all these tards who can't compile
*	- Changed the MySQL include around a bunch, better queries, non-persistent connection, etc...
*		Thanks for the help from HC of superherocs.com
*	- Changed HUDHELP memtable to be player flags for future use
*	- Added admin command logging
*	- Allowing XP lines in superhero.ini to load up to 1024 bytes instead of 512
*	- Added loop for registering power keydowns so it adjusts with SH_MAXBINDPOWERS
*	- Greatly reduced number of SQL queries sent every round if using endround saving,
*		by not re-saving a persons heroes unless they change them.
*	- Fixed bug in extradamage that took away XP for suicide.
*	- Utilized plugin_log native for hostage and bomb XP events, fixing the bugs in them
*	- Added check so people don't get MercyXP for typing "kill" in the console (not available for AMX98)
*	- Prevented XP variable overflow which would cause XP loss to the player
*	- Removed XP checks in adminSetXP since the above fix prevents overflows
*
*  v1.17.6 - JTP10181 - 12/15/04
*	- Made it so menu is not auto-displayed for spectators
*	- Fixed bug, giving wrong XP ammout if you get a HS and are using the HSMULT setting
*	- Fixed bug, reload ammo function would slow down user if using the drop weapon setting
*	- Added functionality to remeber XP for bots by thier names
*	- Eliminated cpalive CVAR, set sh_cmdprojector to "2" for the same effect
*	- Heroes using extradamage now send the correct weapon name if they are only multiplying the damage
*	- Added ability to send shExtraDamage as a headshot so the kill shows up correctly
*	- Fixed small bug in playerskills console output
*	- Fixed version CVAR so it will change when upgrading without a server restart
*	- Plugin tries to make SQL tables if they don't exist already
*	- Fixed bug if superhero is disabled no one could chat.
*	- Tweaked the speed system to make it spam less on AMXModX
*	- Made the admin commands idiot proof
*	- Made use of plugin_cfg() stock instead of a task
*	- Fixed bug, extradamage would not let you kill yourself
*	- Added check so sh_xpsavedays cannot bet set higher than 365
*	- Added checks for other CVARS since people like to do stupid things
*	- Fixed issue with people binding to +power1; +power1; +power1;.....
*	- Changed function of sh_bombhostxp again, it was too confusing the way it was
*	- Added check so core can only be loaded once (not available on AMX 0.9.9+)
*	- Fixed bug with non-saved XP, XP never intialiazing.
*
*  v1.17.5 - JTP10181 - 10/03/04
*	- AMXX 0.20 Support (Vault and MySQL)
*	- Tweaks to godmode coding to prevent problems
*	- Fixed anubis errors on AMXX
*	- Fixed Batman "Reliable channel overflow" problems on AMXX
*	- Cleaned up code on all heroes, redid indenting, removed useless code.
*	- Successful bomb plant will now give entire alive team XP
*	- Added event to catch round end if triggered by sv_restart
*	- Tweaked hostage and bomb XP to make it more evenly distributed
*	- Added new function to include to reload clients ammo (see sh_punisher.sma for example)
*	- Fixed some stuff in the include for AMXX
*	- Reworked vault data parsing to remove hardcoded limit of loading only 20 skills (heroes)
*	- Rewrote readINI function to use new strbrkqt stock
*	- Moved all the shExtraDamage code into the core
*	- Fixed readXP so it will not get processed more than once on a player
*	- Added new hero command to set a shield restriction (see sh_batman.sma for example)
*	- Found a more reliable way to detect hostage rescue and get players id
*	- Fixed some bugs in the stun system
*
*  v1.17.4 - JTP10181 - 09/05/04
*	- Fixed "playerskills" bug with some skills getting cut off
*	- Fixed bug with XP not displaying until after freezetime
*	- Hero Levels should now load correctly from cvars on the first map
*	- Fixed "whohas" that has been broken for a long time I assume
*	- Fixed bug in "drop" command when client has the max powers allowed on the server
*	- Increased plugins available memory as it was teetering near the edge of runtime 3 issues.
*	- Tweaked string array lengths to make plugin use less memory
*	- Finally fixed menu bug causing it to say a hero was disabled when it wasn't
*	- Added code to restrict dropping while alive and a cvar to enable / disable it.
*	- Fixed bug in godmode code so one godmode wont cancel another out
*	- "File" saving support totally removed (vault saving is still the default)
*	- Added support for AMX 0.9.9
*
*  v1.17.3 - JTP10181 - 08/27/04
*	- Fixed bug with loadimmediate and some people loosing XP
*	- Fixed bug with ban code if file did not end in a newline
*	- Added checks to make sure authid is valid before trying to load XP
*	- Made autobalance setting get ignored when savexp is on
*	- Fixed more bugs with XP not loading correctly.
*	- Added admin command to reset all the XP
*	- Worked a lot on the MySQL include to make it work better overall
*	- Added a bunch of checks to cancel events for bots (better CZ support also)
*	- Found a way to reset speed without forcing a weapon switch
*	- Fixed bugs with menu resetting to page 1 while you are in it
*	- Made it so powers are not disabled (for freezetime) until the first person spawns
*	- Changed function of debug cvar, it is now the debugging level.
*
*  v1.17.2 - JTP10181 - 08/17/04
*	- Fixed runtime errors if you exceed the MAXHEROS amount
*	- Fixed bug with playSoundDenySelect, changed to client spk so others cannot hear it
*	- Made banning system use less files reads, with the old method it
*		would have caused lag with a large ban file
*	- Redid banning support, can now unban also.
*	- Changed debugMsg function again, to backward support non-stock heroes
*	- Fixed more bugs with stale menus after certain commands
*	- Fixed some issues with variables that could have been causing memory problems
*	- Fixed some menu issues that arose with the last release
*	- Added a cvar to put the menu back how it used to be where it hides disabled heroes
*	- Added a cvar to change (or disable) the level limiting in the menu
*	- Tweaked the way things load on first startup to hopefully fix cvar issues people are having
*	- Found recursion problem causing runtime error 3 and fixed it
*	- If a level is lost the plugin will remove heroes you should not have anymore
*	- Added HeadShot multiplyer cvar to give extra XP for headshots
*
*  v1.17.1 - JTP10181 - 08/12/04
*	- Redid the new round code, should have fixed some bugs with the feezetime being 0
*	- Fixed bug with sh_adminaccess not getting loaded from config before being set as level for commands
*	- Redid the debugging messages system
*	- Redid the readINI function to make it more versatile
*	- Fixed bug with giving XP for hostage rescue
*	- Removed some useless code in the hostage rescue system
*	- Added status messages for the XP given on bomb and hostage events
*	- Changed use of sh_bombhostxp cvar. It now sets the level of XP given/taken for the events
*		Set CVAR to -1 to disable the XP bonuses
*	- Changed the default admin flag because for some reason it was set to the admin_immunity flag
*	- Fixed vault saving by IP so it wont use the port anymore, only the IP
*	- Blocked fullupdate client command to prevent exploiting and resetting cooldown timers and other bad things.
*	- Changed the menu system to make it less confusing why some heroes are not available
*	- Added extra codes to the menu system
*	- Grayed out disabled menu items instead of hiding them
*	- Error message if no argument supplied to /whohas
*	- Added Power Number to /herolist output
*	- Fixed bug in the clearpower function causing hero ids to be out of place in the players array
*	- Redid the damage function in the inc file, blocking death messages with vexd and updating scoreboard properly
*	- Fixed bug with clearpowers when menu was on screen, it would be stale and not refresh
*	- Added function to adjust the servers sv_maxspeed so speed increasing heroes can work properly
*	- Redid the layout for most of the stock heroes so its more standardized.
*	- Removed xtrafun from all heroes possible to better support amx 0.9.9.
*
*  v1.17 - JTP10181 - 07/27/04
*	- Updated all motd box output to be more easy to follow
*	- Fixed bug if only one hero left to pick it would not be displayed
*	- Fixed bug with setting the speed system
*	- Fixed admin commands to follow better standards
*	- Added mercy XP system to give players who gained no XP a small boost each round
*	- cmd_projector merged in with this plugin
*
*  REV 1.16.0 - (ASSKICR) Fixed save by ip if sv_lan = 1
*  REV 1.14.8 - (ASSKICR) Fixed the 1.6 speed bug
*  REV 1.14.7 - (ASSKICR) Made some fixes in newround
*  REV 1.14.6 - (ASSKICR) Made it save XP by STEAMID for 1.6 and WONID for 1.5
*  REV 1.14.5 - (ASSKICR) - Made a few more commands for XP and a command to block powers
*  REV 1.14.4 - added ability to point mysql database to another database than the default amx database if these cvars exists: sh_mysql_db, sh_mysql_user, sh_mysql_pass, sh_mysql_db
*  REV 1.14.3 - bug fix playerpower missed 1 level.  amx_vaulttosql didn't strip shinfo. cleanXP() mysql delete now does sh_saveskills to
*  REV 1.14.2 - bug fix - "re"-joiners loose certain hero skills
*  REV 1.14.1 - mysql, cvars(sh_loadimmediate), say commands(playerskills, playerlevels, whohas),
*               command (amx_vaulttosql) if mysqlmode...
*               Initialize via server command instead of plugin_ini
*               depricated cvar( sh_usevault)
*               small Xavier disconect test
*               small change in displayPowers (now shows how many levels are earnable)
*  REV 1.13.3 - MSG_ONE gaurd to try and eliminate writedest crashes
*  REV 1.13.2 - unabomber radius change, bomberman, cyclops slightly, anubis
*  REV 1.13.1- changed xavier, rolled in aquaman
*  REV 1.12b - reviewing xtrafun based heroes: ironman, skeletor, spiderman, xavier ( make sure user is alive b4 getting origin on new_round), nightcrawler, windwalker
*              Going to try and eliminate xtrafun calls on new joiners to see if can elimnate the crashes.
*  REV 1.12a - fixed loadXP bug - ppl losing XP - various small checks
*  REV 1.11b  - not using max_players() function any longer - test...
*  REV 1.11a - Made hero levels a number instead of reading cvars..., changes cleanXP to make a little better
*  REV 1.10f - take out playerpowerflags..., gaurded key presses by gPlayerBinds instead of gPlayerPowers
*  REV 1.10d - make bomb/hostage, speed, health, armor, gravity turned into vars instead of cvar reads
*  REV 1.10c - refined speed hack bug fix, FIXED playerskills 4096 vs 2048 copy problem
*             changed batman and hob to zeus with weapons.  Batman no longer gets defuse packs.
*  REVE 1.10b
*  REV  1.10a
*  REV 1.09 - commented out client_connect code (should be done on disconnect), make sure user is alive on newRound(),
*             added startround,endround logic to pop client menus to people just joining
*  REV 1.08 - readMemoryTable make sure key is >0, sh_round_started only set once
*  REV 1.07 - fixed unabomber, fixed loading guy with more than sh_maxpowers, addes sh_endroundsave
*  REV 1.06 - removed messaging from heroes - wolv heals to 100, drac to 100
*  REV 1.05 - ADDED sh_maxpowers, removed register loops, added regMaxHealth
*  REV 1.04 - REMOVED CVARS AS A WAY TO COMMUNICATE PLAYER LEVELS AND PLAYER MAXHEALTH
*  REV 1.03 - PROVED CVARS WERE CRASHING SERVER
*  REV 1.02 Beta
*  6/1/2003  - strunpack to copies and changed diminsions - testing crashes large servers
*  5/16/2003 - Fixed mid-round join bug
*  5/17/2003 - Added amx_shsetlevel, amx_shxpspeed, console playerskills
*
*  Thanks to ST4life for the orginal time projector that was used for the cmd projector
*  Thanks to asskicr for his verison which this is based off of
*
*
*  To-Do:
*
*	- Admin menu for giving XP / levels / etc. Also for resetting and other admin commands. (separate plugin).
*	- Config file to make heroes only available to certain access flags.
*	- Create a Block weapon fire/sound/animation for laser type heroes instead of having them switch to knife.
*	- Look into blocking power key use native maybe by user / hero id.
*	- Find different method to indicate sh_set_godmode (remove forced blue glow).
*	- CVAR for old style XP modding - how fast to level ("slow", "medium", "fast", "normal", "long").
*	- Make superhero IDs start at 1 not 0.
*	- Get rid of binaries tables in mysql.
*	- Make command to autogenerate ini up to X levels.
*	- Save sh bans using flag into saved data instead of the ban file (possible issue with nvault, and that data must be saved then).
*	- Add gravity settings based on current weapon (incomplete currently).
*	- Make use of multilingual support for "core" messages only.
*	- Remove all use of set_user_info, find a better method to tell when a power is in use (possibly native so hero can say it's in use).
*	- Possibly change extradamage death to use hamsandwhich Ham_TakeDamage (Maybe have both options?).
*	- Run a check to make sure no menu is open before opening powers menu.
*	- Add chosen hero child page to menu to verify hero choice, but mainly to add hero info there instead of using hud messages for powerHelp info.
*	- Find a better method for blocking shield with primary bug or refine currently used one.
*	- Clean up any issues with the say commands.
*	- Possibly use threading only for mysql saving at round end (may require too much recoding).
*	- Convert the read_file usage in superheromysql.inc to use new file natives.
*	- Add check to skip power key if pressed too fast to stop aliasing multiple power keys at the same time.
*	- Make sh more csdm/respawn friendly, remove reliance on round ending
* 	- Improve sh_minplayersxp to count only players that are on a team
* 	- Make restricting bonus xp bomb tracking optional
*
**************************************************************************/

//By default, plugins have 4KB of stack space.
//This gives the plugin a little more memory to work with (6144 or 24KB is sh default)
#pragma dynamic 6144

//Sets the size of the memory table to hold data until the next save
#define gMemoryTableSize 64

//Amount of heroes at a time to display in the amx_help style console listing
#define HEROAMOUNT 10

//Lets includes detect if the core is loading them or a hero
#define SHCORE

#include <amxmodx>
#include <amxmisc>
#include <superheromod>
#include <sh_core_objectives>
#include <sh_core_hpap>

#pragma semicolon 1

new const SH_PLUGIN_STR[] = "[SH] Core: Main";

// Parms Are: Hero, Power Description, Help Info, Needs A Bind?, Level Available At
enum enumHeros { hero[25], superpower[50], help[128], requiresKeys, availableLevel };

// The Big Array that holds all of the heroes, superpowers, help, and other important info
new gSuperHeros[SH_MAXHEROS][enumHeros];
new gSuperHeroCount = 0;

// Changed these from CVARS to straight numbers...
new gHeroMaxSpeed[SH_MAXHEROS];
new gHeroSpeedWeapons[SH_MAXHEROS][31]; // array weapons of weapon's i.e. {4,30} Note:{0}=all
new gHeroMinGravity[SH_MAXHEROS];
new gHeroLevelCVAR[SH_MAXHEROS];
new gHeroMaxDamageMult[SH_MAXHEROS][31];

// Player Variables Used by Various Functions
// Player IDS are base 1 (i.e. 1-32 so we have to diminsion for 33)
new gPlayerPowers[MAX_PLAYERS + 1][SH_MAXLEVELS + 1];     // List of all Powers - Slot 0 is the superpower count
new gPlayerBinds[MAX_PLAYERS + 1][SH_MAXBINDPOWERS + 1];  // What superpowers are the bind keys bound
new gPlayerFlags[MAX_PLAYERS + 1];
new gPlayerMenuOffset[MAX_PLAYERS + 1];
new gPlayerMenuChoices[MAX_PLAYERS + 1][SH_MAXHEROS + 1]; // This will be filled in with # of heroes available
new gMaxPowersLeft[MAX_PLAYERS + 1][SH_MAXLEVELS + 1];
new gPlayerStunTimer[MAX_PLAYERS + 1];
new Float:gPlayerStunSpeed[MAX_PLAYERS + 1];
new gPlayerGodTimer[MAX_PLAYERS + 1];
new gPlayerStartXP[MAX_PLAYERS + 1];
new gPlayerLevel[MAX_PLAYERS + 1];
new gPlayerXP[MAX_PLAYERS + 1];
new gXPLevel[SH_MAXLEVELS + 1];
new gXPGiven[SH_MAXLEVELS + 1];
new bool:gNewRoundSpawn[MAX_PLAYERS + 1];
new bool:gIsPowerBanned[MAX_PLAYERS + 1];
new bool:gInMenu[MAX_PLAYERS + 1];
new bool:gReadXPNextRound[MAX_PLAYERS + 1];
new bool:gFirstRound[MAX_PLAYERS + 1];
new bool:gBlockMercyXp[MAX_PLAYERS + 1];
new Float:gReloadTime[MAX_PLAYERS + 1];
new gInPowerDown[MAX_PLAYERS + 1][SH_MAXBINDPOWERS + 1];
new bool:gChangedHeroes[MAX_PLAYERS + 1];
new bool:gPlayerPutInServer[MAX_PLAYERS + 1];
//new Float:gLastKeydown[MAX_PLAYERS + 1]

// Other miscellaneous global variables
new gHelpHudMsg[340];
new gmsgStatusText, gmsgScoreInfo, gmsgDeathMsg, gmsgDamage;
new bool:gRoundFreeze;
new bool:gRoundStarted;
new bool:gBetweenRounds;
new bool:gGiveMercyXP = true;
new gNumLevels = 0;
new gMenuID = 0;
new gHelpHudSync, gHeroHudSync;
new bool:gMapBlockWeapons[31]; //1-30 CSW_ constants
new bool:gXrtaDmgClientKill;
new gXrtaDmgWpnName[32];
new gXrtaDmgAttacker;
new gXrtaDmgHeadshot;
new bool:gMonsterModRunning;

//Memory Table Variables
new gMemoryTableCount = 33;
new gMemoryTableKeys[gMemoryTableSize][32];					// Table for storing xp lines that need to be flushed to file...
new gMemoryTableNames[gMemoryTableSize][32];				// Stores players name for a key
new gMemoryTableXP[gMemoryTableSize];						// How much XP does a player have?
new gMemoryTableFlags[gMemoryTableSize];					// User flags for other settings (see below)
new gMemoryTablePowers[gMemoryTableSize][SH_MAXLEVELS + 1];	// 0=# of powers, 1=hero index, etc...

//Config Files
new gSHConfigDir[128], gBanFile[128], gSHConfig[128], gHelpMotd[128];

//CVARs Bound To Variables
new CvarSuperHeros, CvarAliveDrop, CvarAutoBalance, CvarCmdProjector;
new CvarDebugMessages, CvarEndRoundSave, Float:CvarHSMult, CvarLoadImmediate, CvarLvlLimit;
new CvarMaxBinds, CvarMaxPowers, CvarMenuMode, CvarMercyXPMode, CvarSaveXP;
new CvarSaveBy, CvarXPSaveDays, CvarMinPlayersXP, CvarReloadMode, CvarFreeForAll;
new CvarFriendlyFire, CvarLan;

//PCVARs
new sh_mercyxp, sh_minlevel;
new sv_maxspeed;

//Forwards
new fwdReturn;
new fwd_HeroInit, fwd_HeroKey, fwd_Spawn, fwd_Death;
new fwd_RoundStart, fwd_RoundEnd, fwd_NewRound;

//Level up sound
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
	sh_mercyxp = create_cvar("sh_mercyxp", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("sh_mercyxpmode", "1"), CvarMercyXPMode);
	sh_minlevel = create_cvar("sh_minlevel", "0", .has_min = true, .min_val = 0.0);
	bind_pcvar_num(create_cvar("sh_savexp", "1"), CvarSaveXP);
	bind_pcvar_num(create_cvar("sh_saveby", "1"), CvarSaveBy);
	bind_pcvar_num(create_cvar("sh_xpsavedays", "14", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 365.0), CvarXPSaveDays);
	bind_pcvar_num(create_cvar("sh_reloadmode", "1"), CvarReloadMode);
	if (cvar_exists("sh_minplayersxp"))
        bind_pcvar_num(get_cvar_pointer("sh_minplayersxp"), CvarMinPlayersXP);
	else
        bind_pcvar_num(create_cvar("sh_minplayersxp", "2"), CvarMinPlayersXP);
	bind_pcvar_num(create_cvar("sh_ffa", "0"), CvarFreeForAll);

	// Server cvars checked by core
	bind_pcvar_num(get_cvar_pointer("mp_friendlyfire"), CvarFriendlyFire);
	sv_maxspeed = get_cvar_pointer("sv_maxspeed");
	bind_pcvar_num(get_cvar_pointer("sv_lan"), CvarLan);


	// API - Register a bunch of forwards that heroes can use
	fwd_HeroInit = CreateMultiForward("sh_hero_init", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL); // id, heroID, mode
	fwd_HeroKey = CreateMultiForward("sh_hero_key", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL); // id, heroID, key
	fwd_Spawn = CreateMultiForward("sh_client_spawn", ET_IGNORE, FP_CELL, FP_CELL); // id, newSpawn
	fwd_Death = CreateMultiForward("sh_client_death", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_STRING); //killer, victim, wpnindex, hitplace, TK
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
	RegisterHamPlayer(Ham_TakeDamage, "ham_TakeDamage_Pre");
	new weaponName[32];
	for (new id = CSW_P228; id <= CSW_P90; id++) {
		if (get_weaponname(id, weaponName, charsmax(weaponName)))
			RegisterHam(Ham_CS_Item_GetMaxSpeed, weaponName, "@Forward_CS_Item_GetMaxSpeed_Pre", 0);
	}

	// Player choosing a team (t, ct, auto, spec)
	register_menucmd(register_menuid("IG_Team_Select", 1), 511, "team_chosen");
	register_menucmd(register_menuid("Team_Select", 1), 511, "team_chosen");
	register_menucmd(register_menuid("Team_Select_Spect", 1), 511, "team_chosen");
	register_clcmd("jointeam", "team_chosen");

	// Client Commands
	register_clcmd("superpowermenu", "cl_superpowermenu", ADMIN_ALL, "superpowermenu");
	register_clcmd("clearpowers", "cl_clearpowers", ADMIN_ALL, "clearpowers");
	register_clcmd("say", "cl_say");
	register_clcmd("fullupdate", "cl_fullupdate");

	// Power Commands, using a loop so it adjusts with SH_MAXBINDPOWERS
	for (new x = 1; x <= SH_MAXBINDPOWERS; x++) {
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
	gmsgScoreInfo = get_user_msgid("ScoreInfo");
	gmsgDeathMsg = get_user_msgid("DeathMsg");
	gmsgDamage = get_user_msgid("Damage");

	// Set the game description
	register_forward(FM_GetGameDescription, "@Forward_GetGameDescription");

	// Block committed suicide hl log messages caused by extradamage
	register_forward(FM_AlertMessage, "fm_AlertMessage");
	register_message(gmsgDeathMsg, "msg_DeathMsg");

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
	register_library(SH_LIBRARY_STR);

	register_native("sh_create_hero", "@Native_CreateHero");
	register_native("sh_set_hero_info", "@Native_SetHeroInfo");
	register_native("sh_set_hero_bind", "@Native_SetHeroBind");
	register_native("sh_set_hero_speed", "@Native_SetHeroSpeed");
	register_native("sh_set_hero_grav", "@Native_SetHeroGravity");
	register_native("sh_set_hero_dmgmult", "@Native_SetHeroDamageMultiplier");
	register_native("sh_get_num_heroes", "@Native_GetNumHeroes");
	register_native("sh_get_num_lvls", "@Native_GetNumLvls");
	register_native("sh_get_lvl_xp", "@Native_GetLvlXP");
	register_native("sh_get_user_hero", "@Native_GetUserHero");
	register_native("sh_get_user_lvl", "@Native_GetUserLvl");
	register_native("sh_set_user_lvl", "@Native_SetUserLvl");
	register_native("sh_get_user_powers", "@Native_GetUserPowers");
	register_native("sh_get_user_xp", "@Native_GetUserXP");
	register_native("sh_set_user_xp", "@Native_SetUserXP");
	register_native("sh_add_kill_xp", "@Native_AddKillXP");
	register_native("sh_get_hero_id", "@Native_GetHeroID");
	register_native("sh_user_has_hero", "@Native_UserHasHero");
	register_native("sh_chat_message", "@Native_ChatMessage");
	register_native("sh_debug_message", "@Native_DebugMessage");
	register_native("sh_extra_damage", "@Native_ExtraDamage");
	register_native("sh_set_stun", "@Native_SetStun");
	register_native("sh_get_stun", "@Native_GetStun");
	register_native("sh_set_godmode", "@Native_SetGodmode");
	register_native("sh_is_freezetime", "@Native_IsFreezeTime");
	register_native("sh_is_inround", "@Native_IsInRound");
	register_native("sh_reload_ammo", "@Native_ReloadAmmo");
	register_native("sh_drop_weapon", "@Native_DropWeapon");
	register_native("sh_give_weapon", "@Native_GiveWeapon");
	register_native("sh_give_item", "@Native_GiveItem");
	register_native("sh_reset_max_speed", "@Native_ResetMaxSpeed");
	register_native("sh_reset_min_gravity", "@Native_ResetMinGravity");
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

	// Check to see if we need to block weapon giving heroes
	giveWeaponConfig();

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
	set_task(5.0, "setSvMaxspeed");

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
// This will set the sh_give_weapon blocks for the map
giveWeaponConfig()
{
	new wpnBlockFile[128];
	formatex(wpnBlockFile, charsmax(wpnBlockFile), "%s/shweapon.cfg", gSHConfigDir);

	if (!file_exists(wpnBlockFile)) {
		//Create the file if it doesn't exist
		createGiveWeaponConfig(wpnBlockFile);
		return;
	}

	new blockWpnFile = fopen(wpnBlockFile, "rt");

	if (!blockWpnFile) {
		debugMsg(0, 0, "Failed to open shweapon.cfg, please verify file/folder permissions");
		return;
	}

	new data[512], mapName[32], blockMapName[32];
	new blockWeapons[512], weapon[16], weaponName[32];
	new checkLength, x, weaponID;

	get_mapname(mapName, charsmax(mapName));

	while (!feof(blockWpnFile)) {
		fgets(blockWpnFile, data, charsmax(data));
		trim(data);

		//Comments or blank skip it
		switch (data[0]) {
			case '^0', '^n', ';', '/', '\', '#': continue;
		}

		argbreak(data, blockMapName, charsmax(blockMapName), blockWeapons, charsmax(blockWeapons));

		//all maps or check for something more specific?
		if (blockMapName[0] != '*') {

			//How much of the map name do we check?
			checkLength = strlen(blockMapName);

			if (blockMapName[checkLength-1] == '*')
				--checkLength;
			else //Largest length between the 2, do this because of above check
				checkLength = max(checkLength, strlen(mapName));

			//Keep checking or did we find the map?
			if (!equali(mapName, blockMapName, checkLength))
				continue;
		}

		//If gotten this far a map has been found
		remove_quotes(blockWeapons);

		//Idiot check, make sure weapon names are lowercase before going further
		strtolower(blockWeapons);

		while (blockWeapons[0] != '^0') {
			//trim any spaces left over especially from strtok
			trim(blockWeapons);
			strtok(blockWeapons, weapon, charsmax(weapon), blockWeapons, 415, ',', 1);

			if (equal(weapon, "all")) {
				//Set all 1-30 CSW_ constants
				for (x = 1; x < 31; x++)
					gMapBlockWeapons[x] = gMapBlockWeapons[x] ? false : true;
			} else {
				//Set named weapon
				formatex(weaponName, charsmax(weaponName), "weapon_%s", weapon);
				weaponID = get_weaponid(weaponName);

				if (!weaponID) {
					debugMsg(0, 0, "Invalid block weapon name ^"%s^" for entry ^"%s^" check shweapon.cfg", weapon, blockMapName);
					continue;
				}

				gMapBlockWeapons[weaponID] = gMapBlockWeapons[weaponID] ? false : true;
			}
		}

		// Map found stop looking for more
		break;
	}
	fclose(blockWpnFile);
}
//----------------------------------------------------------------------------------------------
public loopMain()
{
	//Might be better to create an ent think loop
	if (!CvarSuperHeros)
		return;

	//Unstun Timer & GodMode Timer
	timerAll();

	//Show the CMD Projector
	showHelpHud();
}
//----------------------------------------------------------------------------------------------
public setHeroLevels()
{
	debugMsg(0, 1, "Reloading Levels for %d Heroes", gSuperHeroCount);

	for ( new x = 0; x < gSuperHeroCount && x <= SH_MAXHEROS; x++)
		gSuperHeros[x][availableLevel] = get_pcvar_num(gHeroLevelCVAR[x]);
}
//----------------------------------------------------------------------------------------------
public setSvMaxspeed()
{
	new maxSpeed = 320; // Server Default
	for (new x = 0; x < gSuperHeroCount; x++) {
		if (gHeroMaxSpeed[x] != 0)
			maxSpeed = max(maxSpeed, get_pcvar_num(gHeroMaxSpeed[x]));
	}

	// Only set if below required speed to avoid setting lower then server op may want
	if (get_pcvar_num(sv_maxspeed) < maxSpeed) {
		debugMsg(0, 1, "Setting server CVAR sv_maxspeed to: %d", maxSpeed);
		set_pcvar_num(sv_maxspeed, maxSpeed);
	}
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
//native sh_get_lvl_xp()
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

	if (0 < powerIndex < getPowerCount(id))
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
	// if (gReadXPNextRound[id])
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
	for (new x = 0; x < gSuperHeroCount; x++) {
		if (equali(heroName, gSuperHeros[x][hero]))
			return x;
	}
	return -1;
}
//----------------------------------------------------------------------------------------------
//native sh_user_has_hero(id, heroIndex)
@Native_UserHasHero()
{
	new id = get_param(1);

	//stupid check - but checking prevents crashes
	if (id < 1 || id > MaxClients)
		return 0;

	new heroIndex = get_param(2);

	if (-1 < heroIndex < gSuperHeroCount)
		return playerHasPower(id, heroIndex);

	return 0;
}
//----------------------------------------------------------------------------------------------
bool:playerHasPower(id, heroIndex)
{
	new playerpowercount = getPowerCount(id);
	for (new x = 1; x <= playerpowercount && x <= SH_MAXLEVELS; x++) {
		if (gPlayerPowers[id][x] == heroIndex)
			return true;
	}
	return false;
}
//----------------------------------------------------------------------------------------------
//native sh_drop_weapon(id, weaponID, bool:remove = false)
@Native_DropWeapon()
{
	new id = get_param(1);
	new weaponID = get_param(2);
	
	dropWeapon(id, weaponID, get_param(3) ? true : false);
}
//---------------------------------------------------------------------------------------------
dropWeapon(id, weaponID, bool:remove)
{
	if (!CvarSuperHeros)
		return;

	if (!is_user_alive(id))
		return;

	// If VIPs are not allowed other weapons, protect them from losing what they have
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_WEAPONS)
		return;

	if (!user_has_weapon(id, weaponID))
		return;

	new slot = sh_get_weapon_slot(weaponID);
	if (slot == 1 || slot == 2 || slot == 5) {
		//Don't drop/remove the main c4
		if (weaponID == CSW_C4 && pev_valid(sh_get_c4_id()) && id == pev(sh_get_c4_id(), pev_owner))
			return;

		static weaponName[32];
		get_weaponname(weaponID, weaponName, charsmax(weaponName));

		engclient_cmd(id, "drop", weaponName);

		if (!remove)
			return;

		new Float:weaponVel[3];
		new weaponBox = -1;

		while ((weaponBox = cs_find_ent_by_owner(weaponBox, "weaponbox", id)) > 0) {
			// Skip anything not owned by this client
			if (pev_valid(weaponBox))
				continue;

			// If Velocities are all zero its on the ground already and should stay there
			pev(weaponBox, pev_velocity, weaponVel);
			if (weaponVel[0] == 0.0 && weaponVel[1] == 0.0 && weaponVel[2] == 0.0)
				continue;

			// Forcing a think cleanly removes weaponbox and it's contents
			dllfunc(DLLFunc_Think, weaponBox);
		}
	}
}
//---------------------------------------------------------------------------------------------
//native sh_give_weapon(id, weaponID, bool:switchTo = false)
@Native_GiveWeapon()
{
	new id = get_param(1);
	new weaponID = get_param(2);

	return giveWeapon(id, weaponID, get_param(3) ? true : false);
}
//---------------------------------------------------------------------------------------------
giveWeapon(id, weaponID, bool:switchTo)
{
	if (!CvarSuperHeros)
		return 0;

	if (!is_user_alive(id))
		return 0;

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_WEAPONS)
		return 0;

	if (weaponID < CSW_P228 || weaponID > CSW_P90)
		return 0;

	if (gMapBlockWeapons[weaponID])
		return 0;

	if (!user_has_weapon(id, weaponID)) {
		static weaponName[32];
		get_weaponname(weaponID, weaponName, charsmax(weaponName));

		new itemID = give_item(id, weaponName);

		// Switch to the given weapon?
		if (switchTo)
			engclient_cmd(id, weaponName);

		return itemID;
	}

	return 0;
}
//---------------------------------------------------------------------------------------------
//native sh_give_item(id, const itemName[], bool:switchTo = false)
@Native_GiveItem()
{
	if (!CvarSuperHeros)
		return 0;

	new id = get_param(1);

	if (!is_user_alive(id))
		return 0;

	new itemName[32], itemID;
	get_array(2, itemName, charsmax(itemName));

	if (equal(itemName, "weapon", 6)) {
		if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_WEAPONS)
			return 0;

		new weaponID = get_weaponid(itemName);
		if (weaponID) {
			//It's a weapon see if it is blocked or user already has it
			if (gMapBlockWeapons[weaponID] || user_has_weapon(id, weaponID))
				return 0;
		}

		itemID = give_item(id, itemName);

		if (get_param(3))
			engclient_cmd(id, itemName);
	} else {
		itemID = give_item(id, itemName);
	}

	return itemID;
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
	gHeroLevelCVAR[idx] = pcvarMinLevel;
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

	// Reset Hero hp/ap/speed/grav if needed
	if (mode == SH_HERO_DROP && is_user_alive(id)) {
		//reset all values
		if (gHeroMaxSpeed[heroIndex] != 0)
			setSpeedPowers(id, true);

		if (gHeroMinGravity[heroIndex] != 0)
			resetMinGravity(id);
	}

	//Init the hero
	ExecuteForward(fwd_HeroInit, fwdReturn, id, heroIndex, mode);

	gChangedHeroes[id] = true;
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_speed(heroID, pcvarSpeed, const weapons[] = {0}, numofwpns = 1)
@Native_SetHeroSpeed()
{
	new heroIndex = get_param(1);

	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return;

	new pcvarSpeed = get_param(2);
	new numWpns = get_param(4);

	new pWeapons[31];
	get_array(3, pWeapons, numWpns);

	//Avoid running this unless debug is high enough
	if (CvarDebugMessages > 2) {
		//Set up the weapon string for the debug message
		new weapons[32], number[3], x;
		for (x = 0; x < numWpns; x++) {
			formatex(number, charsmax(number), "%d", pWeapons[x]);
			add(weapons, charsmax(weapons), number);
			if (pWeapons[x+1] != '^0')
				add(weapons, charsmax(weapons), ",");
			else
				break;
		}

		debugMsg(0, 3, "Set Max Speed -> HeroID: %d - Speed: %d - Weapon(s): %s", heroIndex, get_pcvar_num(pcvarSpeed), weapons);
	}

	gHeroMaxSpeed[heroIndex] = pcvarSpeed; // pCVAR expected!
	copy(gHeroSpeedWeapons[heroIndex], charsmax(gHeroSpeedWeapons[]), pWeapons); // Array expected!
}
//----------------------------------------------------------------------------------------------
//native sh_set_hero_grav(heroID, pcvarGravity, const weapons[] = {0}, numofwpns = 1)
@Native_SetHeroGravity()
{
	new heroIndex = get_param(1);

	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return;

	new pcvarGravity = get_param(2);
	new numWpns = get_param(4);

	new pWeapons[40];
	get_array(3, pWeapons, numWpns);

	//Avoid running this unless debug is high enough
	if (CvarDebugMessages > 2) {
		//Set up the weapon string for the debug message
		new weapons[32], number[3], x;
		for (x = 0; x < numWpns; x++) {
			formatex(number, charsmax(number), "%d", pWeapons[x]);
			add(weapons, charsmax(weapons), number);
			if (pWeapons[x+1] != '^0')
				add(weapons, charsmax(weapons), ",");
			else
				break;
		}

		debugMsg(0, 3, "Set Min Gravity -> HeroID: %d - Gravity: %.3f - Weapon(s): %s", heroIndex, get_pcvar_float(pcvarGravity), weapons);
	}

	gHeroMinGravity[heroIndex] = pcvarGravity; // pCVAR expected!
	//copy(gHeroGravityWeapons[heroIndex], charsmax(gHeroGravityWeapons[]), pWeapons) // Array expected!
}
//----------------------------------------------------------------------------------------------
Float:getMaxSpeed(id, weapon)
{
	static Float:returnSpeed, Float:heroSpeed, x, i;
	static playerPowerCount, heroIndex, heroWeapon, heroSpeedPointer;
	returnSpeed = -1.0;
	playerPowerCount = getPowerCount(id);

	for (x = 1; x <= playerPowerCount; x++) {
		heroIndex = gPlayerPowers[id][x];
		
		if (-1 < heroIndex < gSuperHeroCount) {
			heroSpeedPointer = gHeroMaxSpeed[heroIndex];
			if (!heroSpeedPointer)
				continue;
			
			heroSpeed = get_pcvar_float(heroSpeedPointer);
			if (heroSpeed > 0.0) {
				for (i = 0; i < 31; i++) {
					heroWeapon = gHeroSpeedWeapons[heroIndex][i];

					//Stop checking, end of list
					if (i != 0 && heroWeapon == 0)
						break;

					debugMsg(id, 5, "Looking for Speed Functions - %s, %d, %d", gSuperHeros[heroIndex][hero], heroWeapon, weapon);

					//if 0 or current weapon check max
					if (heroWeapon == 0 || heroWeapon == weapon) {
						returnSpeed = floatmax(returnSpeed, heroSpeed);
						break;
					}
				}
			}
		}
	}

	return returnSpeed;
}
//----------------------------------------------------------------------------------------------
Float:getMinGravity(id)
{
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_GRAVITY)
		return 1.0;

	static Float:returnGravity, Float:heroMinGravity;
	static x, heroIndex, playerPowerCount, heroGravityPointer;
	returnGravity = 1.0;
	playerPowerCount = getPowerCount(id);

	for (x = 1; x <= playerPowerCount; x++) {
		heroIndex = gPlayerPowers[id][x];
		if (-1 < heroIndex < gSuperHeroCount) {
			heroGravityPointer = gHeroMinGravity[heroIndex];
			if (!heroGravityPointer)
				continue;
			
			heroMinGravity = get_pcvar_float(heroGravityPointer);
			if (heroMinGravity > 0.0)
				returnGravity = floatmin(returnGravity, heroMinGravity);
		}
	}

	return returnGravity;
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
	for (new x = 1; x <= CvarMaxBinds; x++) {
		if (gPlayerBinds[id][x] == heroIndex)
			return x;
	}
	return 0;
}
//----------------------------------------------------------------------------------------------
menuSuperPowers(id, menuOffset)
{
	// Don't show menu if mod off or they're not connected
	if (!CvarSuperHeros || !is_user_connected(id) || gReadXPNextRound[id])
		return PLUGIN_HANDLED;

	gInMenu[id] = false;
	gPlayerMenuOffset[id] = 0;

	new bool:isBot = is_user_bot(id) ? true : false;

	if (gIsPowerBanned[id]) {
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

	for (new x = 0; x <= gNumLevels; x++) {
		if (playerLevel >= x)
			gMaxPowersLeft[id][x] = playerLevel - x + LvlLimit;
		else
			gMaxPowersLeft[id][x] = 0;
	}

	// Now decrement the level powers that they've picked
	new heroIndex, heroLevel;

	for (new x = 1; x <= playerPowerCount && x <= SH_MAXLEVELS; x++) {
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

	for (new x = 0; x < gSuperHeroCount; x++) {
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
					enabled++;
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
	for (new x = menuOffset; x < menuOffset + 8; x++) {
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

	if ((count > 0 && enabled > 0) || gInMenu[id]) {
		debugMsg(id, 8, "Displaying Menu - offset: %d - count: %d - enabled: %d", menuOffset, count, enabled);
		gInMenu[id] = true;
		show_menu(id, keys, message);
	}

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
public selectedSuperPower(id, key)
{
	if (!gInMenu[id] || !CvarSuperHeros)
		return PLUGIN_HANDLED;

	gInMenu[id] = false;

	if (gIsPowerBanned[id]) {
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
	for (new x = level; x <= playerPowerCount && x <= SH_MAXLEVELS; x++) {
		if (x != SH_MAXLEVELS)
			gPlayerPowers[id][x] = gPlayerPowers[id][x + 1];
	}

	new powers = gPlayerPowers[id][0]--;
	if (powers < 0)
		gPlayerPowers[id][0] = 0;

	//Clear out powers higher than powercount
	for (new x = powers + 1; x <= gNumLevels && x <= SH_MAXLEVELS; x++)
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
	for (new x = 1; x <= gNumLevels && x <= SH_MAXLEVELS; x++) {
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
		gReadXPNextRound[id] = false;

	//Cancel the ultimate timer task on any new spawn
	//It is up to the hero to set the variable back to false
	remove_task(id + SH_COOLDOWN_TASKID, 1); // 1 = look outside this plugin

	//Sets the stun and god timers back to normal
	gPlayerStunTimer[id] = -1;
	gPlayerGodTimer[id] = -1;
	set_user_godmode(id, 0);

	//These must be checked here to set the max variables correctly
	sh_update_max_hp(id);
	sh_update_max_ap(id);

	//Prevents this whole function from being called if its not a new round
	if (!gNewRoundSpawn[id]) {
		displayPowers(id, true);

		//Let heroes know someone just spawned mid-round
		ExecuteForward(fwd_Spawn, fwdReturn, id, 0);

		return HAM_IGNORED;
	}

	if (!gBetweenRounds)
		setSpeedPowers(id, false);

	// Read the XP!
	if (gFirstRound[id])
		gFirstRound[id] = false;
	else if (gReadXPNextRound[id])
		readXP(id);

	//MercyXP system
	if (gGiveMercyXP && !gReadXPNextRound[id] && !gBlockMercyXp[id]) {
		new mercyXPMode = CvarMercyXPMode;

		if (mercyXPMode != 0 && gPlayerStartXP[id] >= gPlayerXP[id] && get_playersnum() > CvarMinPlayersXP) {
			new XPtoGive = 0;
			new mercyXP = get_pcvar_num(sh_mercyxp);

			if (mercyXPMode == 1) {
				XPtoGive = mercyXP;
			} else if (mercyXPMode == 2 && gPlayerLevel[id] <= mercyXP) {
				new giveLvl = mercyXP - gPlayerLevel[id];
				XPtoGive = gXPGiven[giveLvl] / 2;
			}

			if (XPtoGive != 0) {
				localAddXP(id, XPtoGive);
				chatMessage(id, _, "You were given %d MercyXP points", XPtoGive);
			}
		}
		gPlayerStartXP[id] = gPlayerXP[id];
	}

	//Display the XP and bind powers to their screen
	displayPowers(id, true);

	//Shows menu if the person is not in it already, always show for bots to choose powers
	if (!gInMenu[id] && (is_user_bot(id) || !(gPlayerFlags[id] & SH_FLAG_NOAUTOMENU)))
		menuSuperPowers(id, gPlayerMenuOffset[id]);

	//Prevents resetHUD from getting called twice in a round
	gNewRoundSpawn[id] = false;

	//Reset this check for the mercyxp system
	gBlockMercyXp[id] = false;

	//Prevents People from going invisible randomly
	set_user_rendering(id);

	//Makes armor system more reliable, also forces armor to reset if survived round
	//Note: might need to call this after forward is sent
	if (sh_update_max_ap(id) != 0 && !(id == sh_get_vip_id() && (sh_vip_flags() & VIP_BLOCK_ARMOR)))
		cs_set_user_armor(id, 0, CS_ARMOR_NONE);

	//Let heroes know someone just spawned from a new round
	ExecuteForward(fwd_Spawn, fwdReturn, id, 1);

	return HAM_IGNORED;
}
//----------------------------------------------------------------------------------------------
//New Round
public event_HLTV()
{
	gRoundFreeze = true;
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
	ExecuteForward(fwd_NewRound, fwdReturn);
}
//----------------------------------------------------------------------------------------------
public round_Start()
{
	if (!CvarSuperHeros)
		return;

	gRoundFreeze = false;
	gBetweenRounds = false;

	set_task(0.1, "roundStartDelay");
}
//----------------------------------------------------------------------------------------------
public roundStartDelay()
{
	for (new x = 1; x <= MaxClients; x++) {
		displayPowers(x, true);
		//Prevents People from going invisible randomly
		if (is_user_alive(x))
			set_user_rendering(x);
	}

	gRoundStarted = true;

	//Lets let all the heroes know
	ExecuteForward(fwd_RoundStart, fwdReturn);
}
//----------------------------------------------------------------------------------------------
public round_Restart()
{
	// Round end is not called when round is set to restart, so lets just force it right away.
	round_End();
	gGiveMercyXP = false;
}
//----------------------------------------------------------------------------------------------
public round_End()
{
	gBetweenRounds = true;

	gGiveMercyXP = false;

	new CsTeams:idTeam;

	for (new id = 1; id <= MaxClients; id++) {
		gNewRoundSpawn[id] = true;

		if (!is_user_connected(id))
			continue;

		idTeam = cs_get_user_team(id);

		if (idTeam == CS_TEAM_UNASSIGNED)
			continue;

		gFirstRound[id] = false;

		// Player must be on a team beyond this point
		// Find if anyone needs mercy xp to avoid the more expenisve check during spawn
		if (idTeam == CS_TEAM_SPECTATOR)
			continue;

		if (!gBlockMercyXp[id])
			gGiveMercyXP = true;
	}

	//Save XP Data
	if (CvarEndRoundSave)
		set_task(2.0, "memoryTableWrite");

	//Lets let all the heroes know
	ExecuteForward(fwd_RoundEnd, fwdReturn);
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
	//new Float:gametime = get_gametime()
	//if ( gametime - gLastKeydown[id] < 0.2 ) return PLUGIN_HANDLED
	//gLastKeydown[id] = gametime

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
	if (gPlayerStunTimer[id] > 0) {
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
	if (gInPowerDown[id][whichKey])
		return PLUGIN_HANDLED;
	gInPowerDown[id][whichKey] = true;

	if (playerHasPower(id, heroIndex))
		ExecuteForward(fwd_HeroKey, fwdReturn, id, heroIndex, SH_KEYDOWN);

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
	if (gPlayerStunTimer[id] > 0 && !gInPowerDown[id][whichKey])
		return PLUGIN_HANDLED;

	//Set this key as NOT in use anymore
	gInPowerDown[id][whichKey] = false;

	debugMsg(id, 5, "power%d Released", whichKey);

	// Make sure there is a power bound to this key!
	if (whichKey > gPlayerBinds[id][0])
		return PLUGIN_HANDLED;

	new heroIndex = gPlayerBinds[id][whichKey];
	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return PLUGIN_HANDLED;

	if (playerHasPower(id, heroIndex))
		ExecuteForward(fwd_HeroKey, fwdReturn, id, heroIndex, SH_KEYUP);

	return PLUGIN_HANDLED;
}
//----------------------------------------------------------------------------------------------
@Forward_CS_Item_GetMaxSpeed_Pre(weapon, Float:newSpeed)
{
	if (!CvarSuperHeros)
		return HAM_IGNORED;

	static owner;
	owner = pev(weapon, pev_owner);

	if (!is_user_alive(owner) || gRoundFreeze || gReadXPNextRound[owner])
		return HAM_IGNORED;

	if (gPlayerStunTimer[owner] > 0) {
		static Float:stunSpeed;
		stunSpeed = gPlayerStunSpeed[owner];

		SetHamReturnFloat(stunSpeed);
		debugMsg(owner, 5, "Setting Stun Speed To %f", stunSpeed);
		return HAM_SUPERCEDE;
	}

	if (owner == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_SPEED)
		return HAM_IGNORED;

	if (cs_get_user_zoom(owner) != CS_SET_NO_ZOOM)
		return HAM_IGNORED;

	static Float:heroSpeed;
	heroSpeed = getMaxSpeed(owner, cs_get_weapon_id(weapon));

	debugMsg(owner, 10, "Checking Speeds - New: %f - Hero: %f", newSpeed, heroSpeed);

	if (heroSpeed == newSpeed || heroSpeed == -1.0)
		return HAM_IGNORED;

	SetHamReturnFloat(heroSpeed);
	debugMsg(owner, 5, "Setting Speed To %f", heroSpeed);
	return HAM_SUPERCEDE;
}
//----------------------------------------------------------------------------------------------
public setPowers(id)
{
	if (!is_user_alive(id))
		return;

	setSpeedPowers(id, false);
	setArmorPowers(id);
	setGravityPowers(id);
	setHealthPowers(id);
}
//----------------------------------------------------------------------------------------------
//native sh_reset_max_speed(id)
@Native_ResetMaxSpeed()
{
	if (!CvarSuperHeros)
		return;

	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	setSpeedPowers(id, true);
}
//----------------------------------------------------------------------------------------------
setSpeedPowers(id, bool:checkDefault)
{
	if (!CvarSuperHeros)
		return;

	if (!is_user_alive(id) || gRoundFreeze || gReadXPNextRound[id])
		return;

	if (gPlayerStunTimer[id] > 0) {
		new Float:stunSpeed = gPlayerStunSpeed[id];
		set_user_maxspeed(id, stunSpeed);

		debugMsg(id, 5, "Setting Stun Speed To %f", stunSpeed);
		return;
	}

	new weapon = cs_get_user_weapon(id);
	new Float:oldSpeed = get_user_maxspeed(id);
	new Float:newSpeed;

	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_SPEED) {
		newSpeed = 227.0;
	} else if (cs_get_user_zoom(id) != CS_SET_NO_ZOOM) {
		switch (weapon) {
			// If weapon is a zoomed sniper rifle set default speeds
			case CSW_SCOUT, CSW_SG550, CSW_AWP, CSW_G3SG1: newSpeed = sh_get_weapon_speed(weapon, true);
		}
	} else {
		newSpeed = getMaxSpeed(id, weapon);
	}

	debugMsg(id, 10, "Checking Speeds - Old: %f - New: %f", oldSpeed, newSpeed);

	// OK SET THE SPEED
	if (newSpeed != oldSpeed) {
		switch (newSpeed) {
			case -1.0: {
				if (checkDefault) {
					if (id == sh_get_vip_id())
						//Still need to check this because vip speed may not be blocked
						//and user may not have a hero with current weapon speed 
						set_user_maxspeed(id, 227.0);
					else
						// Set default weapon speed
						// Do not need to check for scoped sniper rifles as getMaxSpeed will
						// return that value since heroes can not effect scoped sniper rifles.
						set_user_maxspeed(id, sh_get_weapon_speed(weapon));
				}
			}
			default: {
				set_user_maxspeed(id, newSpeed);
				debugMsg(id, 5, "Setting Speed To %f", newSpeed);
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
setHealthPowers(id)
{
	if (!CvarSuperHeros)
		return;
	
	if (!is_user_alive(id) || gReadXPNextRound[id])
		return;

	new oldHealth = get_user_health(id);
	new newHealth = sh_update_max_hp(id);

	// Can't get health in the middle of a round UNLESS you didn't get shot...
	if (oldHealth < newHealth && oldHealth >= 100) {
		debugMsg(id, 5, "Setting Health to %d", newHealth);
		set_user_health(id, newHealth);
	}
}
//----------------------------------------------------------------------------------------------
setArmorPowers(id)
{
	if (!CvarSuperHeros)
		return;

	if (!is_user_alive(id) || gReadXPNextRound[id])
		return;

	new CsArmorType:armorType;
	new oldArmor = cs_get_user_armor(id, armorType);
	new newArmor = sh_update_max_ap(id);

	// Little check for armor system
	if (oldArmor != 0 || oldArmor >= newArmor)
		return;

	// Set the armor to the correct value
	cs_set_user_armor(id, newArmor, CS_ARMOR_VESTHELM);

	debugMsg(id, 5, "Setting Armor to %d", newArmor);
}
//----------------------------------------------------------------------------------------------
//native sh_reset_min_gravity(id)
@Native_ResetMinGravity()
{
	if (!CvarSuperHeros)
		return;

	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	resetMinGravity(id);
}
//----------------------------------------------------------------------------------------------
resetMinGravity(id)
{
	if (!CvarSuperHeros)
		return;

	if (!is_user_alive(id))
		return;

	new Float:newGravity = getMinGravity(id);
	if (get_user_gravity(id) != newGravity)
		// Set to 1.0 or the next lowest Gravity
		set_user_gravity(id, newGravity);
}
//----------------------------------------------------------------------------------------------
setGravityPowers(id)
{
	if (!CvarSuperHeros)
		return;

	if (!is_user_alive(id) || gRoundFreeze || gReadXPNextRound[id])
		return;

	new Float:oldGravity = 1.0;
	new Float:newGravity = getMinGravity(id);

	if (oldGravity != newGravity) {
		debugMsg(id, 5, "Setting Gravity to %f", newGravity);
		set_user_gravity(id, newGravity);
	}
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
	if (gIsPowerBanned[id]) {
		clearAllPowers(id, false); // Avoids Recursion with false
		writeStatusMessage(id, "[SH] You are banned from using powers");
		return;
	} else if (gReadXPNextRound[id]) {
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
	for (new x = 1; x <= maxBinds; x++)
		gPlayerBinds[id][x] = -1;

	playerPowerCount = getPowerCount(id);

	for (new x = 1; x <= gNumLevels && x <= playerPowerCount; x++) {
		heroIndex = gPlayerPowers[id][x];
		if (-1 < heroIndex < gSuperHeroCount) {
			// 2 types of heroes - auto heroes and bound heroes...
			// Bound Heroes require special work...
			if (gSuperHeros[heroIndex][requiresKeys]) {
				count++;
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

	if (is_user_alive(id)) {
		writeStatusMessage(id, message);

		if (setThePowers)
			set_task(0.6, "setPowers", id);
	}

	// Update menu incase already in menu and levels changed
	// or user is no longer in menu
	get_user_menu(id, menuid, mkeys);
	if (menuid != gMenuID)
		gInMenu[id] = false;
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
//----------------------------------------------------------------------------------------------
//native sh_set_hero_dmgmult(heroID, pcvarDamage, const weaponID = 0)
@Native_SetHeroDamageMultiplier()
{
	new heroIndex = get_param(1);

	if (heroIndex < 0 || heroIndex >= gSuperHeroCount)
		return;

	new pcvarDamageMult = get_param(2);
	new weaponID = get_param(3);

	debugMsg(0, 3, "Set Damage Multiplier -> HeroID: %d - Multiplier: %d - Weapon: %d", heroIndex, get_pcvar_num(pcvarDamageMult), weaponID);

	gHeroMaxDamageMult[heroIndex][weaponID] = pcvarDamageMult; // pCVAR expected!
}
//----------------------------------------------------------------------------------------------
Float:getMaxDamageMult(id, weaponID)
{
	if (id == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_EXTRADMG)
		return 1.0;

	static Float:returnDmgMult, x;
	static playerPowerCount, heroIndex, heroDmgMultPointer;
	returnDmgMult = 1.0;
	playerPowerCount = getPowerCount(id);

	for (x = 1; x <= playerPowerCount; x++) {
		heroIndex = gPlayerPowers[id][x];
		if (-1 < heroIndex < gSuperHeroCount) {
			// Check hero for All weapons wildcard first
			heroDmgMultPointer = gHeroMaxDamageMult[heroIndex][0];
			if (!heroDmgMultPointer) {
				// Check hero for weapon that was passed in
				heroDmgMultPointer = gHeroMaxDamageMult[heroIndex][weaponID];

				if (!heroDmgMultPointer)
					continue;
			}

			returnDmgMult = floatmax(returnDmgMult, get_pcvar_float(heroDmgMultPointer));
		}
	}

	return returnDmgMult;
}
//----------------------------------------------------------------------------------------------
public ham_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (damage <= 0.0)
		return HAM_IGNORED;

	if (!is_user_connected(attacker) || !is_user_alive(victim))
		return HAM_IGNORED;

	// if (victim != attacker && cs_get_user_team(victim) == cs_get_user_team(attacker) && !CvarFreeForAll)
		// return HAM_IGNORED;

	if (attacker == sh_get_vip_id() && sh_vip_flags() & VIP_BLOCK_EXTRADMG)
		return HAM_IGNORED;

	new weaponID;
	if (damagebits & DMG_GRENADE)
		weaponID = CSW_HEGRENADE;
	else if (damagebits & DMG_BULLET && inflictor == attacker)
		//includes knife and any other weapon
		weaponID = get_user_weapon(attacker);

	//Damage not from a CS weapon
	if (!weaponID)
		return HAM_IGNORED;

	new Float:dmgmult = getMaxDamageMult(attacker, weaponID);

	//Damage is not increased damage
	if (dmgmult <= 1.0)
		return HAM_IGNORED;

	SetHamParamFloat(4, (damage * dmgmult));

	return HAM_HANDLED;
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

	new damage = get_param(3);

	new mode = get_param(6);

	new health = get_user_health(victim);
	new CsArmorType:armorType;
	new plrArmor = cs_get_user_armor(victim, armorType);

	if (mode == SH_DMG_KILL) {
		damage = health;
	} else {
		if (damage <= 0)
			return;

		// *** Damage calculation due to armor from: multiplayer/dlls/player.cpp ***
		// *** Note: this is not exactly CS damage method because we do not have that sdk ***
		new Float:flDamage = float(damage);
		new Float:flNewDamage = flDamage * SH_ARMOR_RATIO;
		new Float:flArmor = (flDamage - flNewDamage) * SH_ARMOR_BONUS;

		// Does this use more armor than we have figured for?
		if (flArmor > float(plrArmor)) {
			flArmor = float(plrArmor) * (1 / SH_ARMOR_BONUS);
			flNewDamage = flDamage - flArmor;
			plrArmor = 0;
		} else {
			plrArmor = floatround(plrArmor - flArmor);
		}

		if (mode == SH_DMG_NORM)
			damage = floatround(flNewDamage);
		// *** End of damage-armor calculations ***
	}

	new newHealth = health - damage;
	new friendlyFire = CvarFriendlyFire;
	new freeForAll = CvarFreeForAll;
	new CsTeams:victimTeam = cs_get_user_team(victim);
	new CsTeams:attackerTeam = cs_get_user_team(attacker);

	if (newHealth < 1) {
		new bool:kill;
		new headshot = get_param(5);
		new attackerFrags = get_user_frags(attacker);
		new attackerMoney = cs_get_user_money(attacker);

		if (victim == attacker) {
			kill = true;
		} else if (victimTeam != attackerTeam || (friendlyFire && freeForAll)) {
			kill = true;

			if (headshot)
				localAddXP(attacker, floatround(gXPGiven[gPlayerLevel[victim]] * CvarHSMult));
			else
				localAddXP(attacker, gXPGiven[gPlayerLevel[victim]]);

			set_user_frags(attacker, ++attackerFrags);

			// Frag gives $300, make sure not to go over max
			if (attackerMoney < 16000) {
				new money = min((attackerMoney + 300), 16000);
				cs_set_user_money(attacker, money, 1);
			}
		} else if (friendlyFire) {
			kill = true;

			localAddXP(attacker, -gXPGiven[gPlayerLevel[attacker]]);

			gBlockMercyXp[attacker] = true;

			set_user_frags(attacker, --attackerFrags);

			client_print(attacker, print_center, "You killed a teammate");

			// Teamkill removes $3300, make sure not to go under min
			if (attackerMoney > 0) {
				new money = max((attackerMoney - 3300), 0);
				cs_set_user_money(attacker, money, 1);
			}
		}

		if (!kill)
			return;

		new wpnDescription[32];
		get_string(4, wpnDescription, charsmax(wpnDescription));

		// Kill the victim and block the message
		set_msg_block(gmsgScoreInfo, BLOCK_ONCE);

		gXrtaDmgClientKill = true;
		// Save info to change HUD death message and send forward with correct info
		copy(gXrtaDmgWpnName, charsmax(gXrtaDmgWpnName), wpnDescription);
		gXrtaDmgAttacker = attacker;
		gXrtaDmgHeadshot = headshot;
		// Kill the victim
		// pev_dmg_inflictor not set becase this will be self even if we did set it
		dllfunc(DLLFunc_ClientKill, victim);
		gXrtaDmgClientKill = false;

		// Log the Kill
		logKill(attacker, victim, wpnDescription);

		// Make camera turn toward attacker on death, thx Emp`
		set_pev(victim, pev_iuser3, attacker);

		// ClientKill removes a frag, give it back if not self inflicted
		new victimFrags = get_user_frags(victim);
		if (victim != attacker) {
			set_user_frags(victim, ++victimFrags);

			// Update attacker's statustext since his xp changed
			displayPowers(attacker, false);

			// Update victims scoreboard with correct info
			message_begin(MSG_ALL, gmsgScoreInfo);
			write_byte(victim);
			write_short(victimFrags);
			write_short(cs_get_user_deaths(victim));
			write_short(0);
			write_short(_:victimTeam);
			message_end();
		}

		// Update killers scoreboard with new info
		message_begin(MSG_ALL, gmsgScoreInfo);
		write_byte(attacker);
		write_short(attackerFrags);
		write_short(cs_get_user_deaths(attacker));
		write_short(0);
		write_short(_:attackerTeam);
		message_end();
	} else {
		new bool:hurt = false;
		if (victimTeam != attackerTeam || victim == attacker || (friendlyFire && freeForAll)) {
			hurt = true;
		} else if (friendlyFire) {
			hurt = true;
			//new bool:dmgFFmsg = get_param(6) ? true : false;
			if (get_param(8)) {
				new name[32];
				get_user_name(attacker, name, charsmax(name));
				client_print(0, print_chat, "%s attacked a teammate", name);
			}
		}

		if (!hurt)
			return;

		// External plugins might use this
		// This should be set to the entity that caused the
		// damage, but lets just set it to attacker for now
		set_pev(victim, pev_dmg_inflictor, attacker);

		set_user_health(victim, newHealth);

		cs_set_user_armor(victim, plrArmor, armorType);

		// Slow down from damage, does not effect z vector
		// new bool:dmgStun = get_param(7) ? true : false
		if (get_param(7) && pev(victim, pev_movetype) & MOVETYPE_WALK) {
			// Fake a slowdown from damage
			// Method needs improvement can not find how cs does it
			// possibly use a sh_get_velocity type of method adding to current velocity
			new Float:velocity[3];
			pev(victim, pev_velocity, velocity);
			velocity[0] = 0.0;
			velocity[1] = 0.0;
			// Keep [2] the same as current velocity
			set_pev(victim, pev_velocity, velocity);
		}

		if (is_user_bot(victim))
			return;

		new Float:dmgOrigin[3];
		get_array_f(9, dmgOrigin, 3);

		if (dmgOrigin[0] == 0.0 && dmgOrigin[1] == 0.0 && dmgOrigin[2] == 0.0)
			// Damage origin is attacker
			pev(attacker, pev_origin, dmgOrigin);

		// Damage message for showing damage bits only
		message_begin(MSG_ONE_UNRELIABLE, gmsgDamage, _, victim);
		write_byte(0); // dmg_save
		write_byte(damage); // dmg_take
		write_long(DMG_GENERIC); // visibleDamageBits
		write_coord_f(dmgOrigin[0]); // damageOrigin.x
		write_coord_f(dmgOrigin[1]); // damageOrigin.y
		write_coord_f(dmgOrigin[2]); // damageOrigin.z
		message_end();
	}
}
//---------------------------------------------------------------------------------------------
public fm_AlertMessage(atype, const msg[])
{
	// Keeps hl logs clean of commited suicide with world, caused by sh_extra_damage
	return gXrtaDmgClientKill ? FMRES_SUPERCEDE : FMRES_IGNORED;
}
//---------------------------------------------------------------------------------------------
logKill(id, victim, const weaponDescription[32])
{
	new namea[32], namev[32], authida[32], authidv[32], teama[16], teamv[16];

	// Info On Attacker
	get_user_name(id, namea, charsmax(namea));
	get_user_team(id, teama, charsmax(teama));
	get_user_authid(id, authida, charsmax(authida));
	new auserid = get_user_userid(id);

	// Info On Victim
	get_user_name(victim, namev, charsmax(namev));
	get_user_team(victim, teamv, charsmax(teamv));
	get_user_authid(victim, authidv, charsmax(authidv));

	// Log This Kill
	if (id != victim)
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", namea, auserid, authida, teama, namev, get_user_userid(victim), authidv, teamv, weaponDescription);
	else
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"", namea, auserid, authida, teama, weaponDescription);
}
//----------------------------------------------------------------------------------------------
public msg_DeathMsg()
{
	// Send out the sh death forwards and change the hud death message for sh_extra_damage kill
	// Run this even with sh off so forward can still run and clean up what it needs to
	new attacker, headshot;
	static wpnDescription[32];

	if (!gXrtaDmgClientKill) {
		attacker = get_msg_arg_int(1);
		headshot = get_msg_arg_int(3);
		get_msg_arg_string(4, wpnDescription, charsmax(wpnDescription));
	} else {
		attacker = gXrtaDmgAttacker;
		headshot = gXrtaDmgHeadshot;
		copy(wpnDescription, charsmax(wpnDescription), gXrtaDmgWpnName);

		// Change HUD death message to show extradamage kill correctly
		set_msg_arg_int(1, ARG_BYTE, attacker);
		set_msg_arg_int(3, ARG_BYTE, headshot);
		set_msg_arg_string(4, wpnDescription);
	}

	// Send the sh_client_death forward
	ExecuteForward(fwd_Death, fwdReturn, get_msg_arg_int(2), attacker, headshot, wpnDescription);
}
//---------------------------------------------------------------------------------------------
// Must use death event since csx client_death does not catch worldspawn or suicides
public event_DeathMsg()
{
	if (!CvarSuperHeros)
		return;

	new killer = read_data(1);
	new victim = read_data(2);

	// Kill by extra damage will be skipped here since killer is self
	if (killer && killer != victim && victim) {
		if (cs_get_user_team(killer) == cs_get_user_team(victim) && !CvarFreeForAll) {
			// Killed teammate
			gBlockMercyXp[killer] = true;
			localAddXP(killer, -gXPGiven[gPlayerLevel[killer]]);
		} else {
			//new headshot = read_data(3);
			if (read_data(3))
				localAddXP(killer, floatround(gXPGiven[gPlayerLevel[victim]] * CvarHSMult));
			else
				localAddXP(killer, gXPGiven[gPlayerLevel[victim]]);
		}

		displayPowers(killer, false);
	}

	displayPowers(victim, false);
}
//----------------------------------------------------------------------------------------------
//native sh_reload_ammo(id, mode = 0)
@Native_ReloadAmmo()
{
	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	// re-entrency check
	new Float:gametime = get_gametime();
	if (gametime - gReloadTime[id] < 0.5)
		return;
	gReloadTime[id] = gametime;

	new clip, ammo;
	new wpnid = get_user_weapon(id, clip, ammo);
	new wpnslot = sh_get_weapon_slot(wpnid);

	if (wpnslot != 1 && wpnslot != 2)
		return;

	new mode = get_param(2);

	if (mode == 0) {
		// Server decides what mode to use
		mode = CvarReloadMode;

		if (!mode)
			return;
	}

	switch (mode) {
		// No reload, reset max clip (most common)
		case 1: {
			if (clip != 0)
				return;

			new weaponEnt = -1;
			new wpn[32];
			get_weaponname(wpnid, wpn, charsmax(wpn));

			while ((weaponEnt = engfunc(EngFunc_FindEntityByString, weaponEnt, "classname", wpn)) != 0) {
				if (id == pev(weaponEnt, pev_owner)) {
					cs_set_weapon_ammo(weaponEnt, sh_get_max_clipammo(wpnid));
					break;
				}
			}
		}
		// Requires reload, but reset max backpack ammo
		case 2: {
			new maxbpammo = sh_get_max_bpammo(wpnid);
			if (ammo < maxbpammo)
				cs_set_user_bpammo(id, wpnid, maxbpammo);
		}
		// Drop weapon and get a new one with full clip
		case 3: {
			if (clip != 0)
				return;

			new idSilence, idBurst;
			if (wpnid == CSW_M4A1 || wpnid == CSW_USP) {
				new weaponEnt = -1;
				new wpn[32];
				get_weaponname(wpnid, wpn, charsmax(wpn));

				while ((weaponEnt = engfunc(EngFunc_FindEntityByString, weaponEnt, "classname", wpn)) != 0) {
					if (id == pev(weaponEnt, pev_owner)) {
						idSilence = cs_get_weapon_silen(weaponEnt);
						break;
					}
				}
			} else if (wpnid == CSW_FAMAS || wpnid == CSW_GLOCK18) {
				new weaponEnt = -1;
				new wpn[32];
				get_weaponname(wpnid, wpn, charsmax(wpn));

				while ((weaponEnt = engfunc(EngFunc_FindEntityByString, weaponEnt, "classname", wpn)) != 0) {
					if (id == pev(weaponEnt, pev_owner)) {
						idBurst = cs_get_weapon_burst(weaponEnt);
						break;
					}
				}
			}

			dropWeapon(id, wpnid, true);

			new entityID = giveWeapon(id, wpnid, true);

			if (idSilence)
				cs_set_weapon_silen(entityID, idSilence, 0);
			else if (idBurst)
				cs_set_weapon_burst(entityID, idBurst);
		}
	}
}
//----------------------------------------------------------------------------------------------
timerAll()
{
	static id;
	for (id = 1; id <= MaxClients; id++) {
		if (is_user_alive(id)) {
			// Switches are faster but we don't want to do anything with -1
			switch (gPlayerStunTimer[id]) {
				case -1: { /*Do nothing*/ }
				case 0: {
					gPlayerStunTimer[id] = -1;
					setSpeedPowers(id, true);
				}
				default: {
					gPlayerStunTimer[id]--;
					gPlayerStunSpeed[id] = get_user_maxspeed(id); //is this really needed?
				}
			}

			switch (gPlayerGodTimer[id]) {
				case -1: { /*Do nothing*/ }
				case 0: {
					gPlayerGodTimer[id] = -1;
					set_user_godmode(id, 0);
					sh_set_rendering(id);
				}
				default: {
					gPlayerGodTimer[id]--;
				}
			}
		} else {
			gPlayerStunTimer[id] = -1;
			gPlayerGodTimer[id] = -1;
		}
	}
}
//----------------------------------------------------------------------------------------------
//native sh_set_stun(id, Float:howLong, Float:speed = 0.0)
@Native_SetStun()
{
	if (!CvarSuperHeros)
		return;

	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	new Float:howLong = get_param_f(2);

	if (howLong > gPlayerStunTimer[id]) {
		new Float:speed = get_param_f(3);
		debugMsg(id, 5, "Stunning for %f seconds at %f speed", howLong, speed);
		gPlayerStunTimer[id] = floatround(howLong);
		gPlayerStunSpeed[id] = speed;
		set_user_maxspeed(id, speed);
	}
}
//----------------------------------------------------------------------------------------------
//native sh_get_stun(id)
@Native_GetStun()
{
	if (!CvarSuperHeros)
		return 0;

	new id = get_param(1);

	if (!is_user_alive(id))
		return 0;

	return gPlayerStunTimer[id] > 0 ? 1 : 0;
}
//----------------------------------------------------------------------------------------------
//native sh_set_godmode(id, Float:howLong)
@Native_SetGodmode()
{
	if (!CvarSuperHeros)
		return;

	new id = get_param(1);

	if (!is_user_alive(id))
		return;

	new Float:howLong = get_param_f(2);

	if (howLong > gPlayerGodTimer[id]) {
		debugMsg(id, 5, "Has God Mode for %f seconds", howLong);
		sh_set_rendering(id, 0, 0, 128, 16, kRenderFxGlowShell); // Remove the godmode glow, make heroes set it??
		set_user_godmode(id, 1);
		gPlayerGodTimer[id] = floatround(howLong);
	}
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
		pos++;

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
	for (new x = 1; x <= playerPowerCount && x <= SH_MAXLEVELS; x++) {
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

	for (new x = 0; x < gSuperHeroCount; x++)
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
		for (new x = 0; x < playerCount; x++) {
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
		for (new x = 0; x < playerCount; x++) {
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
			for (idx = 1; idx <= playerPowerCount; idx++) {
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

	for (new i = 0; i < gSuperHeroCount; i++) {
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
		for (new x = 0; x < playerCount; x++) {
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
		new players[32], playerCount;
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

	if (gIsPowerBanned[player]) {
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

	gIsPowerBanned[player] = true;
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

		if (!gIsPowerBanned[player]) {
			console_print(id, "[SH] Client is not SuperHero banned: ^"%s<%d><%s><>^"", name, userid, authid);
			return PLUGIN_HANDLED;
		}

		if (!getSaveKey(player, bankey)) {
			console_print(id, "[SH] Unable to find valid Ban Key to remove from file for client: ^"%s<%d><%s>^"", name, userid, authid);
			return PLUGIN_HANDLED;
		}

		if (!removeBanFromFile(id, bankey))
			return PLUGIN_HANDLED;

		gIsPowerBanned[player] = false;
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

	for (new x = 1; x <= MaxClients; x++) {
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
	for (x = 1; x <= playerPowerCount; x++) {
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
		for (new x = 0; x < gSuperHeroCount; x++) {
			if ((containi(gSuperHeros[x][hero], argx) != -1) || (containi(gSuperHeros[x][help], argx) != -1)) {
				if (n > start && n <= end)
					console_print(id, "%3d: %s (%d%s) - %s", n, gSuperHeros[x][hero], getHeroLevel(x), gSuperHeros[x][requiresKeys] ? "b" : "", gSuperHeros[x][help]);

				n++;
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
		for (new i = start; i < end; i++)
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

	static flags[4];
	switch (CvarCmdProjector) {
		case 1: copy(flags, charsmax(flags), "bch"); // show to dead non-bots only
		case 2: copy(flags, charsmax(flags), "ch"); // show to live or dead non-bots
		default: return; // off 
	}

	set_hudmessage(230, 100, 10, 0.80, 0.28, 0, 1.0, 1.0, 0.9, 0.9, -1);

	static players[MAX_PLAYERS], playerCount, player, i;
	get_players(players, playerCount, flags);

	for (i = 0; i < playerCount; i++) {
		player = players[i];
		if (gPlayerFlags[player] & SH_FLAG_HUDHELP)
			ShowSyncHudMsg(player, gHelpHudSync, "%s", gHelpHudMsg);
	}
}
//----------------------------------------------------------------------------------------------
//Called when a client chooses a "team", not a "class type" (could be used to self kill)
public team_chosen(id)
{
	gBlockMercyXp[id] = true;
}
//----------------------------------------------------------------------------------------------
//Called when a client types "kill" in the console
public client_kill(id)
{
	gBlockMercyXp[id] = true;
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
	gPlayerPutInServer[id] = false;
}
//----------------------------------------------------------------------------------------------
public client_putinserver(id)
{
	if (id < 1 || id > MaxClients)
		return;

	gPlayerPutInServer[id] = true;

	// Don't want to mess up already loaded XP
	if (!gReadXPNextRound[id] && CvarSaveXP)
		return;

	// Load up XP if LongTerm is enabled
	if (CvarSaveXP) {
		// Mid-round loads allowed?
		if (CvarLoadImmediate)
			readXP(id);
		else
			gReadXPNextRound[id] = true;
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

	for (new i = 1; i <= MaxClients; i++) {
		if (is_user_connected(i) && gPlayerXP[i] > 0) {
			count++;
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
	gPlayerStunTimer[id] = -1;
	gPlayerGodTimer[id] = -1;
	setLevel(id, 0);
	gPlayerFlags[id] = SH_FLAG_HUDHELP;
	gFirstRound[id] = true;
	gNewRoundSpawn[id] = true;
	gIsPowerBanned[id] = false;
	gReadXPNextRound[id] = bool:CvarSaveXP;

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

	for (new i = gNumLevels; i >= 0 ; i--) {
		if (gXPLevel[i] <= gPlayerXP[id]) {
			newLevel = i;
			break;
		}
	}

	// Now make sure this level is between the ranges
	new minLevel = clamp(get_pcvar_num(sh_minlevel), 0, gNumLevels);

	if (newLevel < minLevel && !gReadXPNextRound[id]) {
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
		for (new x = 1; x <= gNumLevels && x <= playerPowerCount; x++) {
			heroIndex = gPlayerPowers[id][x];
			if (-1 < heroIndex < gSuperHeroCount) {
				if (getHeroLevel(heroIndex) > gPlayerLevel[id]) {
					clearPower(id, x);
					x--;
				}
			}
		}
	}

	// Uh oh - Rip away a level from powers if they loose a level
	playerPowerCount = getPowerCount(id);
	if (playerPowerCount > newLevel) {
		for (new x = newLevel + 1; x <= playerPowerCount && x <= SH_MAXLEVELS; x++)
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
	if (!gReadXPNextRound[id])
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

	gReadXPNextRound[id] = false;
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
			for (new x = lastchar - 1; x > 0; x--) {
				if (botName[x] == '(') {
					botName[x - 1] = 0;
					break;
				}
				if (!isdigit(botName[x]))
					break;
			}
		}
		if (botName[0] != '^0') {
			replace_all(botName, charsmax(botName), " ", "_");
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
	if (!file_exists(gBanFile) || gIsPowerBanned[id])
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
			gIsPowerBanned[id] = idBanned = true;
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
	
	if (gIsPowerBanned[id] || gReadXPNextRound[id])
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

			for (x = 0; x <= powerCount && x <= SH_MAXLEVELS; x++)
				gMemoryTablePowers[gMemoryTableCount][x] = gMemoryTablePowers[id][x];

			gMemoryTableCount++; // started with position 33
		}
	}

	// OK copy to table now - might have had to write 1 record...
	copy(gMemoryTableKeys[id], charsmax(gMemoryTableKeys[]), savekey);
	get_user_name(id, gMemoryTableNames[id], charsmax(gMemoryTableNames[]));
	gMemoryTableXP[id] = gPlayerXP[id];
	gMemoryTableFlags[id] = gPlayerFlags[id];

	powerCount = getPowerCount(id);
	for (x = 0; x <= powerCount && x <= SH_MAXLEVELS; x++)
		gMemoryTablePowers[id][x] = gPlayerPowers[id][x];
}
//----------------------------------------------------------------------------------------------
memoryTableRead(id, const savekey[])
{
	if (!CvarSuperHeros)
		return false;

	static x, p, idLevel, powerCount, heroIndex;

	for (x = 1; x < gMemoryTableCount; x++) {
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
	strbrkqt(XP, LeftXP, charsmax(LeftXP), XP, charsmax(XP));
	strbrkqt(XPG, LeftXPG, charsmax(LeftXPG), XPG, charsmax(XPG));

	while (XP[0] != '^0' && XPG[0] != '^0' && loadCount < gNumLevels) {
		loadCount++;

		strbrkqt(XP, LeftXP, charsmax(LeftXP), XP, charsmax(XP));
		strbrkqt(XPG, LeftXPG, charsmax(LeftXPG), XPG, charsmax(XPG));

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

	// Add boundaries after getting gNumLevels
	set_pcvar_bounds(sh_minlevel, CvarBound_Upper, true, float(gNumLevels));
	set_pcvar_bounds(sh_mercyxp, CvarBound_Upper, true, float(gNumLevels));
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
createGiveWeaponConfig(const wpnBlockFile[])
{
	new blockWpnFile = fopen(wpnBlockFile, "wt");
	if (!blockWpnFile) {
		debugMsg(0, 0, "Failed to create shweapon.cfg, please verify file/folder permissions");
		return;
	}

	fputs(blockWpnFile, "// Use this file to block SuperHero from giving weapons by map. This only blocks shmod from giving weapons.^n");
	fputs(blockWpnFile, "// For example you can block all heroes from giving any weapon on all ka_ maps instead of disabling the hero.^n");
	fputs(blockWpnFile, "// You can even force people to buy weapons for all maps by blocking all weapons on all maps.^n");
	fputs(blockWpnFile, "//^n");
	fputs(blockWpnFile, "// Usage for maps:^n");
	fputs(blockWpnFile, "// - The asterisk * symbol will act as wildcard or by itself will be all maps, ie de_* is all maps that start with de_^n");
	fputs(blockWpnFile, "// - If setting a map prefix with wildcard and setting a map that has the same prefix, place map name before the^n");
	fputs(blockWpnFile, "//     prefix is used to use it over the prefix. ie set de_dust before de_* to use de_dust over the de_* config.^n");
	fputs(blockWpnFile, "// Usage for weapon:^n");
	fputs(blockWpnFile, "// - Place available weapon shorthand names from list below inside quotes and separate by commas.^n");
	fputs(blockWpnFile, "// - Works like an on/off switch so if you set a weapon twice it will block then unblock it.^n");
	fputs(blockWpnFile, "// - A special ^"all^" shorthand name can be used to toggle all weapons at once.^n");
	fputs(blockWpnFile, "// Valid shorthand weapon names:^n");
	fputs(blockWpnFile, "// - all, p228, scout, hegrenade, xm1014, c4, mac10, aug, smokegrenade, elite, fiveseven, ump45, sg550, galil,^n");
	fputs(blockWpnFile, "// - famas, usp, glock18, awp, mp5navy, m249, m3, m4a1, tmp, g3sg1, flashbang, deagle, sg552, ak47, knife, p90^n");
	fputs(blockWpnFile, "//^n");
	fputs(blockWpnFile, "// Examples of proper usage are as follows (these can be used by removing the // from the line):^n");
	fputs(blockWpnFile, "// - below blocks sh from giving the awp and p90 on de_dust.^n");
	fputs(blockWpnFile, "//de_dust ^"awp, p90^"^n");
	fputs(blockWpnFile, "// - below blocks sh from giving all weapons on all ka_ maps.^n");
	fputs(blockWpnFile, "//ka_* ^"all^"^n");
	fputs(blockWpnFile, "// - below blocks sh from giving all weapons then unblocks hegrenade on all he_ maps.^n");
	fputs(blockWpnFile, "//he_* ^"all, hegrenade^"^n");

	fclose(blockWpnFile);
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
