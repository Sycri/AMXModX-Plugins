
#if defined _sh_core_extradamage_const_included
  #endinput
#endif
#define _sh_core_extradamage_const_included

// sh_extra_damage() damage types
#define SH_DMG_MULT		0	// Multipiler damage, armor will not reduce damage hit points (armor is still reduced)
#define SH_DMG_NORM		1	// Normal damage, armor will reduce damage hit points
#define SH_DMG_KILL		2	// Kill damage, instantly kills if damage is possible (Note: godmode can block this)

// From multiplayer/dlls/player.cpp (Note: Actual CS calculation is unknown)
#define SH_ARMOR_RATIO		0.5	// Armor Takes 50% of the damage (0.2 in the HL SDK)
#define SH_ARMOR_BONUS		0.5	// Each Point of Armor is worth 1/x points of health (0.5 in the HL SDK)
