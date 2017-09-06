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

// Compiler options
#pragma semicolon 1
#pragma newdecls required

ConVar g_WardenModel;

char previousModel[256];
char prevArms[256];

public Plugin myinfo = {
	name = "[BetterWarden] Player Models",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://trinityplay.net"
};

public void OnPluginStart() {
	AutoExecConfig(true, "models", "BetterWarden/Add-Ons");
	
	g_WardenModel = CreateConVar("sm_warden_model", "1", "Enable or disable the warden getting a player model.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public void OnMapStart() {
	if(g_WardenModel.IntValue == 1) { // Only need to download the files if the model is enabled in config!
		// Material files
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
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"); // Only need to precache the .mdl files
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl");
	}
}

public void OnWardenCreated(int client) { // When warden is created, set the models!
	if(g_WardenModel.IntValue == 1) {
		GetEntPropString(client, Prop_Data, "m_ModelName", previousModel, sizeof(previousModel)); // Get the "standard" model that CTs use
		GetEntPropString(client, Prop_Send, "m_szArmsModel", prevArms, sizeof(prevArms));
		
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"); // Set the warden .mdl model file
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl"); // Sets the warden arms model
	}
}

public void OnWardenCreatedByAdmin(int admin, int client) {
	if(g_WardenModel.IntValue == 1) {
		GetEntPropString(client, Prop_Data, "m_ModelName", previousModel, sizeof(previousModel)); // Get the "standard" model that CTs use
		GetEntPropString(client, Prop_Send, "m_szArmsModel", prevArms, sizeof(prevArms));
		
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl"); // Set the warden .mdl model file
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl"); // Sets the warden arms model
	}
}

public void OnWardenRemoved(int client) {
	if(g_WardenModel.IntValue == 1) {
		SetEntityModel(client, previousModel); // Reset the model
		SetEntPropString(client, Prop_Send, "m_szArmsModel", prevArms);
	}
}