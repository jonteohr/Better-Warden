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

// Console Variables
ConVar gc_bTSide;
ConVar gc_bClanTag;
ConVar gc_bChatTag;
ConVar gc_fTagTimer;
ConVar gc_bGangChat;
ConVar gc_bOwnerInvite;

// Integers
int g_iInviteTime[MAXPLAYERS +1];
int g_iInviteGang[MAXPLAYERS +1];

public Plugin myinfo = {
	name = "[BetterWarden] Gangs",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("SendToGang", Native_SendToGang);
	CreateNative("CPrintToChatGang", Native_CPrintToChatGang);
	RegPluginLibrary("bwgangs"); // Register library so main plugin can check if this is loaded
	
	return APLRes_Success;
}

public void OnPluginStart() {
	// Translations
	LoadTranslations("BetterWarden.Gangs.phrases.txt");
	LoadTranslations("common.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	// Config
	AutoExecConfig_SetCreateDirectory(true);
	AutoExecConfig_SetFile("Gangs", "BetterWarden/Add-Ons");
	AutoExecConfig_SetCreateFile(true);
	gc_bTSide = AutoExecConfig_CreateConVar("sm_warden_gang_tside", "1", "Only allow Terrorists to use Gang-functions?\nThis is usually a good idea since CT can ghost via gang chat otherwise.\n1= Enable.\n0 = Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bGangChat = AutoExecConfig_CreateConVar("sm_warden_gang_chat", "1", "Enable private gang chat channels?\nThis is done by typing a % before the message in team-chat.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bChatTag = AutoExecConfig_CreateConVar("sm_warden_gang_chattag", "1", "Show the player's gang name in chat before the name.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bClanTag = AutoExecConfig_CreateConVar("sm_warden_gang_clantag", "1", "Show the player's gang name as a clan tag.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_fTagTimer = AutoExecConfig_CreateConVar("sm_warden_gang_clantag_timer", "15", "This only matters if sm_warden_gang_clantag is set to 1!\nThe amount of seconds the plugin should check a clients tag.\nYou only really need to modify this if you have another plugin conflicting.", FCVAR_NOTIFY, true, 0.1);
	gc_bOwnerInvite = AutoExecConfig_CreateConVar("sm_warden_gang_ownerinvite", "1", "Only allow the owner to invite other players to the gang?\n1 = Only owner can invite.\n0 = Every member can invite.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	// Database
	SQL_InitDB(); // Try to initiate database connection
	
	// Commands
	RegConsoleCmd("sm_gang", Command_Gang);
	RegConsoleCmd("sm_mygang", Command_MyGang);
	RegConsoleCmd("sm_accept", Command_AcceptInvite);
	RegConsoleCmd("sm_deny", Command_DenyInvite);
	
	// Command Listeners
	AddCommandListener(OnPlayerChat, "say");
	AddCommandListener(OnPlayerTeamChat, "say_team");
}

////////////////////////////////////
//			Forwards
////////////////////////////////////

public void OnMapStart() {
	if(gc_bClanTag.IntValue == 1)
		CreateTimer(gc_fTagTimer.FloatValue, ClanTagTimer, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd() {
	delete gH_Db; // Close the connection between mapchanges
}

public void OnClientPutInServer(int client) {
	if(!SQL_UserExists(client)) // If user is not in DB, add him without a gang
		SQL_AddUserToBWTable(client);
	
	if(SQL_IsInGang(client)) {
		char buff[255];
		SQL_GetGang(client, buff, sizeof(buff));
		
		SendToGang(SQL_GetGangId(buff), "%t", "Client Came Online", client);
	}
}

public Action OnPlayerChat(int client, char[] command, int args) {
	if(gc_bChatTag.IntValue != 1)
		return Plugin_Continue;
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(GetClientTeam(client) != CS_TEAM_T && GetClientTeam(client) != CS_TEAM_CT) // Only show to active players
		return Plugin_Continue;
	if(gc_bTSide.IntValue == 1 && GetClientTeam(client) != CS_TEAM_T) // Is client CT
		return Plugin_Continue;
	if(IsClientWarden(client)) // If client is warden, then warden tag should show
		return Plugin_Continue;
	if(!SQL_IsInGang(client)) // Make sure the client is actually in a gang
		return Plugin_Continue;
	
	char message[255];
	char gang[255];
	GetCmdArg(1, message, sizeof(message));
	SQL_GetGang(client, gang, sizeof(gang));
	
	if(message[0] == '/' || message[0] == '@' || IsChatTrigger())
		return Plugin_Handled;
	
	if(GetClientTeam(client) == CS_TEAM_CT)
		CPrintToChatAll("{green}[%s] {team2}%N :{default} %s", gang, client, message);
	if(GetClientTeam(client) == CS_TEAM_T)
		CPrintToChatAll("{green}[%s] {team1}%N :{default} %s", gang, client, message);
	
	return Plugin_Handled;
}

public Action OnPlayerTeamChat(int client, char[] command, int args) {
	if(gc_bGangChat.IntValue != 1)
		return Plugin_Continue;
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(GetClientTeam(client) != CS_TEAM_T && GetClientTeam(client) != CS_TEAM_CT)
		return Plugin_Continue;
	if(gc_bTSide.IntValue == 1 && GetClientTeam(client) != CS_TEAM_T)
		return Plugin_Continue;
	if(!SQL_IsInGang(client))
		return Plugin_Continue;
	
	char message[255];
	char gang[255];
	GetCmdArg(1, message, sizeof(message));
	SQL_GetGang(client, gang, sizeof(gang));
	
	if(message[0] != '%')
		return Plugin_Continue;
	
	char final[255];
	Format(final, sizeof(final), "%s", message);
	strcopy(final, sizeof(final), final[1]);
	
	CPrintToChatGang(client, SQL_GetGangId(gang), final);
	
	return Plugin_Handled;
}

////////////////////////////////////
//			Timers
////////////////////////////////////

public Action ClanTagTimer(Handle timer) {
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i, _, true) || !SQL_IsInGang(i) || (gc_bTSide.IntValue == 1 && GetClientTeam(i) != CS_TEAM_T)) // Make sure client is actually in a gang and/or is valid
			continue;
		char buffer[255];
		char clanTag[255];
		
		SQL_GetGang(i, buffer, sizeof(buffer));
		Format(clanTag, sizeof(clanTag), "[%s]", buffer);
		
		CS_SetClientClanTag(i, clanTag);
	}
}

////////////////////////////////////
//			Commands
////////////////////////////////////

public Action Command_Gang(int client, int args) {
	if(!IsValidClient(client, _, true))
		return Plugin_Handled;
	if(gc_bTSide.IntValue == 1 && GetClientTeam(client) != CS_TEAM_T) {
		CPrintToChat(client, "%s {error}%t", g_sPrefix, "Only T");
		return Plugin_Handled;
	}
	
	if(args < 1) {
		CPrintToChat(client, "%s %t", g_sPrefix, "Available Commands");
		CPrintToChat(client, "%s    !gang create <name>", g_sPrefix);
		CPrintToChat(client, "%s    !gang del", g_sPrefix);
		CPrintToChat(client, "%s    !gang inv <player>", g_sPrefix);
		CPrintToChat(client, "%s    !gang kick <player>", g_sPrefix);
	} else if(args >= 1) {
		char arg[64]; // First argument
		char name[128]; // Gang name or player name
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, name, sizeof(name));
		
		if(StrEqual(arg, "create", false)) {
			if(args >= 2 && !StrEqual(name, " "))
				CreateGang(client, name);
			else
				CPrintToChat(client, "%s {error}%t", g_sPrefix, "No name specified");
		}
		if(StrEqual(arg, "del", false)) {
			DeleteGang(client);
		}
		if(StrEqual(arg, "inv", false)) {
			if(gc_bOwnerInvite.IntValue == 1)
				if(SQL_OwnsGang(client))
					InviteGang(client, name);
				else
					CPrintToChat(client, "%s {error}%t", g_sPrefix, "Not Owner");
			else
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
		CPrintToChat(client, "%s {error}%t", g_sPrefix, "Not In Gang");
		return Plugin_Handled;
	}
	
	char gang[128];
	SQL_GetGang(client, gang, sizeof(gang));
	
	CPrintToChat(client, "%s Gang: %s", g_sPrefix, gang);
	
	return Plugin_Handled;
}

public Action Command_AcceptInvite(int client, int args) {
	if(!IsValidClient(client, _, true))
		return Plugin_Handled;
	if(g_iInviteTime[client] < GetTime()) // Invite timed out
		return Plugin_Handled;
	
	g_iInviteTime[client] = -1;
	SQL_AddToGang(client, g_iInviteGang[client]);
	
	SendToGang(g_iInviteGang[client], "%t", "Announce Client Joined Gang", client);
	CPrintToChat(client, "%s %t", g_sPrefix, "Invite Accepted");
	
	return Plugin_Handled;
}

public Action Command_DenyInvite(int client, int args) {
	if(!IsValidClient(client, _, true))
		return Plugin_Handled;
	if(g_iInviteTime[client] < GetTime()) // Invite timed out
		return Plugin_Handled;
	
	CPrintToChat(client, "%s %t", g_sPrefix, "You Declined Invite");
	
	if(SQL_GetGangOwner(g_iInviteGang[client]) != -1)
		CPrintToChat(g_iInviteGang[client], "%s {error}%t", g_sPrefix, "Invite Declined", client);
	
	g_iInviteTime[client] = -1;
	g_iInviteGang[client] = -1;
	
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
		CPrintToChat(client, "%s {error}%t", g_sPrefix, "Gang Create Error", name);
	}
}

public void DeleteGang(int client) { // Deletes gangs
	if(SQL_OwnsGang(client)) {
		int gangID = SQL_GetGangIdFromOwner(client);
		
		char gang[255];
		SQL_GetGang(client, gang, sizeof(gang));
		
		if(SQL_DeleteGang(gangID)) {
			CPrintToChat(client, "%s %t", g_sPrefix, "Success Delete Gang", gang); // Success!
		} else {
			CPrintToChat(client, "%s {error}%t", g_sPrefix, "Failed Delete Gang", gang);
		}
		
	} else {
		CPrintToChat(client, "%s {error}%t", g_sPrefix, "Not Owner"); // Not the owner
	}
}

public void InviteGang(int client, char[] arg) { // Invites a client to the given gang
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	int iGang = -1;
	char sGang[255];
	
	if((target_count = ProcessTargetString(arg, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
	}
	
	for(int usr = 1; usr <= target_count; usr++) { // target_list[usr] is now the target entity index
		if(!IsValidClient(target_list[usr], _, true)) {
			CPrintToChat(client, "%s {error}%t", g_sPrefix, "Could Not Find Target", target_list[usr]);
			break;
		}
		if(target_list[usr] == client) { // Make sure target is not the client
			CPrintToChat(client, "%s {error}%t", g_sPrefix, "Cannot Invite Self");
			break;
		}
		if(!SQL_IsInGang(client)) {
			CPrintToChat(client, "%s {error}%t", g_sPrefix, "Not In Gang");
		} else {
			SQL_GetGang(client, sGang, sizeof(sGang));
			iGang = SQL_GetGangId(sGang);
			
			if(!SQL_IsInGang(target_list[usr])) { // Target is not in a gang, let's send the invite!
				
				g_iInviteTime[target_list[usr]] = (GetTime() + 30);
				g_iInviteGang[target_list[usr]] = iGang;
				CPrintToChat(target_list[usr], "%s {gold}%t", g_sPrefix, "Invitation", client, sGang);
				
			} else { // Target is already in a gang
				CPrintToChat(client, "%s {error}%t", g_sPrefix, "Already In Gang", target_list[usr]);
				break;
			}
		}
	}
}

public void KickGang(int client, char[] arg) { // Kicks a client from their gang
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	int GangID = -1;
	char sGang[255];
	
	if((target_count = ProcessTargetString(arg, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
	}
	
	for(int usr = 1; usr <= target_count; usr++) {
		if(target_list[usr] == client) { // Make sure target is not the client
			CPrintToChat(client, "%s {error}%t", g_sPrefix, "Cannot Kick Self");
			break;
		}
		
		if(!SQL_OwnsGang(client)) {
			CPrintToChat(client, "%s {error}%t", g_sPrefix, "Could not Kick", target_list[usr]);
		} else {
			
			SQL_GetGang(target_list[usr], sGang, sizeof(sGang));
			GangID = SQL_GetGangId(sGang);
			
			if(SQL_GetGangIdFromOwner(client) == GangID) { // Gang match! Let's kick the target
				SQL_KickFromGang(target_list[usr]);
				CPrintToChat(client, "%s %t", g_sPrefix, "Kicked Client", target_list[usr], sGang); // Tell the owner about the success
				CPrintToChat(target_list[usr], "%s %t", g_sPrefix, "You Have Been Kicked", client, sGang); // Let the target know he was kicked
				
				SendToGang(GangID, "%t", sGang, "Announce Kick", target_list[usr]); // Announce in gangchat
				
			} else { // Target not in same gang
				CPrintToChat(client, "%s {error}%t", g_sPrefix, "Client Not in Gang", target_list[usr]);
				break;
			}
			
		}
	}
}

////////////////////////////////////
//			Natives
////////////////////////////////////
public int Native_SendToGang(Handle plugin, int numParams) {
	int iGang = GetNativeCell(1);
	char sBuffer[1024];
	int written;
	FormatNativeString(1, 2, 3, sizeof(sBuffer), written, sBuffer);
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i, _, true))
			continue;
			
		char sGang[255];
		SQL_GetGang(i, sGang, sizeof(sGang));
		
		if(iGang != SQL_GetGangId(sGang))
			continue;
		
		CPrintToChat(i, "{green}(%s) {yellow} %s", sGang, sBuffer);
	}
	
	return true;
}

public int Native_CPrintToChatGang(Handle plugin, int numParams) {
	int sender = GetNativeCell(1);
	int iGang = GetNativeCell(2);
	char sBuffer[1024];
	int written;
	FormatNativeString(2, 3, 4, sizeof(sBuffer), written, sBuffer);
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i, _, true))
			continue;
			
		char sGang[255];
		SQL_GetGang(i, sGang, sizeof(sGang));
		
		if(iGang != SQL_GetGangId(sGang))
			continue;
		
		CPrintToChat(i, "{green}(%s) %N :{default} %s", sGang, sender, sBuffer);
	}
	
	return true;
}