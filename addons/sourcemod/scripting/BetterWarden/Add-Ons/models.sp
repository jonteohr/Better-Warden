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
ConVar gc_bPrisonerModel;

char g_sPreviousModel[256];
char g_sPrevArms[256];

char anarchistModelsT[][] = 
{
	"models/player/custom_player/legacy/tm_anarchist.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantA.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantB.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantC.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantD.mdl"
};

char balkanModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_balkan_variantA.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantB.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantC.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantD.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantE.mdl"
};

char leetModelsT[][] = 
{ 	
	"models/player/custom_player/legacy/tm_leet_variantA.mdl",
	"models/player/custom_player/legacy/tm_leet_variantB.mdl",
	"models/player/custom_player/legacy/tm_leet_variantC.mdl",
	"models/player/custom_player/legacy/tm_leet_variantD.mdl",
	"models/player/custom_player/legacy/tm_leet_variantE.mdl"
};

char phoenixModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_phoenix.mdl",
	"models/player/custom_player/legacy/tm_phoenix_heavy.mdl",	
	"models/player/custom_player/legacy/tm_phoenix_variantA.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantB.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantC.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantD.mdl"
};

char pirateModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_pirate.mdl",	
	"models/player/custom_player/legacy/tm_pirate_variantA.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantB.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantC.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantD.mdl"
};

char professionalModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_professional.mdl",	
	"models/player/custom_player/legacy/tm_professional_var1.mdl",
	"models/player/custom_player/legacy/tm_professional_var2.mdl",
	"models/player/custom_player/legacy/tm_professional_var3.mdl",
	"models/player/custom_player/legacy/tm_professional_var4.mdl"
};

char separatistModelsT[][] = 
{ 
	"models/player/custom_player/legacy/tm_separatist.mdl",	
	"models/player/custom_player/legacy/tm_separatist_variantA.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantB.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantC.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantD.mdl"
};

char fbiModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_fbi.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantA.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantB.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantC.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantD.mdl"
};

char gignModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_gign.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantA.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantB.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantC.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantD.mdl"	
};

char gsg9ModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_gsg9.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantA.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantB.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantC.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantD.mdl"	
};

char idfModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_idf.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantA.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantB.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantC.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantD.mdl",	
	"models/player/custom_player/legacy/ctm_idf_variantE.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantF.mdl"	
};

char sasModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_sas.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantA.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantB.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantC.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantD.mdl",	
	"models/player/custom_player/legacy/ctm_sas_variantE.mdl"	
};

char st6ModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_st6.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantA.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantB.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantC.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantD.mdl"
};

char swatModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_swat.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantA.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantB.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantC.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantD.mdl"
};

char AgentModelsT[][] = 
{
	"models/player/custom_player/legacy/tm_balkan_variantf.mdl",	
	"models/player/custom_player/legacy/tm_balkan_variantg.mdl",
	"models/player/custom_player/legacy/tm_balkan_varianth.mdl",
	"models/player/custom_player/legacy/tm_balkan_varianti.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantj.mdl",
	"models/player/custom_player/legacy/tm_leet_variantf.mdl",
	"models/player/custom_player/legacy/tm_leet_variantg.mdl",
	"models/player/custom_player/legacy/tm_leet_varianth.mdl",
	"models/player/custom_player/legacy/tm_leet_varianti.mdl",	
	"models/player/custom_player/legacy/tm_phoenix_variantf.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantg.mdl",
	"models/player/custom_player/legacy/tm_phoenix_varianth.mdl"
};

