
#include <superheromod>
#include <zp50_core>

public plugin_init() {
	register_plugin("[ZP] SH Compatibility", "1.0", "Sycri")
}

public zp_fw_core_infect_post(victim, attacker) {
	sh_add_kill_xp(attacker, victim)
	reset_user_attributes(victim)
}

public zp_fw_core_cure_post(victim) {
	reset_user_attributes(victim)
}

reset_user_attributes(index) {
	if(get_user_health(index) < sh_get_max_hp(index)) set_user_health(index, sh_get_max_hp(index))
	
	if(get_user_armor(index) < sh_get_max_ap(index)) cs_set_user_armor(index, sh_get_max_ap(index), CS_ARMOR_VESTHELM)
	
	sh_reset_min_gravity(index)
	sh_reset_max_speed(index)
}