/*
* https://github.com/condolent/Better-Warden
*/

#if defined _ZOMBIE_included
 #endinput
#endif
#define _ZOMBIE_included

/**
* Initiates a Zombie event day.
*
* @return				true if successful
*/
native bool initZombie();


public SharedPlugin __pl_bwzombie = 
{
	name = "zombie",
	file = "zombie.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_bwzombie_SetNTVOptional()
{
	MarkNativeAsOptional("initZombie");
}
#endif