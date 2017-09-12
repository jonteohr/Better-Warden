/*
* https://github.com/condolent/Better-Warden
*/

#if defined _CATCH_included
 #endinput
#endif
#define _CATCH_included

/**
* Initiates a Catch event day.
* 
* @return				true if successful
*/
native bool initCatch();


public SharedPlugin __pl_bwcatch = 
{
	name = "catch",
	file = "catch.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_bwcatch_SetNTVOptional()
{
	MarkNativeAsOptional("initCatch");
}
#endif