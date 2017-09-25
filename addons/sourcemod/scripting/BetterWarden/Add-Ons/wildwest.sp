/*
 * Better Warden - Wild West
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
#include <betterwarden>
#include <wardenmenu>
#include <colorvariables>
#include <smlib>
#include <BetterWarden/wildwest>
#include <autoexecconfig>

// Misc variables
bool g_bIsWWActive;

// ConVars
ConVar gc_sWeaponUsed;
ConVar gc_bInfAmmo;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[BetterWarden] Wild West",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("initWW", Native_initWW);
	RegPluginLibrary("bwwildwest"); // Register plugin library so main plugin can check if this is running or not!
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.WildWest.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
	
	gc_bInfAmmo = FindConVar("sv_infinite_ammo"); // This will be changed to 2 when it starts and reset to the value in server.cfg when game ends
	
	AutoExecConfig_SetFile("wildwest", "BetterWarden/Add-Ons");
	AutoExecConfig_SetCreateFile(true);
	gc_sWeaponUsed = AutoExecConfig_CreateConVar("sm_betterwarden_wildwest_weapon", "weapon_revolver", "What weapon is supposed to be used?\nUse the entity names.", FCVAR_NOTIFY);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}


public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) { // Post-event cleaning
	if(g_bIsWWActive == true) {
		g_bIsWWActive = false;
		g_bIsGameActive = false;
		ResetConVar(gc_bInfAmmo);
	}
}

public void StartWW() { // Start the actual event
	char buff[128];
	GetConVarString(gc_sWeaponUsed, buff, sizeof(buff));
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		GivePlayerItem(i, buff);
	}
	AddToBWLog("Wild West was initiated.");
	g_bIsWWActive = true;
	SetConVarInt(gc_bInfAmmo, 2);
}

public Action FiveSecTimer(Handle timer) { // Timer for the countdown til the event starts
	static int sec = 6;
	
	if(sec == 1) {
		CPrintToChatAll("%s %t", g_sPrefix, "Wild West Begun");
		StartWW();
		sec = 6; // Reset for possible next rounds
		return Plugin_Stop;
	}
	
	sec--;
	CPrintToChatAll("%s %t", g_sPrefix, "Countdown", sec);
	return Plugin_Continue;
}


/***********************
* When a player drops a weapon, make that weapon
* only pickup-able to that same player!
***********************/
public void WeaponDropPost(int client, int weapon) { // When player drops a weapon
	if(g_bIsWWActive == true) {
		if(weapon != -1)
			SetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity", client); // Register that weapon's owner as the client
	}
}

public Action WeaponCanUse(int client, int weapon) { // When player tries to pickup weapon
	if(g_bIsWWActive == false)
		return Plugin_Continue;
	
	if(GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity") == client)
		return Plugin_Continue;
		
	return Plugin_Handled;
}

/****************
*    NATIVES
****************/
public int Native_initWW(Handle plugin, int numParams) { // Called to actually start the game
	if(g_bIsWWActive == false) {
		g_bIsGameActive = true;
		CreateTimer(1.0, FiveSecTimer, _, TIMER_REPEAT);
		
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			Client_RemoveAllWeapons(i);
			SDKHook(i, SDKHook_WeaponDropPost, WeaponDropPost);
			SDKHook(i, SDKHook_WeaponCanUse, WeaponCanUse);
		}
		
		return true;
	}
	
	return false;
}