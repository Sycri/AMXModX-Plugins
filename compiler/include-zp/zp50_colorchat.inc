#if defined _zp50_colorchat_included
  #endinput
#endif
#define _zp50_colorchat_included

#include <zp50_colorchat_const>

// --------------
// Example usage:
// --------------
// zp_colored_print(id, "Class: %L", id, "CLASS_HUMAN")
// zp_colored_print(0, "Class: %L", LANG_PLAYER, "CLASS_HUMAN")
// zp_colored_print(id, "Class: %l", "CLASS_HUMAN")
// zp_colored_print(0, "Class: %l", "CLASS_HUMAN")
// ----------------------------------------------------------------------------

// Prints a colored message to target (use 0 for everyone), supports ML formatting.
// - Supports passing -1 as an argument (ZP 4.3 stock had a bug with that)
// - Does not support blue/red/gray colors
stock zp_colored_print(target, const message[], any:...)
{
	static buffer[512], len;
	buffer[0] = '^0';
	len = 0;

	// Format message for player (+add ZP prefix)
	len += copy(buffer, charsmax(buffer), ZP_PREFIX);
	vformat(buffer[len], charsmax(buffer) - len, message, 3);

	// Send it
	client_print_color(target, print_team_default, buffer);
}
