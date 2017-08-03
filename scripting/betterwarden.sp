#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <colorvariables>
#include <betterwarden>
#include <cmenu>
#include <smartjaildoors>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.0"

char prefix[] = "[{blue}Warden{default}] ";
char curWardenStat[MAX_NAME_LENGTH];

int curWarden = -1;
int aliveCT;
int totalCT;
int aliveTerrorists;
int totalTerrorists;

// Forward handles
Handle gF_OnWardenDeath = null;
Handle gF_OnWardenDisconnect = null;
Handle gF_OnWardenRetire = null;
Handle gF_OnAdminRemoveWarden = null;
Handle gF_OnWardenCreated = null;

public Plugin myinfo = {
	name = "[CS:GO] Better Warden",
	author = "Hypr",
	description = "A better, more advanced warden plugin for jailbreak.",
	version = VERSION,
	url = "https://condolent.xyz"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("IsClientWarden", Native_IsClientWarden);
	CreateNative("WardenExists", Native_WardenExists);
	CreateNative("SetWarden", Native_SetWarden);
	CreateNative("RemoveWarden", Native_RemoveWarden);
	CreateNative("GetCurrentWarden", Native_GetCurrentWarden);
	RegPluginLibrary("betterwarden");
}

public void OnPluginStart() {
	// Translation stuff
	LoadTranslations("betterwarden.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	// Regular Commands
	RegConsoleCmd("sm_w", Command_Warden);
	RegConsoleCmd("sm_warden", Command_Warden);
	RegConsoleCmd("sm_c", Command_Warden);
	RegConsoleCmd("sm_rw", Command_Retire);
	RegConsoleCmd("sm_retire", Command_Retire);
	RegConsoleCmd("sm_open", Command_OpenCells);
	
	// Admin Commands
	RegAdminCmd("sm_uw", Command_Unwarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_unwarden", Command_Unwarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_sw", Command_SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setwarden", Command_SetWarden, ADMFLAG_GENERIC);
	
	// Global forwards
	gF_OnWardenDeath = CreateGlobalForward("OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnect = CreateGlobalForward("OnWardenDisconnect", ET_Ignore, Param_Cell);
	gF_OnWardenRetire = CreateGlobalForward("OnWardenRetire", ET_Ignore, Param_Cell);
	gF_OnAdminRemoveWarden = CreateGlobalForward("OnAdminRemoveWarden", ET_Ignore, Param_Cell, Param_Cell);
	gF_OnWardenCreated = CreateGlobalForward("OnWardenCreated", ET_Ignore, Param_Cell);
	
	// Event Hooks
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", OnJoinTeam);
	
	// Command listeners
	AddCommandListener(OnPlayerChat, "say");
	
	// Timers
	CreateTimer(0.1, JBToolTip, _, TIMER_REPEAT);
}

/////////////////////////////
//		   FORWARDS		   //
/////////////////////////////
public void OnMapStart() {
	aliveCT = 0;
	totalCT = 0;
	aliveTerrorists = 0;
	totalTerrorists = 0;
}

public void OnJoinTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int newTeam = GetEventInt(event, "team");
	int oldTeam = GetEventInt(event, "oldteam");
	
	if(IsClientInGame(client)) {
		if(newTeam == CS_TEAM_T) {
			totalTerrorists++;
			if(IsPlayerAlive(client)) {
				aliveTerrorists++;
			}
		}
		if(newTeam == CS_TEAM_CT) {
			totalCT++;
			if(IsPlayerAlive(client)) {
				aliveCT++;
			}
		}
		if(oldTeam == CS_TEAM_T) {
			totalTerrorists--;
			if(IsPlayerAlive(client)) {
				aliveTerrorists--;
			}
		}
		if(oldTeam == CS_TEAM_CT) {
			totalCT--;
			if(IsPlayerAlive(client)) {
				aliveCT--;
			}
		}
	}
	
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", prefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDeath);
		Call_PushCell(client);
		Call_Finish();
	}
	
	if(IsValidClient(client, false, true)) {
		if(GetClientTeam(client) == CS_TEAM_CT)
			aliveCT--;
		if(GetClientTeam(client) == CS_TEAM_T)
			aliveTerrorists--;
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	aliveCT = 0;
	totalCT = 0;
	aliveTerrorists = 0;
	totalTerrorists = 0;
	
	if(WardenExists())
		RemoveWarden();
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			if(IsPlayerAlive(i)) {
				if(GetClientTeam(i) == CS_TEAM_CT)
					aliveCT++;
				if(GetClientTeam(i) == CS_TEAM_T)
					aliveTerrorists++;
			}
			
			if(GetClientTeam(i) == CS_TEAM_CT)
				totalCT++;
			if(GetClientTeam(i) == CS_TEAM_T)
				totalTerrorists++;
		}
	}
	
}

