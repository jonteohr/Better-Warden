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
#define VERSION "0.6.4"

stock char g_sPrefix[] = "[{blue}Warden{default}] ";
stock char g_sLogPath[PLATFORM_MAX_PATH] = "addons/sourcemod/logs/betterwarden.log";


/**
* Called when the current warden dies.
*
* @param client			Client index
*/
forward void OnWardenDeath(int client);

/**
* Called when a player becomes warden.
*
* @param client			Client index
*/
forward void OnWardenCreated(int client);

/**
* Called when an admin sets a warden.
*
* @param admin			Client index of the admin
* @param client			Client index of the target
*/
forward void OnWardenCreatedByAdmin(int admin, int client);

/**
* Called when the current warden disconnects.
*
* @param client			Client index
*/
forward void OnWardenDisconnect(int client);

/**
* Called when the current warden retires by himself.
*
* @param client			Client index
*/
forward void OnWardenRetire(int client);

/**
* Called when an admin removes the current warden.
*
* @param admin			Client index of the admin
* @param warden			Client index of the warden
*/
forward void OnAdminRemoveWarden(int admin, int warden);

/**
* Called when a warden is removed in any way.
*
* @param client			The warden client index
*/
forward void OnWardenRemoved(int client);

/**
* Checks if the given client is currently warden.
*
* @param client			Client index
* @return				true if yes
*/
native bool IsClientWarden(int client);

/**
* Checks is there currently is a warden.
*
* @return				true if yes
*/
native bool WardenExists();

/**
* Makes the given client warden for the round.
*
* @param client			Client index
* @return				true if successful
*/
native bool SetWarden(int client);

/**
* Remove the current warden.
*
* @return				true if successful
*/
native bool RemoveWarden();

/**
* Fetch the current wardens' client index
*
* @return				Wardens' client index
*/
native bool GetCurrentWarden();

/**
* Gets the amount of alive players in the specified team.
*
* @param team			Team index number
* @return				the alive count
*/
native bool GetTeamAliveClientCount(int teamIndex);

/**
* Checks if the client is a Better Warden admin.
*
* @param client 		Client index
* @return				true if yes
*/
native bool IsClientWardenAdmin(int client);

/**
* Checks several parameters to see if the specified client is a valid user.
*
* @param client 		Client index
* @param bAllowBots		Allow bots? (Default = false)
* @param bAllowDead		Allow dead? (Default = false)
* @return				true if valid
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
* @param sModel			Path to model (Inside /materials/)
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

/**
* Adds a message to logfile if enabled in config.
*
* @param sMessage		Message to enter in log
* @param ...			Formatting arguments
* @return				true if successful
*/
native bool AddToBWLog(const char[] sMessage, any ...);

/**
* Show an overlay to a specific client
*
* @param client			Client index
* @param path			Path to the overlay file
* @param lifetime		How long the overlay should be shown. 0.0 = Forever
*/
stock void ShowOverlay(int client, char[] path, float lifetime) {
	if (!IsValidClient(client))
		return;

	ClientCommand(client, "r_screenoverlay \"%s.vtf\"", path);

	if (lifetime != 0.0)
	{
		CreateTimer(lifetime, DeleteOverlay, GetClientUserId(client));
	}
}


/**
* Show an overlay to all clients on the server
*
* @param path			Path to the overlay file
* @param lifetime		How long the overlay should be shown. 0.0 = Forever
*/
stock void ShowOverlayAll(char[] path, float lifetime) {
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;

		ClientCommand(i, "r_screenoverlay \"%s.vtf\"", path);

		if (lifetime != 0.0)
		{
			CreateTimer(lifetime, DeleteOverlay, GetClientUserId(i));
		}
	}
}


stock Action DeleteOverlay(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);

	if (!IsValidClient(client))
		return Plugin_Handled;

	ClientCommand(client, "r_screenoverlay \"\"");

	return Plugin_Handled;
}

/**
* Adds the provided decal to downloads table and precaches it.
*
* @param path			Path to the decal. Inside /materials/
*/
stock void PrecacheDecalAnyDownload(char[] path) {
	if (strlen(path) == 0)
		return;

	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "%s.vmt", path);
	PrecacheDecal(sBuffer, true);
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", path);
	AddFileToDownloadsTable(sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%s.vtf", path);
	PrecacheDecal(sBuffer, true);
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", path);
	AddFileToDownloadsTable(sBuffer);
}