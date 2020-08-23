// SuperHero Constants Include File
// Version 1.3.0

#if defined _sh_core_main_const_included
  #endinput
#endif
#define _sh_core_main_const_included

//----------------------------------------------------------------------------------------------
// Changeable DEFINE Settings, must recompile SuperHero plugins if changed
//----------------------------------------------------------------------------------------------

// Max levels that can be loaded from the superhero.ini
#define SH_MAXLEVELS 100

// Max Amount of heros that can be loaded
#define SH_MAXHEROS 100

// Potential of power1-power9 but limited by sh_maxbinds (3 default)
#define SH_MAXBINDPOWERS 9

//----------------------------------------------------------------------------------------------
// DO NOT EDIT BELOW HERE
//----------------------------------------------------------------------------------------------

#define SH_VERSION		1.30
stock const SH_VERSION_STR[] =	"1.3.0.0";
stock const SH_AUTHOR_STR[] =	"JTP10181/{HOJ}Batman/vittu/AssKicR/Sycri";

// Cooldown task id, required to allow core to stop task
#define SH_COOLDOWN_TASKID	572910

// sh_hero_init(id, heroID, mode) modes
#define SH_HERO_DROP	0	//Hero is dropped
#define SH_HERO_ADD		1	//Hero is added

// sh_hero_key(id, heroID, key) keys
#define SH_KEYUP		0	//Power Key is released
#define SH_KEYDOWN		1	//Power Key is pressed

// sh_extra_damage() damage types
#define SH_DMG_MULT		0	// Multipiler damage, armor will not reduce damage hit points (armor is still reduced)
#define SH_DMG_NORM		1	// Normal damage, armor will reduce damage hit points
#define SH_DMG_KILL		2	// Kill damage, instantly kills if damage is possible (Note: godmode can block this)

// From HLSDK for sh_screenfade
#define SH_FFADE_IN		0x0000	// Just here so we don't pass 0 into the function
#define SH_FFADE_OUT		0x0001	// Fade out (not in)
#define SH_FFADE_MODULATE	0x0002	// Modulate (don't blend)
#define SH_FFADE_STAYOUT	0x0004	// Ignores the duration, stays faded out until new ScreenFade message received

// User Flags, saved with XP data
#define SH_FLAG_HUDHELP		(1 << 0)	/* flag "a" */	// Enable the Help HUD
#define SH_FLAG_NOAUTOMENU	(1 << 1)	/* flag "b" */	// Do not show menu automatically on spawn
#define SH_FLAG_XPIMMUNE	(1 << 2)	/* flag "c" */	// Immue to xp reset from savedays. (Not available for nVault)
#define SH_FLAG_BANNED		(1 << 3)	/* flag "d" */	// Flag user banned from having hereos (not used, if used would have to keep info stored and will not work with nVault)

// From multiplayer/dlls/player.cpp (Note: Actual CS calculation is unknown)
#define SH_ARMOR_RATIO		0.5	// Armor Takes 50% of the damage (0.2 in the HL SDK)
#define SH_ARMOR_BONUS		0.5	// Each Point of Armor is worth 1/x points of health (0.5 in the HL SDK)

// Common sound for denying power use, precached by core
stock const gSoundDeny[] = 	"common/wpn_denyselect.wav";
