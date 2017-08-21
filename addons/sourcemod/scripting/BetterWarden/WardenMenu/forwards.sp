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
	
	aliveTs = GetTeamAliveClientCount(CS_TEAM_T);
		
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientWarden(client)) {
		abortGames();
	}
	
	aliveTs = GetTeamAliveClientCount(CS_TEAM_T);
	
	if(IsHnsActive()) {
		// Check if HnS should end
		if(hnsWinners == aliveTs) {
			abortGames();
			CPrintToChatAll("%s %t", cmenuPrefix, "HnS Over");
			
			Call_StartForward(gF_OnHnsOver);
			Call_Finish();
		} else {
			CPrintToChatAll("%s %t", cmenuPrefix, "HnS Players Left", aliveTs);
		}
	}
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	
	if(hnsActive == 1 && cvHnSGod.IntValue == 1) {
		if(IsValidClient(victim) && IsValidClient(inflictor) && GetClientTeam(victim) == CS_TEAM_CT && GetClientTeam(inflictor) == CS_TEAM_T) {
			CPrintToChat(inflictor, "%s %t", cmenuPrefix, "No Rebel HnS");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	abortGames();
	
	aliveTs = 0;
	aliveTs = GetTeamAliveClientCount(CS_TEAM_T);
	for(int client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client)) {
			if(ClientHasFreeday(client)) {
				RemoveClientFreeday(client);
			}
		}
	}
}

public void OnMapStart() {
	abortGames();
	
	hnsTimes = 0;
	freedayTimes = 0;
	warTimes = 0;
	gravTimes = 0;
	
	// Beacon stuff
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if (gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}
	
	if (GameConfGetKeyValue(gameConfig, "SoundBlip", g_BlipSound, sizeof(g_BlipSound)) && g_BlipSound[0])
	{
		PrecacheSound(g_BlipSound, true);
	}
	
	char buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
	{
		g_BeamSprite = PrecacheModel(buffer);
	}
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
	{
		g_HaloSprite = PrecacheModel(buffer);
	}
	
	delete gameConfig;
}

public void OnWardenCreated(int client) {
	CPrintToChat(client, "%s %t", cmenuPrefix, "Available to open menu");
	if(cvAutoOpen.IntValue == 1) {
		openMenu(client);
	} else {
		PrintToServer("Skipping auto open since it's disabled in config.");
	}
}

public void OnHnsOver() {
	PrintHintTextToAll("%t", "Small HNS Over");
}