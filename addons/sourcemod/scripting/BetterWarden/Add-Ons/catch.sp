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
#include <BetterWarden/catch>
#include <autoexecconfig>

#pragma semicolon 1
#pragma newdecls required

bool g_bIsCatchActive;

ConVar gc_bFreezeTime;

public Plugin myinfo = {
	name = "[BetterWarden] Catch",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("initCatch", Native_initCatch);
	RegPluginLibrary("bwcatch"); // Register library so main plugin can check if this is loaded
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.Catch.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig_SetFile("Catch", "BetterWarden/Add-Ons");
	AutoExecConfig_SetCreateFile(true);
	gc_bFreezeTime = AutoExecConfig_CreateConVar("sm_warden_catch_freezetime", "1", "Freeze all CT's for 5 seconds when game is started?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(g_bIsCatchActive == true) // If catch is still active for some reason
		g_bIsCatchActive = false;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if(g_bIsCatchActive == true) { // If catch is active
		int aliveT = GetTeamAliveClientCount(CS_TEAM_T);
		
		if(aliveT == 1) // If we have a winner
			EndCatch();
	}
}

public Action OnClientTouch(int client, int other) { // Client = The CT. other = the victim (T)
	if(g_bIsCatchActive == false) // Don't do anything if Catch ain't active
		return Plugin_Continue;
	if(!IsValidClient(client) || !IsValidClient(other)) // Make sure client !bot & alive
		return Plugin_Continue;
	
	if(GetClientTeam(client) != CS_TEAM_CT || GetClientTeam(other) != CS_TEAM_T) // No teamkilling and no CT's being killed
		return Plugin_Continue;
		
	ForcePlayerSuicide(other);
	CPrintToChatAll("%s %t", g_sPrefix, "Player Caught T", client, other);
	
	AddToBWLog("%N caught %N during catch.", client, other);
	
	return Plugin_Handled;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	
	if(g_bIsCatchActive == false) // Don't do anything if Catch ain't active
		return Plugin_Continue;
	
	if(!IsValidClient(inflictor) || !IsValidClient(victim))
		return Plugin_Continue;
	
	CPrintToChat(inflictor, "%s {red}%t", g_sPrefix, "No Shooting in Catch");
	return Plugin_Handled;
}

public void EndCatch() { // End the whole game and choose a winner
	if(g_bIsCatchActive == true) {
		int winner;
		
		g_bIsCatchActive = false;
		g_bIsGameActive = false;
		
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			
			GivePlayerItem(i, "weapon_knife");
			
			if(GetClientTeam(i) == CS_TEAM_CT) {
				GivePlayerItem(i, "weapon_fiveseven");
				GivePlayerItem(i, "weapon_m4a1");
			}
			
			if(GetClientTeam(i) != CS_TEAM_T)
				continue;
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			winner = i;
			break;
		}
		
		CPrintToChatAll("%s %t", g_sPrefix, "Catch Over", winner);
		
	}
}

public Action OnClientCommand(int client, int args) { // If a client starts a Last Request during catch, deny it!
	char cmd[64];
	GetCmdArg(0, cmd, sizeof(cmd));
	
	if(g_bIsCatchActive == false)
		return Plugin_Continue;
	
	if((StrEqual(cmd, "sm_lr", false) != true) || (StrEqual(cmd, "sm_lastrequest", false) != true))
		return Plugin_Continue;
	
	CPrintToChat(client, "%s %t", g_sPrefix, "No LR During Catch");
	return Plugin_Handled;
}

public Action FreezeTimer(Handle timer) {
	static int secs = 5;
	
	if(secs == 0) {
		CPrintToChatAll("%s Catch has begun!", g_sPrefix);
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			if(GetClientTeam(i) != CS_TEAM_CT)
				continue;
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.5);
		}
		secs = 5;
		return Plugin_Stop;
	}
	
	CPrintToChatAll("%s Catch starts in %d seconds!", g_sPrefix, secs);
	secs--;
	return Plugin_Continue;
}

/****************
*    NATIVES
****************/
public int Native_initCatch(Handle plugin, int numParams) { // Called to start the game
	if(g_bIsCatchActive == true) {
		return false;
	}
	
	
	g_bIsCatchActive = true;
	g_bIsGameActive = true;
	CPrintToChatAll("%s %t", g_sPrefix, "Catch initiated");
	CPrintToChatTeam(CS_TEAM_CT, "%s %t", g_sPrefix, "Info CT");
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		Client_RemoveAllWeapons(i);
		SDKHook(i, SDKHook_Touch, OnClientTouch);
		SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	
	if(gc_bFreezeTime.IntValue != 0) {
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			if(GetClientTeam(i) != CS_TEAM_CT)
				continue;
			
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
		}
		CreateTimer(1.0, FreezeTimer, _, TIMER_REPEAT);
	}
	
	AddToBWLog("Catch was initiated!");
	
	return true;
}