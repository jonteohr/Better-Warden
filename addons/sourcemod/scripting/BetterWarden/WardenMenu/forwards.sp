/*
 * WardenMenu - Forwards
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

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}
public void OnClientDisconnect(int client) {
	
	g_iAliveTs = GetTeamAliveClientCount(CS_TEAM_T);
		
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientWarden(client)) {
		abortGames();
	}
	
	g_iAliveTs = GetTeamAliveClientCount(CS_TEAM_T);
	
	if(IsHnsActive()) {
		// Check if HnS should end
		if(g_iHnsWinners == g_iAliveTs) {
			abortGames();
			CPrintToChatAll("%s %t", g_sCMenuPrefix, "HnS Over");
			AddToBWLog("Hide n' Seek is now over and there's a winner!");
			Call_StartForward(gF_OnHnsOver);
			Call_Finish();
		} else {
			CPrintToChatAll("%s %t", g_sCMenuPrefix, "HnS Players Left", g_iAliveTs);
			AddToBWLog("A Terrorist died during Hide n' Seek but there's still contenders left.");
		}
	}
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	
	if(g_iHnsActive == 1 && gc_bHnSGod.IntValue == 1) {
		if(IsValidClient(victim) && IsValidClient(inflictor) && GetClientTeam(victim) == CS_TEAM_CT && GetClientTeam(inflictor) == CS_TEAM_T) {
			CPrintToChat(inflictor, "%s %t", g_sCMenuPrefix, "No Rebel HnS");
			AddToBWLog("%N tried attacking %N but was denied since Hide n' Seek is active.", inflictor, victim);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	abortGames();
	
	g_bAllowVotes = false;
	
	g_iAliveTs = 0;
	g_iAliveTs = GetTeamAliveClientCount(CS_TEAM_T);
	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			if(ClientHasFreeday(i)) {
				RemoveClientFreeday(i);
				AddToBWLog("%N's freeday was removed since it's a new round.", i);
			}
		}
	}
}

public void OnMapStart() {
	abortGames();
	
	g_iHnsTimes = 0;
	g_iFreedayTimes = 0;
	g_iWarTimes = 0;
	g_iGravTimes = 0;
	
	// Beacon stuff
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if (gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}
	
	if (GameConfGetKeyValue(gameConfig, "SoundBlip", g_sBlipSound, sizeof(g_sBlipSound)) && g_sBlipSound[0])
	{
		PrecacheSound(g_sBlipSound, true);
	}
	
	char buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
	{
		g_iBeamSprite = PrecacheModel(buffer);
	}
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
	{
		g_iHaloSprite = PrecacheModel(buffer);
	}
	
	delete gameConfig;
}

public void OnWardenCreated(int client) {
	CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Available to open menu");
	if(gc_bAutoOpen.IntValue == 1) {
		openMenu(client);
	} else {
		AddToBWLog("Skipping auto open since it's disabled in config.");
	}
}

public void OnHnsOver() {
	PrintHintTextToAll("%t", "Small HNS Over");
}