/*
 * Warden Menu
 * By: Hypr
 * https://github.com/condolent/BetterWarden/
 * 
 * Copyright (C) 2020 Jonathan Öhrström (Hypr/Condolent)
 *
 * This file is part of the BetterWarden SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <menus>
#include <colorvariables>
#include <cstrike>
#include <wardenmenu>
#include <adminmenu>
#include <betterwarden>
#include <autoexecconfig>

// Optional plugins
#undef REQUIRE_PLUGIN
#include <BetterWarden/catch>
#include <BetterWarden/wildwest>
#include <BetterWarden/zombie>
#define REQUIRE_PLUGIN

#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"
#define CHOICE3 "#choice3"
#define CHOICE4 "#choice4"
#define CHOICE5 "#choice5"
#define CHOICE6 "#choice6"
#define CHOICE7 "#choice7"
#define CHOICE8 "#choice8"
#define CHOICE9 "#choice9"
#define SPACER "#spacer"
#define SEP "#sep"

// Add-On checks
bool g_bCatchLoaded;
bool g_bWWLoaded;
bool g_bZombieLoaded;
bool g_bVotesLoaded;

char g_sCMenuPrefix[] = "[{bluegrey}WardenMenu{default}] ";
char g_sBlipSound[PLATFORM_MAX_PATH];

// Current game
int g_iHnsActive = 0;
int g_iFreedayActive = 0;
int g_iWardayActive = 0;
int g_iGravActive = 0;

// Track number of games played
int g_iHnsTimes = 0;
int g_iFreedayTimes = 0;
int g_iWarTimes = 0;
int g_iGravTimes = 0;

// Misc
int g_iClientFreeday[MAXPLAYERS +1];
int g_iHnsWinners;
int g_iAliveTs;
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iPlayerBeacon[MAXPLAYERS + 1];

// ## CVars ##
ConVar gc_bAutoOpen;
ConVar gc_fBeaconRadius;
// Convars to add different menu entries
ConVar gc_bHnS;
ConVar gc_bHnSGod;
ConVar gc_iHnSTimes;
ConVar gc_bFreeday;
ConVar gc_iFreedayTimes;
ConVar gc_bWarday;
ConVar gc_iWardayTimes;
ConVar gc_bGrav;
ConVar gc_iGravTeam;
ConVar gc_fGravStrength;
ConVar gc_iGravTimes;
ConVar gc_bRestFreeday;
ConVar gc_bNoblock;
ConVar gc_bEnableWeapons;
ConVar gc_bEnablePlayerFreeday;
ConVar gc_bEnableDoors;

Handle gF_OnCMenuOpened = null;
Handle gF_OnEventDayCreated = null;
Handle gF_OnEventDayAborted = null;
Handle gF_OnHnsOver = null;

#include "BetterWarden/WardenMenu/commands.sp"
#include "BetterWarden/WardenMenu/menus.sp"
#include "BetterWarden/WardenMenu/forwards.sp"
#include "BetterWarden/WardenMenu/natives.sp"

public Plugin myinfo = {
	name = "[CS:GO] Warden Menu",
	author = "Hypr",
	description = "Gives wardens access to a special menu",
	version = VERSION,
	url = "https://condolent.xyz"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("IsEventDayActive", Native_IsEventDayActive);
	CreateNative("IsHnsActive", Native_IsHnsActive);
	CreateNative("IsGravFreedayActive", Native_IsGravFreedayActive);
	CreateNative("IsWarActive", Native_IsWarActive);
	CreateNative("IsFreedayActive", Native_IsFreedayActive);
	CreateNative("ClientHasFreeday", Native_ClientHasFreeday);
	CreateNative("GiveClientFreeday", Native_GiveClientFreeday);
	CreateNative("RemoveClientFreeday", Native_RemoveClientFreeday);
	CreateNative("SetClientBeacon", Native_SetClientBeacon);
	CreateNative("ExecWarday", Native_ExecWarday);
	CreateNative("ExecFreeday", Native_ExecFreeday);
	CreateNative("ExecHnS", Native_ExecHnS);
	CreateNative("ExecGravday", Native_ExecGravday);
	
	RegPluginLibrary("wardenmenu");
	
	return APLRes_Success;
}

public void OnPluginStart() {
	
	LoadTranslations("BetterWarden.Menu.phrases");
	LoadTranslations("BetterWarden.phrases.txt");
	LoadTranslations("BetterWarden.Catch.phrases.txt");
	LoadTranslations("BetterWarden.WildWest.phrases.txt");
	LoadTranslations("BetterWarden.Zombie.phrases.txt");
	LoadTranslations("BetterWarden.Votes.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig_SetFile("menu", "BetterWarden"); // What's the configs name and location?
	AutoExecConfig_SetCreateFile(true); // Create config if it does not exist
	gc_bHnS = AutoExecConfig_CreateConVar("sm_cmenu_hns", "1", "Add an option for Hide and Seek in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bHnSGod = AutoExecConfig_CreateConVar("sm_cmenu_hns_godmode", "1", "Makes CT's invulnerable against attacks from T's during HnS to prevent rebels.\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iHnSTimes = AutoExecConfig_CreateConVar("sm_cmenu_hns_rounds", "2", "How many times is HnS allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	gc_bFreeday = AutoExecConfig_CreateConVar("sm_cmenu_freeday", "1", "Add an option for a freeday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iFreedayTimes = AutoExecConfig_CreateConVar("sm_cmenu_freeday_rounds", "2", "How many times is a Freeday allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	gc_bWarday = AutoExecConfig_CreateConVar("sm_cmenu_warday", "1", "Add an option for Warday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iWardayTimes = AutoExecConfig_CreateConVar("sm_cmenu_warday_rounds", "1", "How many times is a Warday allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	gc_bGrav = AutoExecConfig_CreateConVar("sm_cmenu_gravity", "1", "Add an option for a gravity freeday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iGravTeam = AutoExecConfig_CreateConVar("sm_cmenu_gravity_team", "2", "Which team should get a special gravity on Gravity Freedays?\n0 = All teams.\n1 = Counter-Terrorists.\n2 = Terorrists.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	gc_fGravStrength = AutoExecConfig_CreateConVar("sm_cmenu_gravity_strength", "0.5", "What should the gravity be set to on Gravity Freedays?", FCVAR_NOTIFY);
	gc_iGravTimes = AutoExecConfig_CreateConVar("sm_cmenu_gravity_rounds", "1", "How many times is a Gravity Freeday allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	gc_bNoblock = AutoExecConfig_CreateConVar("sm_cmenu_noblock", "1", "sm_warden_noblock needs to be set to 1 for this to work!\nAdd an option for toggling noblock in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bAutoOpen = AutoExecConfig_CreateConVar("sm_cmenu_auto_open", "1", "Automatically open the menu when a user becomes warden?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bEnableWeapons = AutoExecConfig_CreateConVar("sm_cmenu_weapons", "1", "Add an option for giving the warden a list of weapons via the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bRestFreeday = AutoExecConfig_CreateConVar("sm_cmenu_restricted_freeday", "1", "Add an option for a restricted freeday in the menu?\nThis event uses the same configuration as a normal freeday.\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bEnablePlayerFreeday = AutoExecConfig_CreateConVar("sm_cmenu_player_freeday", "1", "Add an option for giving a specific player a freeday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bEnableDoors = AutoExecConfig_CreateConVar("sm_cmenu_doors", "1", "sm_warden_cellscmd needs to be set to 1 for this to work!\nAdd an option for opening doors via the menu.\n0 = Disable.\n1 = Enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile(); // Execute the config
	AutoExecConfig_CleanFile(); // Clean the .cfg from spaces etc.
	
	RegConsoleCmd("sm_abortgames", sm_abortgames);
	RegConsoleCmd("sm_cmenu", sm_cmenu);
	RegConsoleCmd("sm_wmenu", sm_cmenu);
	RegConsoleCmd("sm_days", sm_days);
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	for(int client = 1; client <= MaxClients; client++) {
		if(!IsValidClient(client, false, true)) 
			continue;
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	
	// Forwards
	gF_OnCMenuOpened = CreateGlobalForward("OnCMenuOpened", ET_Ignore, Param_Cell);
	gF_OnEventDayCreated = CreateGlobalForward("OnEventDayCreated", ET_Ignore);
	gF_OnEventDayAborted = CreateGlobalForward("OnEventDayAborted", ET_Ignore);
	gF_OnHnsOver = CreateGlobalForward("OnHnsOver", ET_Ignore);
	
}

public void OnAllPluginsLoaded() {
	gc_fBeaconRadius = FindConVar("sm_beacon_radius");
	
	g_bCatchLoaded = LibraryExists("bwcatch");
	g_bWWLoaded = LibraryExists("bwwildwest");
	g_bZombieLoaded = LibraryExists("bwzombie");
	g_bVotesLoaded = LibraryExists("bwvoteday");
}

public void abortGames() {
	if(g_bIsGameActive) {
		// Reset
		g_bIsGameActive = false;
		g_iHnsActive = 0;
		g_iWardayActive = 0;
		g_iFreedayActive = 0;
		g_iGravActive = 0;
		for(int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				SetEntityGravity(client, 1.0);
			}
		}
		
		Call_StartForward(gF_OnEventDayAborted);
		Call_Finish();
	} else {
		PrintToServer("%t", "Failed to abort Server");
	}
}

public Action HnSInfo(Handle timer) {
	if(!IsHnsActive())
		return Plugin_Handled;
	
	char msg1[64];
	Format(msg1, sizeof(msg1), "%t", "Contesters Left", g_iAliveTs);
	
	char msg2[64];
	Format(msg2, sizeof(msg2), "%t", "HnS Winners Info", g_iHnsWinners);
	
	PrintHintTextToAll("%s\n%s", msg1, msg2);
	
	return Plugin_Continue;
}

public void initRestFreeday(int client) {
	if(gc_iFreedayTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Rest Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Rest Freeday Begun");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Rest Freeday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iFreedayActive = 1;
		g_bIsGameActive = true;
		AddToBWLog("A Restricted Freeday was executed.");
	} else if(gc_iFreedayTimes.IntValue != 0 && g_iFreedayTimes >= gc_iFreedayTimes.IntValue) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Too many freedays", g_iFreedayTimes, gc_iFreedayTimes.IntValue);
	} else if(gc_iFreedayTimes.IntValue != 0 && g_iFreedayTimes < gc_iFreedayTimes.IntValue) {
		PrintHintTextToAll("%t", "Rest Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Rest Freeday Begun");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Rest Freeday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iFreedayActive = 1;
		g_bIsGameActive = true;
		g_iFreedayTimes++;
		AddToBWLog("A Restricted Freeday was executed.");
	}
}

public void error(int client, int errorCode) {
	if(errorCode == 0) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Not Warden");
	}
	if(errorCode == 1) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Not Alive");
	}
	if(errorCode == 2) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Client Not CT");
	}
}

public Action BeaconTimer(Handle timer, any client) {

	if(!IsValidClient(client))
		return Plugin_Stop;
		
	if(g_iPlayerBeacon[client] == 0)
		return Plugin_Stop;
	
	int beamColor[4] = {
		74,
		255,
		111,
		255
	};
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	if(g_iBeamSprite > -1 && g_iHaloSprite > -1) {
		
		TE_SetupBeamRingPoint(vec, 10.0, gc_fBeaconRadius.FloatValue, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, beamColor, 10, 0);
		TE_SendToAll();
		
	}
	if(g_sBlipSound[0]) {
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_sBlipSound, vec, client, SNDLEVEL_RAIDSIREN);
	}
	
	return Plugin_Continue;
}