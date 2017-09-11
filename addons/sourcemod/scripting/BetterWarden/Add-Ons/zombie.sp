/*
 * Better Warden - Player Models
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
#include <sdkhooks>
#include <sdktools>
#include <betterwarden>
#include <wardenmenu>
#include <colorvariables>
#include <cstrike>
#include <smlib>
#include <emitsoundany>

// Compiler options
#pragma semicolon 1
#pragma newdecls required

// Booleans
bool g_bIsZombieActive;

// Integers
int g_iCTs[MAXPLAYERS + 1];

// ConVars
ConVar gc_bSwapBack;
ConVar gc_iZombieHealth;

public Plugin myinfo = {
	name = "[BetterWarden] Zombie",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("initZombie", Native_initZombie);
	RegPluginLibrary("bwzombie"); // Register plugin library so main plugin can check if this is running or not!
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.Zombie.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true, "zombie", "BetterWarden/Add-Ons");
	gc_bSwapBack = CreateConVar("sm_warden_zombie_swapback", "1", "In the round after a zombie round, swap back the CT's, that were infected, to Counter-Terrorists?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iZombieHealth = CreateConVar("sm_warden_zombie_health", "2000", "How much max-health should zombies have?", FCVAR_NOTIFY);
}

public void OnMapStart() {
	// Materials
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/classic/zombie_classic_sheet.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/classic/zombie_classic_sheet.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/classic/zombie_classic_sheet_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_eye.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_hairflat.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_hairflat2.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_head.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_jacket.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_pants.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_shirt.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_teeth.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zp_sv1_shoe.vmt");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_eye.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_eyeglow.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_hairflat.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_head.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_head_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_jacket.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_jacket_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_pants.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_pants_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_shirt.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_shirt_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zombie2_teeth.vtf");
	AddFileToDownloadsTable("materials/models/player/kuristaja/zombies/zpz/zp_sv1_shoe.vtf");
	// Models
	AddFileToDownloadsTable("models/player/kuristaja/zombies/classic/classic.dx90.vtx");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/classic/classic.mdl");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/classic/classic.phy");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/classic/classic.vvd");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/zpz/zpz.dx90.vtx");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/zpz/zpz.mdl");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/zpz/zpz.phy");
	AddFileToDownloadsTable("models/player/kuristaja/zombies/zpz/zpz.vvd");
	// Arms
	AddFileToDownloadsTable("models/player/custom_player/legacy/zombie/zombie_arms.mdl");
	AddFileToDownloadsTable("models/player/custom_player/legacy/zombie/zombie_arms.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/legacy/zombie/zombie_arms.vvd");
	// Sounds
	AddFileToDownloadsTable("sound/betterwarden/zombie.mp3");
	AddFileToDownloadsTable("sound/betterwarden/became_zombie.mp3");
	
	// Precache necessary files
	PrecacheModel("models/player/custom_player/legacy/zombie/zombie_arms.mdl", true);
	PrecacheModel("models/player/kuristaja/zombies/classic/classic.mdl", true);
	PrecacheModel("models/player/kuristaja/zombies/zpz/zpz.mdl", true);
	PrecacheSoundAny("betterwarden/zombie.mp3", true);
	PrecacheSoundAny("betterwarden/became_zombie.mp3", true);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client) && GetClientTeam(client) == CS_TEAM_T && g_bIsZombieActive) { // Support respawns
		SetClientZombie(client);
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	if(g_bIsZombieActive) {
		g_bIsZombieActive = false;
		g_bIsGameActive = false;
	}
	
	if(gc_bSwapBack.IntValue == 1) { // Swap back CTs that became infected
		for(int i = 1; i <= MaxClients; i++) {
			if(!IsValidClient(i))
				continue;
			if(g_iCTs[i] == 1 && GetClientTeam(i) != CS_TEAM_CT)
				CS_SwitchTeam(i, CS_TEAM_CT);
			g_iCTs[i] = 0; // Reset
		}
	}
}

public Action OnWeaponCanUse(int client, int weapon) {
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(!g_bIsZombieActive)
		return Plugin_Continue;
	if(GetClientTeam(client) != CS_TEAM_T)
		return Plugin_Continue;
	
	return Plugin_Handled; // Deny zombies picking up weapons!
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if(!IsValidClient(victim) || !IsValidClient(inflictor))
		return Plugin_Continue;
	if(!g_bIsZombieActive) // Make sure zombie is active!
		return Plugin_Continue;
	
	if(GetClientTeam(victim) == CS_TEAM_CT && GetClientTeam(inflictor) == CS_TEAM_T) { // Zombie infects CT
		if(gc_bSwapBack.IntValue == 1) {
			g_iCTs[victim] = 1;
		}
		CS_SwitchTeam(victim, CS_TEAM_T);
		SetClientZombie(victim);
		EmitSoundToClientAny(victim, "betterwarden/became_warden.mp3");
		CPrintToChatAll("%s %t", g_sPrefix, "Zombie Infected", inflictor, victim);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*********************
		NATIVES
*********************/
public int Native_initZombie(Handle plugin, int numParams) {
	if(g_bIsZombieActive)
		return false;
	
	g_bIsZombieActive = true;
	g_bIsGameActive = true;
	
	SetZombies();
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
	
	EmitSoundToAllAny("betterwarden/zombie.mp3");
	
	return true;
}

public void SetZombies() {
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		if(GetClientTeam(i) == CS_TEAM_T) { // Make all T's zombies
			SetClientZombie(i);
		}
		if(GetClientTeam(i) == CS_TEAM_CT) { // Give CT's correct equipment
			
		}
	}
}

public void SetClientZombie(int client) {
	int zombieSkin = GetRandomInt(1, 2);
	
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/legacy/zombie/zombie_arms.mdl"); // Set zombie arms
	
	if(zombieSkin == 1) {
		SetEntityModel(client, "models/player/kuristaja/zombies/zpz/zpz.mdl"); // Set the zombie skin
	}
	if(zombieSkin == 2) {
		SetEntityModel(client, "models/player/kuristaja/zombies/classic/classic.mdl"); // Set the zombie skin
	}
	
	Client_RemoveAllWeapons(client);
	GivePlayerItem(client, "weapon_knife");
	SetEntityHealth(client, gc_iZombieHealth.IntValue);
}