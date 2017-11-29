/*
 * Better Warden - Gangs
 * By: Hypr
 * https://github.com/condolent/BetterWarden/
 * 
 * Copyright (C) 2017 Jonathan Öhrström (Hypr/Condolent)
 *
 * This file is part of the BetterWarden SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <betterwarden>
#include <wardenmenu>
#include <colorvariables>
#include <smlib>
#include <BetterWarden/gangs>
#include <autoexecconfig>

// Compiler options
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[BetterWarden] Gangs",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("bwgangs"); // Register library so main plugin can check if this is loaded
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.Gangs.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig_SetFile("Gangs", "BetterWarden/Add-Ons");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	SQL_InitDB(); // Try to initiate database connection
	
	RegConsoleCmd("sm_gang", Command_Gang); // Base command
	RegConsoleCmd("sm_mygang", Command_MyGang);
}

public void OnMapEnd() {
	delete gH_Db; // Close the connection between mapchanges
}

public void OnClientPutInServer(int client) {
	if(!SQL_UserExists(client)) // If user is not in DB, add him without a gang
		SQL_AddUserToBWTable(client);
}

////////////////////////////////////
//			Commands
////////////////////////////////////

public Action Command_Gang(int client, int args) {
	if(!IsValidClient(client, _, true))
		return Plugin_Handled;
	
	if(args < 1) {
		CPrintToChat(client, "%s %t", g_sPrefix, "Available Commands");
		CPrintToChat(client, "%s !gang create <name>", g_sPrefix);
		CPrintToChat(client, "%s !gang del", g_sPrefix);
		CPrintToChat(client, "%s !gang inv <player>", g_sPrefix);
		CPrintToChat(client, "%s !gang kick <player>", g_sPrefix);
	} else if(args >= 1) {
		char arg[64]; // First argument
		char name[128]; // Gang name or player name
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, name, sizeof(name));
		
		if(StrEqual(arg, "create", false)) {
			CreateGang(client, name);
		}
		if(StrEqual(arg, "del", false)) {
			DeleteGang(client);
		}
		if(StrEqual(arg, "inv", false)) {
			InviteGang(client, name);
		}
		if(StrEqual(arg, "kick", false)) {
			KickGang(client, name);
		}
		
	}
	
	return Plugin_Handled;
}

public Action Command_MyGang(int client, int args) {
	if(!IsValidClient(client, _, true))
		return Plugin_Handled;
	if(!SQL_IsInGang(client)) {
		CPrintToChat(client, "%s You're not in a gang.", g_sPrefix);
		return Plugin_Handled;
	}
	
	char gang[128];
	SQL_GetGang(client, gang, sizeof(gang));
	
	CPrintToChat(client, "%s Gang: %s", g_sPrefix, gang);
	
	return Plugin_Handled;
}

////////////////////////////////////
//			Functions
////////////////////////////////////
public void CreateGang(int client, char[] name) { // Creates gangs
	if(!SQL_GangExists(name) && !SQL_IsInGang(client)) { // User is not in a gang and gang name is not taken
		SQL_CreateGang(client, name);
		CPrintToChat(client, "%s %t", g_sPrefix, "Success Create Gang", name);
	} else {
		CPrintToChat(client, "%s %t", g_sPrefix, "Gang Create Error", name);
	}
}

public void DeleteGang(int client) { // Deletes gangs
	if(SQL_OwnsGang(client)) {
		/*
			TODO
		*/
	} else {
		CPrintToChat(client, "%s This command is not currently finished.", g_sPrefix); // Not the owner
	}
}

public void InviteGang(int client, char[] arg) { // Invites a client to the given gang
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
	}
	
	for(int usr = 0; usr < target_count; usr++) { // target_list[usr] is now the target entity index
		if(!SQL_OwnsGang(client)) {
			CPrintToChat(client, "%s %t", g_sPrefix, "Could not Invite", target_list[usr]);
			CPrintToChat(client, "%s This command is not currently finished.", g_sPrefix);
		} else {
			/*
				TODO
			*/
		}
	}
}

public void KickGang(int client, char[] arg) { // Kicks a client from their gang
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
	}
	
	for(int usr = 0; usr < target_count; usr++) {
		if(!SQL_OwnsGang(client)) {
			CPrintToChat(client, "%s %t", g_sPrefix, "Could not Kick", target_list[usr]);
			CPrintToChat(client, "%s This command is not currently finished.", g_sPrefix);
		} else {
			/*
				TODO
			*/
		}
	}
}