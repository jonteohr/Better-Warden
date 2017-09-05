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
#define VERSION "0.5"

stock char prefix[] = "[{blue}Warden{default}] ";

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
* Called when a warden is removed in any way.
*
* @param the warden client index
*/
forward void OnWardenRemoved(int client);

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

/**
* Precaches and prepares models for download. Used for icons!
*
* @param path to model
*/
stock void PrecacheModelAnyDownload(char[] sModel)
{
	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", sModel);
	AddFileToDownloadsTable(sBuffer);
	PrecacheModel(sBuffer, true);
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", sModel);
	AddFileToDownloadsTable(sBuffer);
	PrecacheModel(sBuffer, true);
}