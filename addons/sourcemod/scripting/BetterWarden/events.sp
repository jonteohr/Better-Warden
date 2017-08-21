/*
 * BetterWarden - Events
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

/*
*
*	Forwards
*
*/
public void OnMapStart() {
	aliveCT = 0;
	totalCT = 0;
	aliveTerrorists = 0;
	totalTerrorists = 0;
	
	totalCT = GetTeamClientCount(CS_TEAM_CT);
	totalTerrorists = GetTeamClientCount(CS_TEAM_T);
	
	RemoveWarden();
	
	if(cv_wardenIcon.IntValue == 1) {
		PrecacheModelAnyDownload(WardenIconPath);
	}
}

public void OnJoinTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client, false, true)) {
		totalCT = GetTeamClientCount(CS_TEAM_CT);
		aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
		totalTerrorists = GetTeamClientCount(CS_TEAM_T);
		aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", prefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDeath);
		Call_PushCell(client);
		Call_Finish();
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(WardenExists())
		RemoveWarden();
		
	aliveCT = 0;
	aliveTerrorists = 0;
	
	totalCT = GetTeamClientCount(CS_TEAM_CT);
	totalTerrorists = GetTeamClientCount(CS_TEAM_T);
	aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	cv_noblock.RestoreDefault(true, false);
}

public void OnClientDisconnect(int client) {
	
	totalCT = GetTeamClientCount(CS_TEAM_CT);
	totalTerrorists = GetTeamClientCount(CS_TEAM_T);
	aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", prefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDisconnect);
		Call_PushCell(client);
		Call_Finish();
	}
	
}

/*
*
*	Actions
*
*/
public Action OnPlayerChat(int client, char[] command, int args) {
	if(!IsValidClient(client)) // Make sure warden isn't glitched and is in fact alive etc.
		return Plugin_Continue;
	if(!IsClientWarden(client)) // Client is warden; let's make the message cool!
		return Plugin_Continue;
	
	char message[255];
	GetCmdArg(1, message, sizeof(message));
	
	if(message[0] == '/' || message[0] == '@' || IsChatTrigger())
		return Plugin_Handled;
	
	CPrintToChatAll("{bluegrey}[Warden] {team2}%N :{default} %s", client, message);
	return Plugin_Handled;
	
}