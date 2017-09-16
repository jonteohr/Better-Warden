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
#include <sdktools>
#include <betterwarden>
#include <cstrike>
#include <autoexecconfig>

// Compiler options
#pragma semicolon 1
#pragma newdecls required

ConVar gc_bWardenModel;
ConVar gc_bDeputyModel;

char g_sPreviousModel[256];
char g_sPrevArms[256];

public Plugin myinfo = {
	name = "[BetterWarden] Player Models",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("bwmodels"); // Register plugin library so main plugin can check if this is running or not!
	
	return APLRes_Success;
}

public void OnPluginStart() {
	AutoExecConfig_SetFile("models", "BetterWarden/Add-Ons"); // Create a addon-specific config!
	AutoExecConfig_SetCreateFile(true);
	gc_bWardenModel = AutoExecConfig_CreateConVar("sm_warden_model", "1", "Enable or disable the warden getting a player model.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bDeputyModel = AutoExecConfig_CreateConVar("sm_warden_deputy_model", "0", "Give the other CT's a fitting model aswell?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
}

public void OnMapStart() {
	if(gc_bWardenModel.IntValue == 1 || gc_bDeputyModel.IntValue == 1) { // If one of the models are enabled, make sure to download the shared mats.
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/police_body_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/brown_eye_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/police_body_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/police_body_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/prisoner1_body_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/tex_0086_1.vtf");
	}
	if(gc_bWardenModel.IntValue == 1) { // Only need to download the files if the model is enabled in config!
		// Material files
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d2.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_normal.vtf");
		// Model Files
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1.phy");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1.vvd");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.vvd");
		
		// Precache models
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl", true); // Only need to precache the .mdl files
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl", true);
	}
	
	if(gc_bDeputyModel.IntValue == 1) { // Only need to download the files if the model is enabled in config!
		// Material files
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_head_a6_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_hs_body_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_hs_head_d.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_head_a6_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_head_a6_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_hs_body_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_hs_body_normal.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_hs_head_d.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard5/guard_hs_head_normal.vtf");
		//Model Files
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5.mdl");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5.phy");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5.vvd");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.mdl");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.vvd");
		
		// Precache models
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard5/guard5.mdl", true);
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.mdl", true);
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetClientTeam(client) == CS_TEAM_CT && IsValidClient(client) && gc_bDeputyModel.IntValue == 1) {
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard5/guard5.mdl"); // Set the deputy skin
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.mdl");
	}
}

public void OnWardenCreated(int client) { // When warden is created, set the models!
	if(gc_bWardenModel.IntValue == 1) {
		GetEntPropString(client, Prop_Data, "m_ModelName", g_sPreviousModel, sizeof(g_sPreviousModel)); // Get the "standard" model that CTs use
		GetEntPropString(client, Prop_Send, "m_szArmsModel", g_sPrevArms, sizeof(g_sPrevArms));
		
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"); // Set the warden .mdl model file
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl"); // Sets the warden arms model
	}
}

public void OnWardenCreatedByAdmin(int admin, int client) { // Make sure to also set the model if it's not a voluntary warden
	if(gc_bWardenModel.IntValue == 1) {
		GetEntPropString(client, Prop_Data, "m_ModelName", g_sPreviousModel, sizeof(g_sPreviousModel)); // Get the "standard" model that CTs use
		GetEntPropString(client, Prop_Send, "m_szArmsModel", g_sPrevArms, sizeof(g_sPrevArms));
		
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"); // Set the warden .mdl model file
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl"); // Sets the warden arms model
	}
}

public void OnWardenRemoved(int client) { // Make sure to reset the model when the warden no longer is a warden!
	if(gc_bWardenModel.IntValue == 1) {
		SetEntityModel(client, g_sPreviousModel); // Reset the model
		SetEntPropString(client, Prop_Send, "m_szArmsModel", g_sPrevArms);
	}
}