char AgentModelsCT[][] = 
{
	"models/player/custom_player/legacy/ctm_fbi_variante.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantf.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantg.mdl",
	"models/player/custom_player/legacy/ctm_fbi_varianth.mdl",
	"models/player/custom_player/legacy/ctm_st6_variante.mdl",	
	"models/player/custom_player/legacy/ctm_st6_variantg.mdl",
	"models/player/custom_player/legacy/ctm_st6_varianti.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantk.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantm.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantf.mdl"	
};

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
	AutoExecConfig_SetCreateDirectory(true);
	AutoExecConfig_SetFile("models", "BetterWarden/Add-Ons"); // Create a addon-specific config!
	AutoExecConfig_SetCreateFile(true);
	gc_bWardenModel = AutoExecConfig_CreateConVar("sm_warden_model", "1", "Enable or disable the warden getting a player model.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bDeputyModel = AutoExecConfig_CreateConVar("sm_warden_deputy_model", "0", "Give the other CT's a fitting model aswell?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bPrisonerModel = AutoExecConfig_CreateConVar("sm_warden_prisoner_model", "0", "Give all the T a prisoner model?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
}

public void OnMapStart() {
	if(gc_bWardenModel.IntValue == 1 || gc_bDeputyModel.IntValue == 1 || gc_bPrisonerModel.IntValue == 1) { // If one of the models are enabled, make sure to download the shared mats.
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
	
	if(gc_bPrisonerModel.IntValue == 1) { // Download the prisoner models!
		// Material files
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/eyes.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/gi_head_14.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/gi_head_14.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/gi_head_nml.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/m_white_13_co.vmt");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/m_white_13_co.vtf");
		AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/m_white_13_n.vtf");
		// Model files
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.phy");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.vvd");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.dx90.vtx");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.mdl");
		AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.vvd");
		
		// Precache models
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl");
		PrecacheModel("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.mdl");
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// We want to wait a bit before setting the actual player models
	CreateTimer(2.0, SetModel, client);
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

public Action SetModel(Handle timer, int client) {
	// We only want to set their model if they're using a default model
	// This way we can kind of support other custom model plugins
	char curModel[256];
	GetEntPropString(client, Prop_Data, "m_ModelName", curModel, sizeof(curModel));
	
	if(gc_bDeputyModel.IntValue == 1 || gc_bPrisonerModel.IntValue == 1) {
		if(IsDefaultModel(curModel)) {
			if(GetClientTeam(client) == CS_TEAM_CT && IsValidClient(client) && gc_bDeputyModel.IntValue == 1) { // Set the deputy skin
				SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard5/guard5.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard5/guard5_arms.mdl");
			}
			
			if(GetClientTeam(client) == CS_TEAM_T && IsValidClient(client) && gc_bPrisonerModel.IntValue == 1) { // Set the prisoner skin
				SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.mdl");
			}
		}
	}
}

public bool IsDefaultModel(char[] curModel) {
	int conflict = 0;
	
	for (int i = 0; i < sizeof(AgentModelsCT); i++) {
		if(StrEqual(curModel, AgentModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(AgentModelsT); i++) {
		if(StrEqual(curModel, AgentModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(swatModelsCT); i++) {
		if(StrEqual(curModel, swatModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(st6ModelsCT); i++) {
		if(StrEqual(curModel, st6ModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(sasModelsCT); i++) {
		if(StrEqual(curModel, sasModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(idfModelsCT); i++) {
		if(StrEqual(curModel, idfModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(gsg9ModelsCT); i++) {
		if(StrEqual(curModel, gsg9ModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(gignModelsCT); i++) {
		if(StrEqual(curModel, gignModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(fbiModelsCT); i++) {
		if(StrEqual(curModel, fbiModelsCT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(separatistModelsT); i++) {
		if(StrEqual(curModel, separatistModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(professionalModelsT); i++) {
		if(StrEqual(curModel, professionalModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(pirateModelsT); i++) {
		if(StrEqual(curModel, pirateModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(phoenixModelsT); i++) {
		if(StrEqual(curModel, phoenixModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(leetModelsT); i++) {
		if(StrEqual(curModel, leetModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(balkanModelsT); i++) {
		if(StrEqual(curModel, balkanModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	for (int i = 0; i < sizeof(anarchistModelsT); i++) {
		if(StrEqual(curModel, anarchistModelsT[i])) {
			conflict = 1;
			break;
		}
	}
	
	if(conflict == 1)
		return true;
	else
		return false;
}