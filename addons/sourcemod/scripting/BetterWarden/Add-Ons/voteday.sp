/*
 * Better Warden - Day Votes
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
#include <wardenmenu>
#include <cstrike>
#include <colorvariables>
#include <autoexecconfig>

// Optional plugins (Add-Ons)
#undef REQUIRE_PLUGIN
#include <BetterWarden/catch>
#include <BetterWarden/wildwest>
#include <BetterWarden/zombie>
#define REQUIRE_PLUGIN

// Compiler options
#pragma semicolon 1
#pragma newdecls required

#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"

bool g_bIsWWLoaded;
bool g_bIsCatchLoaded;
bool g_bIsZombieLoaded;

int g_iVoted[MAXPLAYERS + 1]; // 0 = Not Voted, 1 = Voted
int g_iVoteYes;
int g_iVoteNo;
int g_iGameVote = -1; // -1 = No vote active, 0 = War, 1 = HNS, 2 = grav, 3 = freeday, 4 = wildwest, 5 = zombie, 6 = catch
int g_iVoteRound;

ConVar gc_fVoteTime;
ConVar gc_bVoteCooldown;

public Plugin myinfo = {
	name = "[BetterWarden] Day Votes",
	author = "Hypr",
	description = "An Add-On for Better Warden.",
	version = VERSION,
	url = "https://github.com/condolent/Better-Warden"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("bwvoteday"); // Register plugin library so main plugin can check if this is running or not!
	
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("BetterWarden.Votes.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	RegConsoleCmd("sm_warday", Command_Warday);
	RegConsoleCmd("sm_hns", Command_HnS);
	RegConsoleCmd("sm_gravday", Command_Gravity);
	RegConsoleCmd("sm_freeday", Command_Freeday);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);
	
	AutoExecConfig_SetFile("voteday", "BetterWarden/Add-Ons");
	AutoExecConfig_SetCreateFile(true);
	gc_fVoteTime = AutoExecConfig_CreateConVar("sm_warden_vote_duration", "30.0", "The duration of event day votes.", FCVAR_NOTIFY, true, 1.0, true, 120.0);
	gc_bVoteCooldown = AutoExecConfig_CreateConVar("sm_warden_vote_spam", "1", "Prevent users from starting another vote after one has failed in the same round?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnAllPluginsLoaded() { // Handle late loads
	g_bIsCatchLoaded = LibraryExists("bwcatch");
	g_bIsZombieLoaded = LibraryExists("bwzombie");
	g_bIsWWLoaded = LibraryExists("bwwildwest");
	
	if(g_bIsWWLoaded) // Only enable this command if addon exists
		RegConsoleCmd("sm_west", Command_WildWest);
	if(g_bIsZombieLoaded) // Only enable this command if addon exists
		RegConsoleCmd("sm_zombie", Command_Zombie);
	if(g_bIsCatchLoaded) // Only enable this command if addon exists
		RegConsoleCmd("sm_catch", Command_Catch);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) { // Make sure to do a safety reset!
	for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
	g_iVoteYes = 0;
	g_iVoteNo = 0;
	g_iGameVote = -1;
	g_iVoteRound = 0;
}

public Action Command_WildWest(int client, int args) { // Vote for Wild West
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 4);
	
	return Plugin_Handled;
}

public Action Command_Zombie(int client, int args) { // Vote for Zombie
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 5);
	
	return Plugin_Handled;
}

public Action Command_Catch(int client, int args) { // Vote for Catch
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 6);
	
	return Plugin_Handled;
}

public Action Command_Warday(int client, int args) { // Vote for Warday
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 0);
	
	return Plugin_Handled;
}

public Action Command_HnS(int client, int args) { // Vote for HNS
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 1);
	
	return Plugin_Handled;
}

public Action Command_Gravity(int client, int args) { // Vote for Gravity Freeday
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 2);
	
	return Plugin_Handled;
}

public Action Command_Freeday(int client, int args) { // Vote for Freeday
	if(!IsValidVote(client))
		return Plugin_Handled;
	
	StartVote(client, 3);
	
	return Plugin_Handled;
}

/*************************************************
						MENU
*************************************************/
public void BWVoteMenu(int client) {
	Menu menu = new Menu(BWMenuHandler, MENU_ACTIONS_ALL);
	menu.AddItem(CHOICE1, "Yes");
	menu.AddItem(CHOICE2, "No");
	menu.Display(client, 30); // Remove the menu after 30 secs if client has not selected anything
}

