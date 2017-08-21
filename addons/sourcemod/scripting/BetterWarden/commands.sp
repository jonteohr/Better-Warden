/*
 * BetterWarden - Commands
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

// sm_w || sm_warden
public Action Command_Warden(int client, int args) {
	
	if(!IsValidClient(client)) { // Client is not valid. IE not ingame, alive etc.
		CPrintToChat(client, "%s %t", prefix, "Invalid Client");
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) != CS_TEAM_CT) { // Client is not CT.
		CPrintToChat(client, "%s %t", prefix, "Client Not CT");
		return Plugin_Handled;
	}
	
	if(WardenExists()) { // Someone is already warden.
		CPrintToChat(client, "%s %t", prefix, "Warden Exists");
		return Plugin_Handled;
	}
	
	if(IsClientWarden(client)) { // Client is already warden.
		CPrintToChat(client, "%s %t", prefix, "Already Warden");
		return Plugin_Handled;
	}
	
	if(cv_wardenTwice.IntValue == 1) { // If enabled in config, the client is prevented to become warden since he was warden last round.
		if(client == prevWarden) {
			CPrintToChat(client, "%s %t", prefix, "Warden Twice");
			return Plugin_Handled;
		}
	}
	
	SetWarden(client);
	CPrintToChatAll("%s %t", prefix, "Warden Created", client);
	
	Call_StartForward(gF_OnWardenCreated);
	Call_PushCell(client);
	Call_Finish();
	
	return Plugin_Handled;
	
}

// sm_rw || sm_retire
public Action Command_Retire(int client, int args) {
	if(!IsValidClient(client, false, false)) {
		CPrintToChat(client, "%s %t", prefix, "Invalid Client");
		return Plugin_Handled;
	}
	
	if(!IsClientWarden(client)) {
		CPrintToChat(client, "%s %t", prefix, "Not Warden");
		return Plugin_Handled;
	}
	
	RemoveWarden();
	CPrintToChatAll("%s %t", prefix, "Warden Retired", client);
	
	Call_StartForward(gF_OnWardenRetire);
	Call_PushCell(client);
	Call_Finish();
	
	return Plugin_Handled;
}

// sm_noblock
public Action Command_Noblock(int client, int args) {
	if(!IsValidClient(client)) {
		CPrintToChat(client, "%s %t", prefix, "Invalid Client");
		return Plugin_Handled;
	}
	if(!IsClientWarden(client)) {
		CPrintToChat(client, "%s %t", prefix, "Not Warden");
		return Plugin_Handled;
	}
	
	if(cv_noblock.IntValue == 1) {
		CPrintToChatAll("%s %t", prefix, "Noblock on");
		SetConVarInt(cv_noblock, 0, true, false);
	} else if(cv_noblock.IntValue == 0) {
		CPrintToChatAll("%s %t", prefix, "Noblock off");
		SetConVarInt(cv_noblock, 1, true, false);
	}
	
	return Plugin_Handled;
}

// sm_open
public Action Command_OpenCells(int client, int args) {
	if(!IsValidClient(client, false, false)) {
		CPrintToChat(client, "%s %t", prefix, "Invalid Client");
		return Plugin_Handled;
	}
	if(!IsClientWarden(client)) {
		CPrintToChat(client, "%s %t", prefix, "Not Warden");
		return Plugin_Handled;
	}
	
	SJD_ToggleDoors();
	CPrintToChat(client, "%s %t", prefix, "Doors Opened");
	
	return Plugin_Handled;
}

// sm_uw || sm_unwarden
public Action Command_Unwarden(int client, int args) {
	if(!IsClientWardenAdmin(client)) {
		CReplyToCommand(client, "%s {red}%t", prefix, "Not Admin");
		return Plugin_Handled;
	}
	if(!WardenExists()) {
		CReplyToCommand(client, "%s %t", prefix, "No Warden Alive");
		return Plugin_Handled;
	}
	
	int warden = GetCurrentWarden();
	
	RemoveWarden();
	CPrintToChatAll("%s %t", prefix, "Warden Removed", warden);
	
	Call_StartForward(gF_OnAdminRemoveWarden);
	Call_PushCell(client); // The admin removing the warden
	Call_PushCell(warden); // The client forced to retire
	Call_Finish();
	
	return Plugin_Handled;
}

// sm_sw || sm_setwarden
public Action Command_SetWarden(int client, int args) {
	if(!IsClientWardenAdmin(client)) {
		CReplyToCommand(client, "%s {red}%t", prefix, "Not Admin");
		return Plugin_Handled;
	}
	if(!IsValidClient(client, false, true)) {
		CReplyToCommand(client, "%s %t", prefix, "Invalid Client");
		return Plugin_Handled;
	}
	if(WardenExists()) {
		CReplyToCommand(client, "%s %t", prefix, "Warden Exists");
		return Plugin_Handled;
	}
	if(args < 1) {
		CReplyToCommand(client, "[SM] Usage: sm_ip <#userid|name>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg, client, target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(int usr = 0; usr < target_count; usr++) {
		if(GetClientTeam(target_list[usr]) != CS_TEAM_CT) {
			CReplyToCommand(client, "%s %t", prefix, "Client must be CT");
			break;
		}
		SetWarden(target_list[usr]);
		CReplyToCommand(client, "%s %t", prefix, "Warden Set", target_list[usr]);
		
		Call_StartForward(gF_OnWardenCreatedByAdmin);
		Call_PushCell(client);
		Call_PushCell(target_list[usr]);
		Call_Finish();
	}
	
	return Plugin_Handled;
}