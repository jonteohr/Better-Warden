/*
* https://github.com/condolent/Better-Warden
*/

#if defined _GANGS_included
 #endinput
#endif
#define _GANGS_included

Database gH_Db;

/**
* Initiates the database connection
*/
stock void SQL_InitDB() {
	char sError[255];
	
	gH_Db = SQL_Connect("betterwarden", true, sError, sizeof(sError));
	
	if(gH_Db != null) { // Success on connection
		SQL_CreateBWTable();
	} else { // Shit, we messed up
		PrintToServer("### Could not connect to the database! ##");
		PrintToServer("%s", sError);
	}
}

/**
* Creates the table if it doesn't exist
*
* @param name			The table name
* @error				Database connection issues
*/
stock void SQL_CreateBWTable() {
	char sQuery[255];
	char sQuery2[255];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS betterwarden_players (ID int NOT NULL AUTO_INCREMENT, STEAMID varchar(255), GangID int);");
	Format(sQuery2, sizeof(sQuery2), "CREATE TABLE IF NOT EXISTS betterwarden_gangs (ID int NOT NULL AUTO_INCREMENT, Name varchar(255), Owner varchar(255));");
	
	if(!SQL_FastQuery(gH_Db, sQuery)) {
		char err[255];
		SQL_GetError(gH_Db, err, sizeof(err));
		PrintToServer("Error: %s", err);
	}
}

/**
* Checks if a user is registered or not in the DB
*
* @param client			The client to look up
* @return				true if exists
*/
stock bool SQL_UserExists(int client) {
	char sQuery[255];
	char sSteamID[64];
	
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	Format(sQuery, sizeof(sQuery), "SELECT * FROM betterwarden_players WHERE STEAMID LIKE '%s'", sSteamID);
	
	DBResultSet SQL = SQL_Query(gH_Db, sQuery);
	
	if(SQL != null) {
		if(SQL_FetchRow(SQL)) {
			CloseHandle(SQL);
			return true;
		}
	}
	
	CloseHandle(SQL);
	return false;
}

/**
* Adds a user to the database
*
* @param client			The client to add
* @error				Invalid client or database connection issues
*/
stock void SQL_AddUserToBWTable(int client) {
	char sQuery[255];
	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	Format(sQuery, sizeof(sQuery), "INSERT INTO betterwarden_players (STEAMID) VALUES ('%s');", sSteamID);
	
	if(!SQL_FastQuery(gH_Db, sQuery)) {
		char err[255];
		SQL_GetError(gH_Db, err, sizeof(err));
		PrintToServer("DB Error: %s", err);
	}
	
}

/**
* Checks to see if the given gang exists already.
*
* @param name			Gang-name to look up
* @return				true if exists
*/
stock bool SQL_GangExists(char[] name) {
	char sQuery[255];
	
	Format(sQuery, sizeof(sQuery), "SELECT * FROM betterwarden_gangs WHERE Name LIKE '%s'", name);
	
	DBResultSet SQL = SQL_Query(gH_Db, sQuery);
	
	if(SQL != null) {
		if(SQL_FetchRow(SQL)) {
			CloseHandle(SQL);
			return true;
		}
	}
	
	CloseHandle(SQL);
	return false;
}

/**
* Creates a gang and registers it to the database
*
* @param client			Client that'll be set as owner
* @param name			Name of the gang
*/
stock void SQL_CreateGang(int client, char[] name) {
	char sQuery[255];
	char sID[64];
	GetClientAuthId(client, AuthId_Steam2, sID, sizeof(sID));
	
	Format(sQuery, sizeof(sQuery), "INSERT INTO betterwarden_gangs (Name, Owner) VALUES ('%s', '%s');", name, sID);
	
	if(!SQL_FastQuery(gH_Db, sQuery)) {
		char err[255];
		SQL_GetError(gH_Db, err, sizeof(err));
		PrintToServer("DB Error: %s", err);
	}
}

/**
* Checks if a user owns a gang or not
*
* @param client			Client entity index
* @return				true if yes
*/
stock bool SQL_OwnsGang(int client) {
	char sQuery[255];
	char sID[64];
	GetClientAuthId(client, AuthId_Steam2, sID, sizeof(sID));
	
	Format(sQuery, sizeof(sQuery), "SELECT * FROM betterwarden_gangs WHERE Owner LIKE '%s'", sID);
	
	DBResultSet SQL = SQL_Query(gH_Db, sQuery);
	if(SQL != null) {
		if(SQL_FetchRow(SQL)) {
			CloseHandle(SQL);
			return true;
		}
	}
	
	CloseHandle(SQL);
	return false;
}

/**
* Retrieves the gang name of the specified client
* 
* @param client			Client entity index
* @param buffer			Destination string to store the name
* @param maxlen			Max length of the destination buffer
* @error				Not in a gang or invalid client
*/
stock void SQL_GetGang(int client, char[] buffer, int maxlen) {
	int GangID;
	char sQuery[255];
	char sID[64];
	GetClientAuthId(client, AuthId_Steam2, sID, sizeof(sID));
	
	// Stage one
	Format(sQuery, sizeof(sQuery), "SELECT GangID FROM betterwarden_players WHERE STEAMID LIKE '%s'", sID);
	
	DBResultSet SQL = SQL_Query(gH_Db, sQuery);
	if(SQL != null) {
		if(SQL_FetchRow(SQL)) {
			GangID = SQL_FetchInt(SQL, 0);
			CloseHandle(SQL);
		}
	}
	
	// Stage two
	Format(sQuery, sizeof(sQuery), "SELECT Name FROM betterwarden_gangs WHERE ID LIKE %d", GangID);
	DBResultSet SQL2 = SQL_Query(gH_Db, sQuery);
	if(SQL2 != null) {
		if(SQL_FetchRow(SQL2)) {
			char result[255];
			SQL_FetchString(SQL2, 0, result, sizeof(result));
			CloseHandle(SQL2);
			
			Format(buffer, maxlen, "%s", result);
		}
	}
}

/**
* Checks if a client is in a gang
*
* @param client			Client entity index
* @return				true if yes
*/
stock bool SQL_IsInGang(int client) {
	char sQuery[255];
	char sID[64];
	GetClientAuthId(client, AuthId_Steam2, sID, sizeof(sID));
	
	Format(sQuery, sizeof(sQuery), "SELECT GangID FROM betterwarden_players WHERE STEAMID LIKE '%s'", sID);
	
	DBResultSet SQL = SQL_Query(gH_Db, sQuery);
	if(SQL != null) {
		if(SQL_FetchRow(SQL)) {
			CloseHandle(SQL);
			return true;
		}
	}
	
	return false;
}

public SharedPlugin __pl_bwgangs = 
{
	name = "gangs",
	file = "gangs.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
#if !defined REQUIRE_PLUGIN
public void __pl_bwgangs_SetNTVOptional()
{
	//MarkNativeAsOptional("initZombie");
}
#endif