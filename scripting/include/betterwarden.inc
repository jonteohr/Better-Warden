/*
* 
* INCLUDE FOR THE SOURCEMOD PLUGIN; BETTER WARDEN
* https://forums.alliedmods.net/showthread.php?t=298907
* 
*/
#if defined bwardenincluded
 #endinput
#endif
#define bwardenincluded

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
* Checks several parameters to see if the specified client is a valid user.
*
* @param client index
* @param Allow bots?
* @param Allow dead?
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