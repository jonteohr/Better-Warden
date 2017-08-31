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

bool IsWWActive;
int WeaponOwner[2048];
ConVar infAmmo;

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
	
	RegPluginLibrary("wildwest");
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.WildWest.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
	
	infAmmo = FindConVar("sv_infinite_ammo");
}

// Post-event cleaning
public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	if(IsWWActive == true) {
		IsWWActive = false;
		ResetConVar(infAmmo);
	}
}

// Start the actual event
public void StartWW() {
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		GivePlayerItem(i, "weapon_revolver");
	}
	IsWWActive = true;
	SetConVarInt(infAmmo, 2);
}

// Timer for the countdown til the event starts
public Action FiveSecTimer(Handle timer) {
	static int sec = 6;
	
	if(sec == 1) {
		CPrintToChatAll("%s %t", prefix, "Wild West Begun");
		StartWW();
		sec = 6; // Reset for possible next rounds
		return Plugin_Stop;
	}
	
	sec--;
	CPrintToChatAll("%s %t", prefix, "Countdown", sec);
	return Plugin_Continue;
}


/***********************
* When a player drops a weapon, make that weapon
* only pickup-able to that same player!
***********************/
public void WeaponDropPost(int client, int weapon) {
	if(IsWWActive == true)
		WeaponOwner[weapon] = client;
}

public Action WeaponCanUse(int client, int weapon) {
	if(IsWWActive == false)
		return Plugin_Continue;
	
	if(WeaponOwner[weapon] == client)
		return Plugin_Continue;
		
	return Plugin_Handled;
}

/****************
*    NATIVES
****************/
public int Native_initWW(Handle plugin, int numParams) {
	if(IsWWActive == false) {
		IsGameActive = true;
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