#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colorvariables>
#include <betterwarden>
#include <cmenu>
#include <smartjaildoors>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "0.3.2"

// Strings
char prefix[] = "[{blue}Warden{default}] ";
char curWardenStat[MAX_NAME_LENGTH];

// Integers
int curWarden = -1;
int prevWarden = -1;
int aliveCT = 0;
int aliveTerrorists = 0;
int totalCT = 0;
int totalTerrorists = 0;

// Forward handles
Handle gF_OnWardenDeath = null;
Handle gF_OnWardenDisconnect = null;
Handle gF_OnWardenRetire = null;
Handle gF_OnAdminRemoveWarden = null;
Handle gF_OnWardenCreated = null;

// ConVars
ConVar cv_version;
ConVar cv_EnableNoblock;
ConVar cv_noblock;
//ConVar cv_NoblockStandard;
ConVar cv_admFlag;
ConVar cv_openCells;
ConVar cv_wardenTwice;

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
	CreateNative("GetTeamAliveClientCount", Native_GetTeamAliveClientCount);
	RegPluginLibrary("betterwarden");
}

public void OnPluginStart() {

	// CVars
	AutoExecConfig(true, "warden", "BetterWarden");
	cv_version = CreateConVar("sm_warden_version", VERSION, "Current version of this plugin. DO NOT CHANGE THIS!", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cv_admFlag = CreateConVar("sm_warden_admin", "b", "The flag required to execute admin commands for this plugin.", FCVAR_NOTIFY);
	//cv_NoblockStandard = CreateConVar("sm_warden_noblock_standard", "1", "You only need to set this if sm_warden_noblock is set to 1!\nWhat should the noblock rules be as default on start of each round?\nThis should have the same value as your mp_solid_teammates cvar in server.cfg.\n1 = Solid teammates.\n0 = No block.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_EnableNoblock = CreateConVar("sm_warden_noblock", "1", "Give the warden the ability to toggle noblock via sm_noblock?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_openCells = CreateConVar("sm_warden_cellscmd", "1", "Give the warden ability to toggle cell-doors via sm_open?\nCell doors on every map needs to be setup with SmartJailDoors for this to work!\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_wardenTwice = CreateConVar("sm_warden_same_twice", "0", "Prevent the same warden from becoming warden next round instantly?\nThis should only be used on populated servers for obvious reasons.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// Translation stuff
	LoadTranslations("betterwarden.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	// Regular Commands
	RegConsoleCmd("sm_w", Command_Warden);
	RegConsoleCmd("sm_warden", Command_Warden);
	RegConsoleCmd("sm_c", Command_Warden);
	RegConsoleCmd("sm_rw", Command_Retire);
	RegConsoleCmd("sm_retire", Command_Retire);
	if(cv_openCells.IntValue == 1)
		RegConsoleCmd("sm_open", Command_OpenCells);
	if(cv_EnableNoblock.IntValue == 1)
		RegConsoleCmd("sm_noblock", Command_Noblock);
	
	// Admin Commands
	RegAdminCmd("sm_uw", Command_Unwarden, b); /*	TODO: Set the configured flag here	*/
	RegAdminCmd("sm_unwarden", Command_Unwarden, b);
	RegAdminCmd("sm_sw", Command_SetWarden, b);
	RegAdminCmd("sm_setwarden", Command_SetWarden, b);
	
	// Global forwards
	gF_OnWardenDeath = CreateGlobalForward("OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnect = CreateGlobalForward("OnWardenDisconnect", ET_Ignore, Param_Cell);
	gF_OnWardenRetire = CreateGlobalForward("OnWardenRetire", ET_Ignore, Param_Cell);
	gF_OnAdminRemoveWarden = CreateGlobalForward("OnAdminRemoveWarden", ET_Ignore, Param_Cell, Param_Cell);
	gF_OnWardenCreated = CreateGlobalForward("OnWardenCreated", ET_Ignore, Param_Cell);
	
	// Event Hooks
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_team", OnJoinTeam);
	
	// Command listeners
	AddCommandListener(OnPlayerChat, "say");
	
	// Timers
	CreateTimer(0.1, JBToolTip, _, TIMER_REPEAT);
	
	// Fetch 3rd party CVars
	cv_noblock = FindConVar("mp_solid_teammates");
}

/////////////////////////////
//		   FORWARDS		   //
/////////////////////////////
public void OnMapStart() {
	aliveCT = 0;
	totalCT = 0;
	aliveTerrorists = 0;
	totalTerrorists = 0;
	
	totalCT = GetTeamClientCount(CS_TEAM_CT);
	totalTerrorists = GetTeamClientCount(CS_TEAM_T);
	
	RemoveWarden();
}

public void OnJoinTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client, false, true)) {
		totalCT = GetTeamClientCount(CS_TEAM_CT);
		aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
		totalTerrorists = GetTeamClientCount(CS_TEAM_T);
		aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", prefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDeath);
		Call_PushCell(client);
		Call_Finish();
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(WardenExists())
		RemoveWarden();
		
	aliveCT = 0;
	aliveTerrorists = 0;
	
	totalCT = GetTeamClientCount(CS_TEAM_CT);
	totalTerrorists = GetTeamClientCount(CS_TEAM_T);
	aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	cv_noblock.RestoreDefault(true, false);
}

public void OnClientDisconnect(int client) {
	
	totalCT = GetTeamClientCount(CS_TEAM_CT);
	totalTerrorists = GetTeamClientCount(CS_TEAM_T);
	aliveCT = GetTeamAliveClientCount(CS_TEAM_CT);
	aliveTerrorists = GetTeamAliveClientCount(CS_TEAM_T);
	
	
	if(IsClientWarden(client)) {
		RemoveWarden();
		CPrintToChatAll("%s %t", prefix, "Warden Died");
		
		Call_StartForward(gF_OnWardenDisconnect);
		Call_PushCell(client);
		Call_Finish();
	}
	
}


/////////////////////////////
//		   ACTIONS		   //
/////////////////////////////
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
	Call_PushCell(client); // The admin removing the warden
	Call_PushCell(warden); // The client forced to retire
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

public Action OnPlayerChat(int client, char[] command, int args) {
	if(!IsValidClient(client)) // Make sure warden isn't glitched and is in fact alive etc.
		return Plugin_Continue;
	if(!IsClientWarden(client)) // Client is warden; let's make the message cool!
		return Plugin_Continue;
	
	char message[255];
	GetCmdArg(1, message, sizeof(message));
	
	if(message[0] == '/' || message[0] == '@' || IsChatTrigger())
		return Plugin_Handled;
	
	CPrintToChatAll("{bluegrey}[Warden] {team2}%N : %s", client, message);
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
public int Native_GetTeamAliveClientCount(Handle plugin, int numParams) {
	int team = GetNativeCell(1);
	int count = 0;
	
	for(int client = 1; client <= MaxClients; client++) {
		if(!IsValidClient(client, false, false))
			continue;
			
		if(GetClientTeam(client) == team)
			count++;
	}
	
	return count;
}

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
	if(cv_wardenTwice.IntValue == 1) {
		prevWarden = curWarden;
	}
	curWarden = -1;
	curWardenStat = "None..";
	return true;
}
public int Native_GetCurrentWarden(Handle plugin, int numParams) {
	return curWarden;
}