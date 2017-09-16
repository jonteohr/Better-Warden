/*
 * WardenMenu - Commands
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

// sm_cmenu
public Action sm_cmenu(int client, int args) {
	
	if(!IsValidClient(client)) {
		error(client, 1);
		return Plugin_Handled;
	}
	
	if(GetClientTeam(client) != CS_TEAM_CT) {
		error(client, 2);
		return Plugin_Handled;
	}
	
	if(!IsClientWarden(client)) {
		error(client, 0);
		return Plugin_Handled;
	}
	
	openMenu(client);
	
	return Plugin_Handled;
}

// sm_abortgames
public Action sm_abortgames(int client, int args) {
	if(!IsClientWardenAdmin(client)) {
		CReplyToCommand(client, "%s {red}%t", g_sCMenuPrefix, "Not Admin");
		return Plugin_Handled;
	}
	if(!g_bIsGameActive) {
		CReplyToCommand(client, "%s %t", g_sCMenuPrefix, "Admin Abort Denied");
		return Plugin_Handled;
	}
	
	CPrintToChatAll("%s %t", g_sCMenuPrefix, "Admin Aborted", client);
	abortGames();
	
	AddToBWLog("An admin has stopped the current game.");
	
	return Plugin_Handled;
}

// sm_days
public Action sm_days(int client, int args) {
	
	if(!IsValidClient(client) && GetClientTeam(client) != CS_TEAM_CT) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Neither alive or ct");
		return Plugin_Handled;
	}
	
	if(!IsClientWarden(client)) {
		error(client, 0);
		return Plugin_Handled;
	}
	
	openDaysMenu(client);
	
	return Plugin_Handled;
}