public int BWMenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch(action) {
		case MenuAction_Start:{} // Displaying menu to client
		case MenuAction_Display:
		{
			char sTitle[255];
			if(g_iGameVote == 0)
				Format(sTitle, sizeof(sTitle), "%t", "Vote War");
			if(g_iGameVote == 1)
				Format(sTitle, sizeof(sTitle), "%t", "Vote HNS");
			if(g_iGameVote == 2)
				Format(sTitle, sizeof(sTitle), "%t", "Vote Grav");
			if(g_iGameVote == 3)
				Format(sTitle, sizeof(sTitle), "%t", "Vote Freeday");
			if(g_iGameVote == 4)
				Format(sTitle, sizeof(sTitle), "%t", "Vote WW");
			if(g_iGameVote == 5)
				Format(sTitle, sizeof(sTitle), "%t", "Vote Zombie");
			if(g_iGameVote == 6)
				Format(sTitle, sizeof(sTitle), "%t", "Vote Catch");
			
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(sTitle);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(StrEqual(info, CHOICE1)) {
				g_iVoteYes++;
				CPrintToChatAll("%s %t", g_sPrefix, "Client Voted Yes", client);
			}
			if(StrEqual(info, CHOICE2)) {
				g_iVoteNo++;
				CPrintToChatAll("%s %t", g_sPrefix, "Client Voted No", client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
			
			if(StrEqual(info, CHOICE1)) {
				return ITEMDRAW_DEFAULT;
			} else if(StrEqual(info, CHOICE2)) {
				return ITEMDRAW_DEFAULT;
			} else { 
				return style;
			}
		}
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			char display[64];
			
			if(StrEqual(info, CHOICE1)) {
				Format(display, sizeof(display), "%t", "Yes");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE2)) {
				Format(display, sizeof(display), "%t", "No");
				return RedrawMenuItem(display);
			}
		}
	}
	
	return 0;
}

/*************************************************
					NATIVES
*************************************************/
public bool IsValidVote(int client) {
	if(!IsValidClient(client))
		return false;
	if(!g_bAllowVotes && WardenExists()) {
		CPrintToChat(client, "%s %t", g_sPrefix, "Votes Not Allowed");
		return false;
	}
	if(g_bIsGameActive)
		return false;
	if(g_iGameVote != -1) {
		CPrintToChat(client, "%s %t", g_sPrefix, "Vote Already Active");
		return false;
	}
	if(gc_bVoteCooldown.IntValue == 1) {
		if(g_iVoteRound == 1) {
			return false;
		}
	}
	
	return true; // Success, let's go forward with the vote!
}

public void StartVote(int client, int game) {
	g_iGameVote = game;
	g_iVoted[client] = 1;
	g_iVoteYes++;
	g_iVoteRound = 1;
	CreateTimer(gc_fVoteTime.FloatValue, VoteTimer);
	CPrintToChat(client, "%s %t", g_sPrefix, "Vote Started");
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i))
			continue;
		if(i == client) // The voter has automatically said yes
			continue;
		BWVoteMenu(i);
	}
	AddToBWLog("%N started a vote.", client);
}

public bool VoteFinished() {
	if(g_iGameVote == 0) {
		if(g_iVoteYes > g_iVoteNo) {
			ExecWarday();
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	if(g_iGameVote == 1) {
		if(g_iVoteYes > g_iVoteNo) {
			int randomInt = GetRandomInt(1, 2); // Set the number of winners randomly
			ExecHnS(randomInt);
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	if(g_iGameVote == 2) {
		if(g_iVoteYes > g_iVoteNo) {
			ExecGravday();
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	if(g_iGameVote == 3) {
		if(g_iVoteYes > g_iVoteNo) {
			ExecFreeday();
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	if(g_iGameVote == 4) {
		if(g_iVoteYes > g_iVoteNo) {
			initWW();
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	if(g_iGameVote == 5) {
		if(g_iVoteYes > g_iVoteNo) {
			initZombie();
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	if(g_iGameVote == 6) {
		if(g_iVoteYes > g_iVoteNo) {
			initCatch();
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		} else {
			CPrintToChatAll("%s %t", g_sPrefix, "Voted Down");
			g_iGameVote = -1;
			for(int i = 0; i < sizeof(g_iVoted); i++) g_iVoted[i] = 0;
			return true;
		}
	}
	
	return false; // Something went wrong
}

public Action VoteTimer(Handle timer) {
	VoteFinished(); // This gets called after the timer's interval is run out
	return Plugin_Stop;
}