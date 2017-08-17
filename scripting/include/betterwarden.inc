/*
* 
* INCLUDE FOR THE SOURCEMOD PLUGIN; BETTER WARDEN
* https://github.com/condolent/Better-Warden
* 
*/
#if defined bwardenincluded
 #endinput
#endif
#define bwardenincluded
#define VERSION "0.3.5"

#define a ADMFLAG_RESERVATION
#define b ADMFLAG_GENERIC
#define c ADMFLAG_KICK
#define d ADMFLAG_BAN
#define e ADMFLAG_UNBAN
#define f ADMFLAG_SLAY
#define g ADMFLAG_CHANGEMAP
#define h ADMFLAG_CONVARS
#define i ADMFLAG_CONFIG
#define j ADMFLAG_CHAT
#define k ADMFLAG_VOTE
#define l ADMFLAG_PASSWORD
#define m ADMFLAG_RCON
#define n ADMFLAG_CHEATS
#define z ADMFLAG_ROOT
#define o ADMFLAG_CUSTOM1
#define p ADMFLAG_CUSTOM2
#define q ADMFLAG_CUSTOM3
#define r ADMFLAG_CUSTOM4
#define s ADMFLAG_CUSTOM5
#define t ADMFLAG_CUSTOM6

/**
* Called when the current warden dies.
*
* @param client index
*/
forward void OnWardenDeath(int client);

/**
* Called when a player becomes warden.
*
* @param client index
*/
forward void OnWardenCreated(int client);

/**
* Called when an admin sets a warden.
*
* @param admin client index
* @param client index
*/
forward void OnWardenCreatedByAdmin(int admin, int client);

/**
* Called when the current warden disconnects.
*
* @param client index
*/
forward void OnWardenDisconnect(int client);

/**
* Called when the current warden retires by himself.
*
* @param client index
*/
forward void OnWardenRetire(int client);

/**
* Called when an admin removes the current warden.
*
* @param client index
*/
forward void OnAdminRemoveWarden(int admin, int warden);

/**
* Checks if the given client is currently warden.
*
* @param client index
* @return true if yes
*/
native bool IsClientWarden(int client);

/**
* Checks is there currently is a warden.
*
* @return true if yes
*/
native bool WardenExists();

/**
* Makes the given client warden for the round.
*
* @param client index
* @return true if successful
*/
native bool SetWarden(int client);

/**
* Remove the current warden.
*
* @return true if successful
*/
native bool RemoveWarden();

/**
* Fetch the current wardens' client index
*
* @return client index
*/
native bool GetCurrentWarden();

/**
* Gets the amount of alive players in the specified team.
*
* @param team index
* @return the alive count
*/
native bool GetTeamAliveClientCount(int teamIndex);

/**
* Checks if the client is a Better Warden admin.
*
* @param client index
* @return true if yes
*/
native bool IsClientWardenAdmin(int client);

/**
* Checks several parameters to see if the specified client is a valid user.
*
* @param client index
* @param Allow bots? (False)
* @param Allow dead? (False)
* @return true if valid
*/
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}