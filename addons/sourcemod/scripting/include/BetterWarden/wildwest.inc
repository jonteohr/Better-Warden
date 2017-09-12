/*
* https://github.com/condolent/Better-Warden
*/

#if defined _WILDWEST_included
 #endinput
#endif
#define _WILDWEST_included

/**
* Initiates a Wild West event day.
*
* @return				true if successful
*/
native bool initWW();


public SharedPlugin __pl_bwwildwest = 
{
	name = "wildwest",
	file = "wildwest.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_bwwildwest_SetNTVOptional()
{
	MarkNativeAsOptional("initWW");
}
#endif