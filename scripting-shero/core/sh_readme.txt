/* AMX Mod X script.
*
*   SuperHero Mod
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
*****************************************************************************/

/****************************************************************************
*
*	Version 1.3.0 - Date: 08/29/2020
*
*	Original by {HOJ} Batman <johnbroderick@sbcglobal.net>
*
*	Formerly maintained by the SuperHero Team
*	https://forums.alliedmods.net/forumdisplay.php?f=30
*
*	Currently being maintained by Sycri (Kristaps08)
*	https://github.com/Sycri/AMXModX-Plugins
*	https://forums.alliedmods.net/member.php?u=79905
*
****************************************************************************
*
*	GOALS
*	 1) keep # of binds small and determinable (i.e. no matter what new heroes come along)
*	 2) reuse binds amongst heroes (so you don't have to keep rebinding)
*	 3) modular heroes - can add and take away using plugins.ini and separate hero *.sma scripts
*
*	Admin Commands:
*
*	 amx_shsetxp			- Allows admins to set a players XP to a specified amount
*	 amx_shaddxp			- Allows admins to give a players a specified amount of XP
*	 amx_shsetlevel			- Allows admins to set a players level to a specified number
*	 amx_shban				- Allows admins to ban players from using powers
*	 amx_shunban			- Allows admins to un-ban players from using powers
*	 amx_shimmunexp			- Allows admins to set/unset players immune from save days XP reset (Unavailable for nVault)
*	 amx_shresetxp			- Allows admins with ADMIN_RCON to reset all the saved XP
*
*	Client Commands:
*
*	 say /help				- Shows help window with all other client commands.
*
*	CVARs: Please see the shconfig.cfg for the CVAR settings
*
*				******** AMX Mod X 1.90 and above Only ********
*				*********** ENGINE Module REQUIRED ************
*				************* FUN Module REQUIRED *************
*				********** Fakemeta Module REQUIRED ***********
*				******** Ham Sandwich Module REQUIRED *********
*				********** CStrike Module REQUIRED  ***********
*				************* CSX Module REQUIRED *************
*
*	Changelog:
*	v1.3.0 - Sycri (Kristaps08) - 08/29/20
*	 - Added Ham_AddPlayerItem since Ham_Player_ResetMaxSpeed does not catch weapon pickups or purchases
*	 - Changed extradamage to use hamsandwhich Ham_TakeDamage.
*	 - Changed the function chatMessage so that it uses client_print_color
*	 - Changed most cvars from get_pcvar_num to bind_pcvar_num so variables could be used directly
*	 - Changed from RegisterHamFromEntity to RegisterHamPlayer for cleaner code
*	 - Completed setting gravity based on current weapon.
*	 - Forced usage of semicolons for better clarity
*	 - Removed all previous backwards compatibility
*	 - Removed code that uses old syntax for MySQL 3.23
*	 - Removed cvar sh_adminaccess in favor of cmdaccess.ini
*	 - Removed repetitive checks in natives
*	 - Removed variables which cache cvars since AMX Mod X 1.9.0 does it now itself
*	 - Renamed nearly all functions for a unified style
*	 - Replaced arrays with bit-fields to improve performance and reduce memory footprint
*	 - Replaced client command buy blocking with forward CS_OnBuy
*	 - Replaced deprecated function client_disconnect with client_disconnected
*	 - Replaced deprecated function strbreak and stock function strbrkqt with argbreak
*	 - Replaced event CurWeapon with forward Ham_Player_ResetMaxSpeed for more reliable speed change
*	 - Replaced forward FM_Touch with Ham_Touch since the former is less efficient
*	 - Replaced register_cvar with create_cvar
*	 - Replaced SH_MAXSLOTS with MAX_PLAYERS since the latter is in AMX Mod X core
*	 - Replaced variable gServersMaxPlayers with MaxClients which is available in AMX Mod X since version 1.8.3
*	 - Rewrote parts of the SuperHero Core and default heroes
*	 - Separated SuperHero Mod into multiple plugins
*
*	v1.2.1 - vittu - ??/??/??
*	 - Changed SH_ARMOR_RATIO to 0.5 since in cs armor seems to reduce damage by 50% not 80%
*	 - Added native sh_set_hero_dmgmult for weapon multipliers to directly hook damage instead of faking damage with sh_extra_damage
*	 - Added removal of all Monster Mod monsters on new round, stops monster freezetime attacks
*	 - Added option to force save by IP or save by name with cvar sh_saveby
*	 - Added option for Free For All servers to gain money/frags/xp on tk instead of losing money/frags/xp on tk with cvar sh_ffa
*	 - Fixed shield restrict forcing drop of shield to actually drop shield not just active weapon
*	 - Removed /savexp say command due to complaint of the xp removal it has done since version 1.17.4
*	 - Converted superheromysql.inc to use sqlx instead of dbi and optimized a bit
*	 - Fixed passing of some buffers into format routines
*	 - Changed menu string size and made it smaller, it had too much overhead
*	 - Added use of charsmax
*	 - Removed unnecessary checks and static's in stocks
*	 - Fixed Ham_Spawn's first Ham_Spawn call block method
*	 - Fix for amb1961: superhero.ini was being read too late causing sh_minlevel and sh_mercyxp cvars to be set improperly by core
*
*	v1.2.0 - JTP10181/vittu - 08/17/08
*	(took over where JTP10181 left off, mixture of both our work as follows below)
*	 - Converted server messages in core plugin to register_natives, better for plugin communication and fixes overflow caused by too many heroes
*	 - Converted from engine to fakemeta, integrated cstrike more, and utilized csx natives
*	 - Converted to use pcvar system core and heroes
*	 - Converted fully to new file system over inefficient write_file methods
*	 - Added new natives, renamed old, and added some extra options that were not in old
*	 - Added optional modes for reload that can be controlled server wide
*	 - Added VIP support, bonus xp for vip assassination/rescue.
*	 - Added optional blocks for VIP: power key usage, sh give weapons, ect.
*	 - Added cvar for amount of players required to be in server for mercy/hostage/bomb/vip XP
*	 - Added config file to disable sh giving of specified weapon based on map
*	 - Added camera turn toward attacker on death from sh extradamage (thanks Emp`)
*	 - Added damage inflictor to sh extradamage. External plugins might use this ie. ATAC3
*	 - Added silence/burst reset to drop weapon reload mode
*	 - Added bots choosing powers automatically
*	 - Added grey colored chat to prefix chat messages as well as native for it
*	 - Added /automenu say option to disable hero menu from showing up on spawn
*	 - Added amx_shimmunexp admin command to set users immune from savedays deletion (NOT available for nVault)
*	 - Fixed exploit with switching team to gain mercy xp
*	 - Fixed sh setting sv_maxspeed when set higher than what sh requires, some heroes might need more than detected by sh
*	 - Fixed StatusText info from being over written by name of user in crosshairs
*	 - Fixed incorrect amounts in max bpammo and max clip stocks, converted to lookup tables instead of switch statements as well
*	 - Fixed shero folder will now be created if it does not exist. Allows cfg files to be created if they do not exist (except shconfig.cfg)
*	 - Fixed sh_hsmult to work with extradamage headshots, was not counted before
*	 - Fixed clearpowers to send drop on only heroes user had not all heroes server has
*	 - Fixed player console playerskills command cutting off hero names in some cases
*	 - Fixed speed resetting to default speeds after zooming with a sniper rifle
*	 - Fixed bug with keys reversing when HUD shows 0 health
*	 - Fixed possible reliable channel overflow on clients from hero_inits running on ResetHUD causing a loop from weapon give
*	 - Converted to Ham_Spawn post for better reliablity, this adds hamsandwich to be included by default
*	 - Changed the speed system to use actual weapon speeds when resetting to normal, instead of just setting 210
*	 - Changed to track bomb by entity index, cleaner then by bomb holder
*	 - Changed how single hostage bonus xp is given by detecting the amount of hostages on a map
*	 - Changed hero default cvars lvl/hp/ap/grav/speed to be read by pcvar instead of a global, fixes issue with first map hero cvars not setting
*	 - Changed shRemHealthPower, shRemArmorPower, shRemGravityPower, shRemSpeedPower, and shResetShield to be taken care of by the core when hero dropped
*	 - Changed help motd into a file, shmotd.txt, and edited its content
*	 - Removed Cheating-Death support since it is a dead project
*	 - Removed amxmod support since it is a dead project
*	 - Removed cvars sh_round_started and sh_cdrequired
*	 - Removed suicides from hl logs caused by extradamage
*	 - Renamed 3 default heroes Nightcrawler/Windwalker/Zues to Shadowcat/Black Panther/Grandmaster respectively
*	 - Renamed cvar sh_bombhostxp to sh_objectivexp
*	 - Renamed functions in core for better managability
*	 - Recoded all default heroes to have a similar style of coding and optimized them
*		Thanks go to teame06, Emp, and jtpizzalover for their input from my constant badgering of this release.
*		Also, thanks to (msv_), ([S0|0]), and Galore ([G]S) clans for letting me test betas on their servers. - vittu
*
*	v1.18e - JTP10181 - 07/25/06
*	 - Fixed runtime error in reloadAmmo caused by bad hero scripting
*	 - Allowed addXP to take a Float for the multiplier
*	 - Stunning a player now disables their +power keys also (thanks mydas for pointing this out)
*	 - Renamed some functions to match the others
*	 - Added nVault include file for AMXX only
*	 - Fixed issue with Stun and God timers carrying to next round if user stayed alive (thanks vittu)
*	 - Fixed bug in timer that made it skip the last second
*	 - Fixed exploit in stun system
*	 - Fixed bugs in admin commands with case sensitivity
*
*	v1.18d - JTP10181 - 08/27/05
*	 - Fixed runtime errors with AMXX 1.55 and MySQL
*	 - Fully tested with MySQL 4.1.14, MySQL 4.0.25 and MySQL 3.23.58
*	 - Fixed mem leaks from not using dbi_free_result properly
*	 - Added define to mysql include for old style syntax
*
*	v1.18c - JTP10181 - 07/31/05
*	 - Added some more MercyXP abuse checking
*	 - Fixed bug where players could have stale heroes from last player with the same index number
*
*	v1.18a - JTP10181 - 07/19/05
*	 - Added check to extradamage for godmode on the target player
*	 - Fixed bug in bot XP saving that could cause server lockups
*	 - Fixed run time error 4 that occurred when saving the memory table
*
*	v1.18 - JTP10181 - 05/16/05
*	 - Fixed bugs with the CVAR checking
*	 - Changed speed system hack to be enabled for AMX 0.9.9+ also
*	 - Fixed extradamage logging if you kill yourself
*	 - Fixed issue with mysql saving XP if the client has a ` or ' in their name.
*	 - Added a hack to fix XP saving for listen server admins
*	 - Changed debug message logging so the message will always be shown even if server logging is off
*	 - Fixed cooldown timer code to prevent a task from the last round interfering in the next round
*	    (Requires the hero to be recompiled with new includes)
*	 - Made it so when magneto strips a players weapons they vanish instead of ending up on the ground
*	 - Extradamage function now does armor calculations and removes it accordingly
*	 - Fixed issue with armor that superhero gives you was not being recognized by CS
*	 - Fixed issue with server_exec causing the config not to exec for everyone
*	 - Increased default SH_MAXLEVELS to 100, sick of all these tards who can't compile
*	 - Changed the MySQL include around a bunch, better queries, non-persistent connection, etc...
*	    Thanks for the help from HC of superherocs.com
*	 - Changed HUDHELP memtable to be player flags for future use
*	 - Added admin command logging
*	 - Allowing XP lines in superhero.ini to load up to 1024 bytes instead of 512
*	 - Added loop for registering power keydowns so it adjusts with SH_MAXBINDPOWERS
*	 - Greatly reduced number of SQL queries sent every round if using endround saving, by not re-saving a persons heroes unless they change them
*	 - Fixed bug in extradamage that took away XP for suicide
*	 - Utilized plugin_log native for hostage and bomb XP events, fixing the bugs in them
*	 - Added check so people don't get MercyXP for typing "kill" in the console (not available for AMX98)
*	 - Prevented XP variable overflow which would cause XP loss to the player
*	 - Removed XP checks in adminSetXP since the above fix prevents overflows
*
*	v1.17.6 - JTP10181 - 12/15/04
*	 - Made it so menu is not auto-displayed for spectators
*	 - Fixed bug, giving wrong XP ammout if you get a HS and are using the HSMULT setting
*	 - Fixed bug, reload ammo function would slow down user if using the drop weapon setting
*	 - Added functionality to remeber XP for bots by thier names
*	 - Eliminated cpalive CVAR, set sh_cmdprojector to "2" for the same effect
*	 - Heroes using extradamage now send the correct weapon name if they are only multiplying the damage
*	 - Added ability to send shExtraDamage as a headshot so the kill shows up correctly
*	 - Fixed small bug in playerskills console output
*	 - Fixed version CVAR so it will change when upgrading without a server restart
*	 - Plugin tries to make SQL tables if they don't exist already
*	 - Fixed bug if superhero is disabled no one could chat.
*	 - Tweaked the speed system to make it spam less on AMXModX
*	 - Made the admin commands idiot proof
*	 - Made use of plugin_cfg() stock instead of a task
*	 - Fixed bug, extradamage would not let you kill yourself
*	 - Added check so sh_xpsavedays cannot bet set higher than 365
*	 - Added checks for other CVARS since people like to do stupid things
*	 - Fixed issue with people binding to +power1; +power1; +power1;.....
*	 - Changed function of sh_bombhostxp again, it was too confusing the way it was
*	 - Added check so core can only be loaded once (not available on AMX 0.9.9+)
*	 - Fixed bug with non-saved XP, XP never intialiazing.
*
*	v1.17.5 - JTP10181 - 10/03/04
*	 - AMXX 0.20 Support (Vault and MySQL)
*	 - Tweaks to godmode coding to prevent problems
*	 - Fixed anubis errors on AMXX
*	 - Fixed Batman "Reliable channel overflow" problems on AMXX
*	 - Cleaned up code on all heroes, redid indenting, removed useless code.
*	 - Successful bomb plant will now give entire alive team XP
*	 - Added event to catch round end if triggered by sv_restart
*	 - Tweaked hostage and bomb XP to make it more evenly distributed
*	 - Added new function to include to reload clients ammo (see sh_punisher.sma for example)
*	 - Fixed some stuff in the include for AMXX
*	 - Reworked vault data parsing to remove hardcoded limit of loading only 20 skills (heroes)
*	 - Rewrote readINI function to use new strbrkqt stock
*	 - Moved all the shExtraDamage code into the core
*	 - Fixed readXP so it will not get processed more than once on a player
*	 - Added new hero command to set a shield restriction (see sh_batman.sma for example)
*	 - Found a more reliable way to detect hostage rescue and get players id
*	 - Fixed some bugs in the stun system
*
*	v1.17.4 - JTP10181 - 09/05/04
*	 - Fixed "playerskills" bug with some skills getting cut off
*	 - Fixed bug with XP not displaying until after freezetime
*	 - Hero Levels should now load correctly from cvars on the first map
*	 - Fixed "whohas" that has been broken for a long time I assume
*	 - Fixed bug in "drop" command when client has the max powers allowed on the server
*	 - Increased plugins available memory as it was teetering near the edge of runtime 3 issues.
*	 - Tweaked string array lengths to make plugin use less memory
*	 - Finally fixed menu bug causing it to say a hero was disabled when it wasn't
*	 - Added code to restrict dropping while alive and a cvar to enable / disable it.
*	 - Fixed bug in godmode code so one godmode wont cancel another out
*	 - "File" saving support totally removed (vault saving is still the default)
*	 - Added support for AMX 0.9.9
*
*	v1.17.3 - JTP10181 - 08/27/04
*	 - Fixed bug with loadimmediate and some people loosing XP
*	 - Fixed bug with ban code if file did not end in a newline
*	 - Added checks to make sure authid is valid before trying to load XP
*	 - Made autobalance setting get ignored when savexp is on
*	 - Fixed more bugs with XP not loading correctly.
*	 - Added admin command to reset all the XP
*	 - Worked a lot on the MySQL include to make it work better overall
*	 - Added a bunch of checks to cancel events for bots (better CZ support also)
*	 - Found a way to reset speed without forcing a weapon switch
*	 - Fixed bugs with menu resetting to page 1 while you are in it
*	 - Made it so powers are not disabled (for freezetime) until the first person spawns
*	 - Changed function of debug cvar, it is now the debugging level.
*
*	v1.17.2 - JTP10181 - 08/17/04
*	 - Fixed runtime errors if you exceed the MAXHEROS amount
*	 - Fixed bug with playSoundDenySelect, changed to client spk so others cannot hear it
*	 - Made banning system use less files reads, with the old method it would have caused lag with a large ban file
*	 - Redid banning support, can now unban also.
*	 - Changed debugMsg function again, to backward support non-stock heroes
*	 - Fixed more bugs with stale menus after certain commands
*	 - Fixed some issues with variables that could have been causing memory problems
*	 - Fixed some menu issues that arose with the last release
*	 - Added a cvar to put the menu back how it used to be where it hides disabled heroes
*	 - Added a cvar to change (or disable) the level limiting in the menu
*	 - Tweaked the way things load on first startup to hopefully fix cvar issues people are having
*	 - Found recursion problem causing runtime error 3 and fixed it
*	 - If a level is lost the plugin will remove heroes you should not have anymore
*	 - Added HeadShot multiplyer cvar to give extra XP for headshots
*
*	v1.17.1 - JTP10181 - 08/12/04
*	 - Redid the new round code, should have fixed some bugs with the feezetime being 0
*	 - Fixed bug with sh_adminaccess not getting loaded from config before being set as level for commands
*	 - Redid the debugging messages system
*	 - Redid the readINI function to make it more versatile
*	 - Fixed bug with giving XP for hostage rescue
*	 - Removed some useless code in the hostage rescue system
*	 - Added status messages for the XP given on bomb and hostage events
*	 - Changed use of sh_bombhostxp cvar. It now sets the level of XP given/taken for the events
*	    Set CVAR to -1 to disable the XP bonuses
*	 - Changed the default admin flag because for some reason it was set to the admin_immunity flag
*	 - Fixed vault saving by IP so it wont use the port anymore, only the IP
*	 - Blocked fullupdate client command to prevent exploiting and resetting cooldown timers and other bad things.
*	 - Changed the menu system to make it less confusing why some heroes are not available
*	 - Added extra codes to the menu system
*	 - Grayed out disabled menu items instead of hiding them
*	 - Error message if no argument supplied to /whohas
*	 - Added Power Number to /herolist output
*	 - Fixed bug in the clearpower function causing hero ids to be out of place in the players array
*	 - Redid the damage function in the inc file, blocking death messages with vexd and updating scoreboard properly
*	 - Fixed bug with clearpowers when menu was on screen, it would be stale and not refresh
*	 - Added function to adjust the servers sv_maxspeed so speed increasing heroes can work properly
*	 - Redid the layout for most of the stock heroes so its more standardized.
*	 - Removed xtrafun from all heroes possible to better support amx 0.9.9.
*
*	v1.17 - JTP10181 - 07/27/04
*	 - Updated all motd box output to be more easy to follow
*	 - Fixed bug if only one hero left to pick it would not be displayed
*	 - Fixed bug with setting the speed system
*	 - Fixed admin commands to follow better standards
*	 - Added mercy XP system to give players who gained no XP a small boost each round
*	 - cmd_projector merged in with this plugin
*
*	REV 1.16.0 - (ASSKICR) Fixed save by ip if sv_lan = 1
*	REV 1.14.8 - (ASSKICR) Fixed the 1.6 speed bug
*	REV 1.14.7 - (ASSKICR) Made some fixes in newround
*	REV 1.14.6 - (ASSKICR) Made it save XP by STEAMID for 1.6 and WONID for 1.5
*	REV 1.14.5 - (ASSKICR) - Made a few more commands for XP and a command to block powers
*	REV 1.14.4 - added ability to point mysql database to another database than the default amx database if these cvars exists: sh_mysql_db, sh_mysql_user, sh_mysql_pass, sh_mysql_db
*	REV 1.14.3 - bug fix playerpower missed 1 level.  amx_vaulttosql didn't strip shinfo. cleanXP() mysql delete now does sh_saveskills to
*	REV 1.14.2 - bug fix - "re"-joiners loose certain hero skills
*	REV 1.14.1 - mysql, cvars(sh_loadimmediate), say commands(playerskills, playerlevels, whohas),
*				command (amx_vaulttosql) if mysqlmode...
*				Initialize via server command instead of plugin_ini
*				deprecated cvar (sh_usevault)
*				small Xavier disconect test
*				small change in displayPowers (now shows how many levels are earnable)
*	REV 1.13.3 - MSG_ONE gaurd to try and eliminate writedest crashes
*	REV 1.13.2 - unabomber radius change, bomberman, cyclops slightly, anubis
*	REV 1.13.1 - changed xavier, rolled in aquaman
*	REV 1.12b - reviewing xtrafun based heroes: ironman, skeletor, spiderman, xavier ( make sure user is alive b4 getting origin on new_round), nightcrawler, windwalker
*				Going to try and eliminate xtrafun calls on new joiners to see if can elimnate the crashes.
*	REV 1.12a - fixed loadXP bug - ppl losing XP - various small checks
*	REV 1.11b  - not using max_players() function any longer - test...
*	REV 1.11a - Made hero levels a number instead of reading cvars..., changes cleanXP to make a little better
*	REV 1.10f - take out playerpowerflags..., gaurded key presses by gPlayerBinds instead of gPlayerPowers
*	REV 1.10d - make bomb/hostage, speed, health, armor, gravity turned into vars instead of cvar reads
*	REV 1.10c - refined speed hack bug fix, FIXED playerskills 4096 vs 2048 copy problem
*				changed batman and hob to zeus with weapons.  Batman no longer gets defuse packs.
*	REVE 1.10b
*	REV  1.10a
*	REV 1.09 - commented out client_connect code (should be done on disconnect), make sure user is alive on newRound(),
*				added startround,endround logic to pop client menus to people just joining
*	REV 1.08 - readMemoryTable make sure key is >0, sh_round_started only set once
*	REV 1.07 - fixed unabomber, fixed loading guy with more than sh_maxpowers, addes sh_endroundsave
*	REV 1.06 - removed messaging from heroes - wolv heals to 100, drac to 100
*	REV 1.05 - ADDED sh_maxpowers, removed register loops, added regMaxHealth
*	REV 1.04 - REMOVED CVARS AS A WAY TO COMMUNICATE PLAYER LEVELS AND PLAYER MAXHEALTH
*	REV 1.03 - PROVED CVARS WERE CRASHING SERVER
*	REV 1.02 Beta
*	6/1/2003  - strunpack to copies and changed diminsions - testing crashes large servers
*	5/16/2003 - Fixed mid-round join bug
*	5/17/2003 - Added amx_shsetlevel, amx_shxpspeed, console playerskills
*
*	Thanks to ST4life for the orginal time projector that was used for the cmd projector
*	Thanks to asskicr for his version which this is based off of
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
*	- Make use of multilingual support for "core" messages only.
*	- Remove all use of set_user_info, find a better method to tell when a power is in use (possibly native so hero can say it's in use).
*	- Run a check to make sure no menu is open before opening powers menu.
*	- Add chosen hero child page to menu to verify hero choice, but mainly to add hero info there instead of using hud messages for powerHelp info.
*	- Clean up any issues with the say commands.
*	- Possibly use threading only for mysql saving at round end (may require too much recoding).
*	- Convert the read_file usage in superheromysql.inc to use new file natives.
*	- Add check to skip power key if pressed too fast to stop aliasing multiple power keys at the same time.
*	- Make sh more csdm/respawn friendly, remove reliance on round ending
* 	- Make restricting bonus xp bomb tracking optional
*
**************************************************************************/
