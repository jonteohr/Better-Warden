/*
 * Better Warden - Catch
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

#pragma semicolon 1
#pragma newdecls required

bool IsCatchActive;

public Plugin myinfo = {
	name = "[BetterWarden] Catch",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("initCatch", Native_initCatch);
	
	RegPluginLibrary("catch");
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.Catch.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig(true, "Catch", "BetterWarden");
	
	HookEvent("player_death", OnPlayerDeath);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if(IsCatchActive == true) {
		int aliveT = GetTeamAliveClientCount(CS_TEAM_T);
		
		if(aliveT == 1)
			EndCatch();
	}
}

public Action OnClientTouch(int client, int other) {
	if(IsCatchActive == false)
		return Plugin_Continue;
	if(!IsValidClient(client) || !IsValidClient(other))
		return Plugin_Continue;
	
	if(GetClientTeam(client) != CS_TEAM_CT || GetClientTeam(other) != CS_TEAM_T)
		return Plugin_Continue;
		
	ForcePlayerSuicide(other);
	CPrintToChatAll("%s %t", prefix, "Player Caught T", client, other);
	
	return Plugin_Handled;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	
	if(IsCatchActive == false)
		return Plugin_Continue;
	
	if(!IsValidClient(inflictor) || !IsValidClient(victim))
		return Plugin_Continue;
	
	CPrintToChat(inflictor, "%s {red}%t", prefix, "No Shooting in Catch");
	return Plugin_Handled;
}

public void EndCatch() {
	if(IsCatchActive == true) {
		int winner;
		
		IsCatchActive = false;
		IsGameActive = false;
		
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			if(GetClientTeam(i) != CS_TEAM_T)
				continue;
			winner = i;
			break;
		}
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			
			GivePlayerItem(i, "weapon_knife");
			
			if(GetClientTeam(i) == CS_TEAM_CT) {
				GivePlayerItem(i, "weapon_fiveseven");
				GivePlayerItem(i, "weapon_m4a1");
			}
		}
		
		CPrintToChatAll("%s %t", prefix, "Catch Over", winner);
		
	}
}

/****************
*    NATIVES
****************/
public int Native_initCatch(Handle plugin, int numParams) {
	if(IsCatchActive == true) {
		return false;
	}
	
	IsCatchActive = true;
	CPrintToChatAll("%s %t", prefix, "Catch initiated");
	IsGameActive = true;
	CPrintToChatTeam(CS_TEAM_CT, "%s %t", prefix, "Info CT");
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		Client_RemoveAllWeapons(i);
		SDKHook(i, SDKHook_Touch, OnClientTouch);
		SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	
	return true;
}