
#if defined _sh_core_objectives_const_included
  #endinput
#endif
#define _sh_core_objectives_const_included

// VIP Flags, set with sh_blockvip CVAR
#define VIP_BLOCK_POWERKEYS (1 << 0)	/* flag "a" */	// VIP blocked from using power keys
#define VIP_BLOCK_WEAPONS   (1 << 1)	/* flag "b" */	// VIP blocked from receiving weapons thru sh
#define VIP_BLOCK_HEALTH    (1 << 2)	/* flag "c" */	// VIP blocked from receiving health thru sh
#define VIP_BLOCK_ARMOR     (1 << 3)	/* flag "d" */	// VIP blocked from receiving armor thru sh
#define VIP_BLOCK_SPEED     (1 << 4)	/* flag "e" */	// VIP blocked from receiving speed thru sh
#define VIP_BLOCK_GRAVITY   (1 << 5)	/* flag "f" */	// VIP blocked from receiving gravity thru sh
#define VIP_BLOCK_EXTRADMG  (1 << 6)	/* flag "g" */	// VIP blocked from using sh_extra_damage
#define VIP_BLOCK_CUSTOM    (1 << 7)	/* flag "h" */	// Custom VIP block, heroes can use for whatever they want
