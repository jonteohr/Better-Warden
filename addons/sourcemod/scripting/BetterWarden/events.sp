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
	g_iAliveCT = 0;
	g_iTotalCT = 0;
	g_iAliveTerrorists = 0;
	g_iTotalTerrorists = 0;
	
	g_iTotalCT = GetTeamClientCount(CS_TEAM_CT);
	g_iTotalTerrorists = GetTeamClientCount(CS_TEAM_T);
	
	RemoveWarden();
	
	AddFileToDownloadsTable("sound/betterwarden/newwarden.mp3");
	AddFileToDownloadsTable("sound/betterwarden/wardendead.mp3");
	
	if(gc_bWardenIcon.IntValue == 1) {
		PrecacheModelAnyDownload(g_sWardenIconPath);
	}
	
	if(gc_bWardenDeathSound.IntValue == 1) {
		PrecacheSoundAny("betterwarden/wardendead.mp3", true);
	}
	
	if(gc_bWardenCreatedSound.IntValue == 1) {
		PrecacheSoundAny("betterwarden/newwarden.mp3", true);
	}
}

public void OnJoinTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client, false, true)) {
		g_iTotalCT = GetTeamClientCount(CS_TEAM_CT);
		g_iAliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
		g_iTotalTerrorists = GetTeamClientCount(CS_TEAM_T);
		g_iAliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iAliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	g_iAliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	if(IsClientWarden(client)) {
		if(gc_bWardenDeathSound.IntValue == 1)
			EmitSoundToAllAny("betterwarden/wardendead.mp3");
		
		
		RemoveWarden();
		CPrintToChatAll("%s %t", g_sPrefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDeath);
		Call_PushCell(client);
		Call_Finish();
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(WardenExists())
		RemoveWarden();
		
	g_iAliveCT = 0;
	g_iAliveTerrorists = 0;
	
	g_iTotalCT = GetTeamClientCount(CS_TEAM_CT);
	g_iTotalTerrorists = GetTeamClientCount(CS_TEAM_T);
	g_iAliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	g_iAliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	gc_bNoblock.RestoreDefault(true, false);
	
	g_iNoLR = 0;
}

public void OnClientDisconnect(int client) {
	
	g_iTotalCT = GetTeamClientCount(CS_TEAM_CT);
	g_iTotalTerrorists = GetTeamClientCount(CS_TEAM_T);
	g_iAliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	g_iAliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", g_sPrefix, "Warden Died");
		AddToBWLog("%N disconnected while being warden. Removed warden.", client);
		
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

public Action OnPlayerLR(int client, char[] command, int args) {
	if(gc_bNoLR.IntValue != 1)
		return Plugin_Continue;
	if(g_iNoLR == 0)
		return Plugin_Continue;
		
	CPrintToChat(client, "%s %t", g_sPrefix, "No LR Allowed");
	return Plugin_Handled;
}