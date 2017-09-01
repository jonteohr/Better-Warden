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

#pragma semicolon 1
#pragma newdecls required

char wardenMaterials[] = {
	"materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vmt",
	"materials/models/player/kuristaja/jailbreak/shared/police_body_d.vmt",
	"materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vmt",
	"materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vmt",
	"materials/models/player/kuristaja/jailbreak/shared/brown_eye_normal.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/police_body_d.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/police_body_normal.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/prisoner1_body_normal.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vtf",
	"materials/models/player/kuristaja/jailbreak/shared/tex_0086_1.vtf",
	"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d.vmt",
	"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d2.vmt",
	"materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_d.vmt",
	"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_d.vtf",
	"materials/models/player/kuristaja/jailbreak/guard1/hair01_ao_normal.vtf",
	"materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_d.vtf",
	"materials/models/player/kuristaja/jailbreak/guard1/sewell01_head01_au_normal.vtf"
};

char wardenModels[] = {
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.dx90.vtx",
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl",
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.phy",
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1.vvd",
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.dx90.vtx",
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl",
	"models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.vvd"
};

char wardenModelFile[] = "models/player/custom_player/kuristaja/jailbreak/guard1/guard1.mdl";
char wardenArmFile[] = "models/player/custom_player/kuristaja/jailbreak/guard1/guard1_arms.mdl";

ConVar g_wardenModel;

public Plugin myinfo = {
	name = "[BetterWarden] Player Models",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://trinityplay.net"
};

public void OnPluginStart() {
	AutoExecConfig(true, "models", "BetterWarden/Add-Ons");
	
	g_wardenModel = CreateConVar("sm_warden_model", "1", "Enable or disable the warden getting a player model.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public void OnMapStart() {
	if(g_wardenModel.IntValue == 1) {
		for(int i = 0; i < sizeof(wardenMaterials); i++) // Make sure to add every material to downloads-table!
			AddFileToDownloadsTable(wardenMaterials[i]);
		for(int i = 0; i < sizeof(wardenModels); i++) // Model files to download
			AddFileToDownloadsTable(wardenModels[i]);
		
		PrecacheModel(wardenModelFile); // Only need to precache the .mdl files
		PrecacheModel(wardenArmFile);
	}
}

public void OnWardenCreated(int client) {
	if(IsValidClient(client) && g_wardenModel.IntValue == 1) {
		SetEntityModel(client, wardenModelFile); // Set the warden .mdl model file
		SetEntPropString(client, Prop_Send, "m_szArmsModel", wardenArmFile); // Sets the warden arms model
	}
}