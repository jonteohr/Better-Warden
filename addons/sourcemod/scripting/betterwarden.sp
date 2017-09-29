/*
 * Better Warden
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
#include <colorvariables>
#include <betterwarden>
#include <wardenmenu>
#include <emitsoundany>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <updater>
#include <smartjaildoors>
#define REQUIRE_PLUGIN

#define BW_UPDATE_URL "http://updater.ecoround.se/betterwarden/updater.txt"
#define SERVERTAG "BetterWarden, Better Warden"

#pragma semicolon 1
#pragma newdecls required

// Strings
char g_sCurWardenStat[MAX_NAME_LENGTH];
char g_sWardenIconPath[256];

// Integers
int g_iCurWarden = -1;
int g_iPrevWarden = -1;
int g_iAliveCT = 0;
int g_iAliveTerrorists = 0;
int g_iTotalCT = 0;
int g_iTotalTerrorists = 0;
int g_iIcon[MAXPLAYERS +1] = {-1, ...};
int g_iNoLR = 0;

// Forward handles
Handle gF_OnWardenDeath = null;
Handle gF_OnWardenDisconnect = null;
Handle gF_OnWardenRetire = null;
Handle gF_OnAdminRemoveWarden = null;
Handle gF_OnWardenCreated = null;
Handle gF_OnWardenCreatedByAdmin = null;
Handle gF_OnWardenRemoved = null;

// Regular ConVars
ConVar gc_bEnableNoblock;
ConVar gc_bNoblock;
ConVar gc_sAdmFlag;
ConVar gc_bOpenCells;
ConVar gc_bWardenTwice;
ConVar gc_bStatsHint;
ConVar gc_iColorR;
ConVar gc_iColorG;
ConVar gc_iColorB;
ConVar gc_bWardenIcon;
ConVar gc_sWardenIconPath;
ConVar gc_bWardenDeathSound;
ConVar gc_bWardenCreatedSound;
ConVar gc_bLogging;
ConVar gc_bNoLR;
ConVar gc_bServerTag;

// Modules
#include "BetterWarden/commands.sp"
#include "BetterWarden/actions.sp"
#include "BetterWarden/events.sp"

public Plugin myinfo = {
	name = "[CS:GO] Better Warden",
	author = "Hypr",
	description = "A better, more advanced warden plugin for jailbreak.",
	version = VERSION,
	url = "https://condolent.xyz"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Game is not supported. CS:GO ONLY");
	}
	
	CreateNative("IsClientWarden", Native_IsClientWarden);
	CreateNative("WardenExists", Native_WardenExists);
	CreateNative("SetWarden", Native_SetWarden);
	CreateNative("RemoveWarden", Native_RemoveWarden);
	CreateNative("GetCurrentWarden", Native_GetCurrentWarden);
	CreateNative("GetTeamAliveClientCount", Native_GetTeamAliveClientCount);
	CreateNative("IsClientWardenAdmin", Native_IsClientWardenAdmin);
	CreateNative("AddToBWLog", Native_AddToBWLog);
	RegPluginLibrary("betterwarden");
	
	// Global forwards
	gF_OnWardenDeath = CreateGlobalForward("OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnect = CreateGlobalForward("OnWardenDisconnect", ET_Ignore, Param_Cell);
	gF_OnWardenRetire = CreateGlobalForward("OnWardenRetire", ET_Ignore, Param_Cell);
	gF_OnAdminRemoveWarden = CreateGlobalForward("OnAdminRemoveWarden", ET_Ignore, Param_Cell, Param_Cell);
	gF_OnWardenCreated = CreateGlobalForward("OnWardenCreated", ET_Ignore, Param_Cell);
	gF_OnWardenCreatedByAdmin = CreateGlobalForward("OnWardenCreatedByAdmin", ET_Ignore, Param_Cell, Param_Cell);
	gF_OnWardenRemoved = CreateGlobalForward("OnWardenRemoved", ET_Ignore, Param_Cell);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	
	// CVars
	AutoExecConfig_SetFile("warden", "BetterWarden"); // What's the configs name and location?
	AutoExecConfig_SetCreateFile(true); // Create config if it does not exist
	AutoExecConfig_CreateConVar("sm_warden_version", VERSION, "Current version of this plugin. DO NOT CHANGE THIS!", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	gc_sAdmFlag = AutoExecConfig_CreateConVar("sm_warden_admin", "b", "The flag required to execute admin commands for this plugin.", FCVAR_NOTIFY);
	gc_bLogging = AutoExecConfig_CreateConVar("sm_warden_logs", "0", "Do you want the plugin to write logs?\nGenerally only necessary when you're experiencing any sort of issue.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bEnableNoblock = AutoExecConfig_CreateConVar("sm_warden_noblock", "1", "Give the warden the ability to toggle noblock via sm_noblock?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bOpenCells = AutoExecConfig_CreateConVar("sm_warden_cellscmd", "1", "Give the warden ability to toggle cell-doors via sm_open?\nCell doors on every map needs to be setup with SmartJailDoors for this to work!\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bWardenTwice = AutoExecConfig_CreateConVar("sm_warden_same_twice", "0", "Prevent the same warden from becoming warden next round instantly?\nThis should only be used on populated servers for obvious reasons.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bStatsHint = AutoExecConfig_CreateConVar("sm_warden_stats", "1", "Have a hint message up during the round with information about who's warden, how many players there are etc.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iColorR = AutoExecConfig_CreateConVar("sm_warden_color_R", "33", "The Red value of the color the warden gets.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	gc_iColorG = AutoExecConfig_CreateConVar("sm_warden_color_G", "114", "The Green value of the color the warden gets.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	gc_iColorB = AutoExecConfig_CreateConVar("sm_warden_color_B", "255", "The Blue value of the color the warden gets.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	gc_bWardenIcon = AutoExecConfig_CreateConVar("sm_warden_icon", "1", "Have an icon above the wardens' head?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_sWardenIconPath = AutoExecConfig_CreateConVar("sm_warden_icon_path", "decals/BetterWarden/warden", "The path to the icon. Do not include file extensions!\nThe path here should be from whithin the materials/ folder.", FCVAR_NOTIFY);
	gc_bWardenDeathSound = AutoExecConfig_CreateConVar("sm_warden_deathsound", "1", "Play a sound telling everyone the warden has died?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bWardenCreatedSound = AutoExecConfig_CreateConVar("sm_warden_createsound", "1", "Play a sound to everyone when someone becomes warden\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bNoLR = AutoExecConfig_CreateConVar("sm_warden_nolr", "1", "Allow warden to control if terrorists can do a !lastrequest or !lr when available?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bServerTag = AutoExecConfig_CreateConVar("sm_warden_servertag", "1", "Add Better Warden tags to your servers sv_tags?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile(); // Execute the config
	AutoExecConfig_CleanFile(); // Clean the .cfg from spaces etc.
	
	// Translation stuff
	LoadTranslations("BetterWarden.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	// Regular Commands
	RegConsoleCmd("sm_w", Command_Warden);
	RegConsoleCmd("sm_warden", Command_Warden);
	RegConsoleCmd("sm_c", Command_Warden);
	RegConsoleCmd("sm_rw", Command_Retire);
	RegConsoleCmd("sm_retire", Command_Retire);
	if(gc_bOpenCells.IntValue == 1)
		RegConsoleCmd("sm_open", Command_OpenCells);
	if(gc_bEnableNoblock.IntValue == 1)
		RegConsoleCmd("sm_noblock", Command_Noblock);
	if(gc_bNoLR.IntValue == 1)
		RegConsoleCmd("sm_nolr", Command_NoLR);
	
	// Admin Commands
	RegConsoleCmd("sm_uw", Command_Unwarden);
	RegConsoleCmd("sm_unwarden", Command_Unwarden);
	RegConsoleCmd("sm_sw", Command_SetWarden);
	RegConsoleCmd("sm_setwarden", Command_SetWarden);
	
	// Server Commands
	RegServerCmd("sm_reloadbw", Command_ReloadPlugin);
	
	// Event Hooks
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_team", OnJoinTeam);
	
	// Command listeners
	AddCommandListener(OnPlayerChat, "say");
	AddCommandListener(OnPlayerLR, "sm_lr");
	AddCommandListener(OnPlayerLR, "sm_lastrequest");
	
	// Timers
	if(gc_bStatsHint.IntValue == 1)
		CreateTimer(0.1, JBToolTip, _, TIMER_REPEAT);
	
	// Fetch CVars
	gc_bNoblock = FindConVar("mp_solid_teammates");
	gc_sWardenIconPath.GetString(g_sWardenIconPath, sizeof(g_sWardenIconPath));
	
	// Updater
	if(LibraryExists("updater")) {
		Updater_AddPlugin(BW_UPDATE_URL);
		Updater_ForceUpdate();
	}
	
	if(gc_bServerTag.IntValue == 1) {
		ConVar gc_sTags = FindConVar("sv_tags");
		char sTags[128];
		
		GetConVarString(gc_sTags, sTags, sizeof(sTags));
		
		if(StrContains(sTags, SERVERTAG, false) == -1) {
			char murderTag[64];
			Format(murderTag, sizeof(murderTag), ", %s", SERVERTAG);
			
			StrCat(sTags, sizeof(sTags), murderTag);
			SetConVarString(gc_sTags, sTags);
		}
	}
	
}

public void OnLibraryAdded(const char[] name) {
	// Updater
	if(StrEqual(name, "updater")) {
		Updater_AddPlugin(BW_UPDATE_URL);
		Updater_ForceUpdate();
	}
}

public void OnAllPluginsLoaded() {
	int addons;
	
	if(LibraryExists("bwwildwest"))
		addons++;
	if(LibraryExists("bwcatch"))
		addons++;
	if(LibraryExists("bwzombie"))
		addons++;
	if(LibraryExists("bwmodels"))
		addons++;
	if(LibraryExists("bwvoteday"))
		addons++;
	
	PrintToServer("");
	PrintToServer("#### BETTERWARDEN LOADED SUCCESSFULLY WITH %d ADDONS! ####", addons);
	PrintToServer("");
	AddToBWLog("Betterwarden loaded successfully with %d addons!", addons);
}

/////////////////////////////
//		   FORWARDS		   //
/////////////////////////////

public void CreateIcon(int client) {
	if(!IsValidClient(client) || !IsClientWarden(client))
		return;
	
	if(gc_bWardenIcon.IntValue != 1)
		return;
	
	RemoveIcon(client);
	
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	
	g_iIcon[client] = CreateEntityByName("env_sprite");
	
	if (!g_iIcon[client]) 
		return;
	
	char iconbuffer[256];
	
	Format(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", g_sWardenIconPath);
	
	DispatchKeyValue(g_iIcon[client], "model", iconbuffer);
	DispatchKeyValue(g_iIcon[client], "classname", "env_sprite");
	DispatchKeyValue(g_iIcon[client], "spawnflags", "1");
	DispatchKeyValue(g_iIcon[client], "scale", "0.3");
	DispatchKeyValue(g_iIcon[client], "rendermode", "1");
	DispatchKeyValue(g_iIcon[client], "rendercolor", "255 255 255");
	DispatchSpawn(g_iIcon[client]);
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] = origin[2] + 90.0;
	
	TeleportEntity(g_iIcon[client], origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(g_iIcon[client], "SetParent", g_iIcon[client], g_iIcon[client], 0);
	
	SDKHook(g_iIcon[client], SDKHook_SetTransmit, Should_TransmitW);
}

public void RemoveIcon(int client) {
	if(g_iIcon[client] > 0 && IsValidEdict(g_iIcon[client])) {
		AcceptEntityInput(g_iIcon[client], "Kill");
		g_iIcon[client] = -1;
		AddToBWLog("Removed icon from warden %N", client);
	}
}




/////////////////////////////
//			NATIVES		   //
/////////////////////////////
public int Native_GetTeamAliveClientCount(Handle plugin, int numParams) {
	int team = GetNativeCell(1);
	int count = 0;
	
	for(int client = 1; client <= MaxClients; client++) {
		if(!IsValidClient(client))
			continue;
			
		if(GetClientTeam(client) == team)
			count++;
	}
	
	return count;
}

public int Native_IsClientWarden(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(g_iCurWarden == client)
		return true;
	
	return false;
}
public int Native_WardenExists(Handle plugin, int numParams) {
	if(g_iCurWarden != -1) {
		return true;
	}
	
	return false;
}
public int Native_SetWarden(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	g_iCurWarden = client;
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	g_sCurWardenStat = name;
	CreateTimer(1.0, RenderColor, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	CreateIcon(client);
	
	if(gc_bWardenCreatedSound.IntValue == 1)
		EmitSoundToAllAny("betterwarden/newwarden.mp3");
	
	AddToBWLog("%N was set as warden", client);
	
	return true;
}
public int Native_RemoveWarden(Handle plugin, int numParams) {
	if(!WardenExists())
		return false;
	
	Call_StartForward(gF_OnWardenRemoved);
	Call_PushCell(g_iCurWarden);
	Call_Finish();
	
	if(gc_bWardenTwice.IntValue == 1) {
		g_iPrevWarden = g_iCurWarden;
	}
	
	RemoveIcon(GetCurrentWarden());
	
	g_iCurWarden = -1;
	g_sCurWardenStat = "None..";
	
	AddToBWLog("The Warden was successfully removed");
	
	return true;
}
public int Native_GetCurrentWarden(Handle plugin, int numParams) {
	return g_iCurWarden;
}
public int Native_IsClientWardenAdmin(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	char admflag[32];
	GetConVarString(gc_sAdmFlag, admflag, sizeof(admflag));
	
	if(IsValidClient(client, false, true)) {
		if((GetUserFlagBits(client) & ReadFlagString(admflag) == ReadFlagString(admflag)) || GetUserFlagBits(client) & ADMFLAG_ROOT)
			return true;
	}
	
	return false;
}
public int Native_AddToBWLog(Handle plugin, int numParams) {
	
	if(gc_bLogging.IntValue == 1) {
		char sBuffer[1024];
		int written;
		FormatNativeString(0, 1, 2, sizeof(sBuffer), written, sBuffer);
		LogToFile(g_sLogPath, "%s", sBuffer);
		
		return true;
	}
	
	return false;
}