public void OnClientDisconnect(int client) {
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", prefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDisconnect);
		Call_PushCell(client);
		Call_Finish();
	}
	
	if(!IsFakeClient(client)) {
		if(IsPlayerAlive(client)) {
			if(GetClientTeam(client) == CS_TEAM_CT)
				aliveCT--;
			if(GetClientTeam(client) == CS_TEAM_T)
				aliveTerrorists--;
		}
		if(GetClientTeam(client) == CS_TEAM_CT)
			totalCT--;
		if(GetClientTeam(client) == CS_TEAM_T)
			totalTerrorists--;
			
	}
}


/////////////////////////////
//		   ACTIONS		   //
/////////////////////////////
public Action Command_Warden(int client, int args) {
	
	if(!IsValidClient(client, false, false)) { // Client is not valid. IE not ingame, alive etc.
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
	
	SetWarden(client);
	CPrintToChatAll("%s %t", prefix, "Warden Created", client);
	
	Call_StartForward(gF_OnWardenCreated);
	Call_PushCell(client);
	Call_Finish();
	
	return Plugin_Handled;
	
}

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

public Action Command_Unwarden(int client, int args) {
	if(!WardenExists()) {
		CPrintToChat(client, "%s %t", prefix, "No Warden Alive");
		return Plugin_Handled;
	}
	
	int warden = GetCurrentWarden();
	
	RemoveWarden();
	CPrintToChatAll("%s %t", prefix, "Warden Removed", warden);
	
	Call_StartForward(gF_OnAdminRemoveWarden);
	Call_PushCell(client);
	Call_PushCell(warden);
	Call_Finish();
	
	return Plugin_Handled;
}

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

public Action Command_SetWarden(int client, int args) {
	if(!IsValidClient(client, false, true)) {
		CPrintToChat(client, "%s %t", prefix, "Invalid Client");
		return Plugin_Handled;
	}
	if(WardenExists()) {
		CPrintToChat(client, "%s %t", prefix, "Warden Exists");
		return Plugin_Handled;
	}
	
	char arg[MAX_NAME_LENGTH];
	GetCmdArgString(arg, sizeof(arg));
	
	
	return Plugin_Handled;
}

public Action OnPlayerChat(int client, char[] command, int args) {
	if(!IsValidClient(client)) // Make sure warden isn't glitched and is in fact alive etc.
		return Plugin_Continue;
	if(!IsClientWarden(client)) // Client is warden; let's make the message cool!
		return Plugin_Continue;
	
	char message[255];
	GetCmdArg(1, message, sizeof(message));
	
	if(message[0] == '/' || message[0] == '@' || IsChatTrigger())
		return Plugin_Handled;
	
	CPrintToChatAll("{blue}[Warden] %N{default} : %s", client, message);
	return Plugin_Handled;
	
}


/////////////////////////////
//		   TIMERS		   //
/////////////////////////////
public Action RenderColor(Handle timer, int client) {
	if(!IsClientWarden(client)) {
		SetEntityRenderColor(client);
		return Plugin_Stop;
	}
	
	SetEntityRenderColor(client, 33, 114, 255);
	
	return Plugin_Continue;
}

public Action JBToolTip(Handle timer) {
	if(IsHnsActive())
		return Plugin_Handled;
	
	PrintHintTextToAll("%t\n%t", "Current Warden Hint", curWardenStat, "Players Stat Hint", aliveCT, totalCT, aliveTerrorists, totalTerrorists);
	
	return Plugin_Continue;
}

/////////////////////////////
//			NATIVES		   //
/////////////////////////////
public int Native_IsClientWarden(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(curWarden == client)
		return true;
	
	return false;
}
public int Native_WardenExists(Handle plugin, int numParams) {
	if(curWarden != -1) {
		return true;
	}
	
	return false;
}
public int Native_SetWarden(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	curWarden = client;
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	curWardenStat = name;
	CreateTimer(1.0, RenderColor, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return true;
}
public int Native_RemoveWarden(Handle plugin, int numParams) {
	curWarden = -1;
	curWardenStat = "None..";
	return true;
}
public int Native_GetCurrentWarden(Handle plugin, int numParams) {
	return curWarden;
}