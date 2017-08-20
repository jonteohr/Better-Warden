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

// Strings
char prefix[] = "[{blue}Warden{default}] ";
char curWardenStat[MAX_NAME_LENGTH];
char WardenIconPath[256];

// Integers
int curWarden = -1;
int prevWarden = -1;
int aliveCT = 0;
int aliveTerrorists = 0;
int totalCT = 0;
int totalTerrorists = 0;
int iIcon[MAXPLAYERS +1] = {-1, ...};

// Forward handles
Handle gF_OnWardenDeath = null;
Handle gF_OnWardenDisconnect = null;
Handle gF_OnWardenRetire = null;
Handle gF_OnAdminRemoveWarden = null;
Handle gF_OnWardenCreated = null;
Handle gF_OnWardenCreatedByAdmin = null;

// ConVars
ConVar cv_version;
ConVar cv_EnableNoblock;
ConVar cv_noblock;
ConVar cv_admFlag;
ConVar cv_openCells;
ConVar cv_wardenTwice;
ConVar cv_StatsHint;
ConVar cv_colorR;
ConVar cv_colorG;
ConVar cv_colorB;
ConVar cv_wardenIcon;
ConVar cv_wardenIconPath;

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
	CreateNative("IsClientWardenAdmin", Native_IsClientWardenAdmin);
	RegPluginLibrary("betterwarden");
}

public void OnPluginStart() {

	// CVars
	AutoExecConfig(true, "warden", "BetterWarden");
	cv_version = CreateConVar("sm_warden_version", VERSION, "Current version of this plugin. DO NOT CHANGE THIS!", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cv_admFlag = CreateConVar("sm_warden_admin", "b", "The flag required to execute admin commands for this plugin.", FCVAR_NOTIFY);
	cv_EnableNoblock = CreateConVar("sm_warden_noblock", "1", "Give the warden the ability to toggle noblock via sm_noblock?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_openCells = CreateConVar("sm_warden_cellscmd", "1", "Give the warden ability to toggle cell-doors via sm_open?\nCell doors on every map needs to be setup with SmartJailDoors for this to work!\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_wardenTwice = CreateConVar("sm_warden_same_twice", "0", "Prevent the same warden from becoming warden next round instantly?\nThis should only be used on populated servers for obvious reasons.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_StatsHint = CreateConVar("sm_warden_stats", "1", "Have a hint message up during the round with information about who's warden, how many players there are etc.\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_colorR = CreateConVar("sm_warden_color_R", "33", "The Red value of the color the warden gets.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cv_colorG = CreateConVar("sm_warden_color_G", "114", "The Green value of the color the warden gets.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cv_colorB = CreateConVar("sm_warden_color_B", "255", "The Blue value of the color the warden gets.", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	cv_wardenIcon = CreateConVar("sm_warden_icon", "1", "Have an icon above the wardens' head?\n1 = Enable.\n0 = Disable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_wardenIconPath = CreateConVar("sm_warden_icon_path", "decals/BetterWarden/warden", "The path to the icon. Do not include file extensions!", FCVAR_NOTIFY);
	
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
	RegConsoleCmd("sm_uw", Command_Unwarden);
	RegConsoleCmd("sm_unwarden", Command_Unwarden);
	RegConsoleCmd("sm_sw", Command_SetWarden);
	RegConsoleCmd("sm_setwarden", Command_SetWarden);
	
	// Global forwards
	gF_OnWardenDeath = CreateGlobalForward("OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnect = CreateGlobalForward("OnWardenDisconnect", ET_Ignore, Param_Cell);
	gF_OnWardenRetire = CreateGlobalForward("OnWardenRetire", ET_Ignore, Param_Cell);
	gF_OnAdminRemoveWarden = CreateGlobalForward("OnAdminRemoveWarden", ET_Ignore, Param_Cell, Param_Cell);
	gF_OnWardenCreated = CreateGlobalForward("OnWardenCreated", ET_Ignore, Param_Cell);
	gF_OnWardenCreatedByAdmin = CreateGlobalForward("OnWardenCreatedByAdmin", ET_Ignore, Param_Cell, Param_Cell);
	
	// Event Hooks
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_team", OnJoinTeam);
	
	// Command listeners
	AddCommandListener(OnPlayerChat, "say");
	
	// Timers
	if(cv_StatsHint.IntValue == 1)
		CreateTimer(0.1, JBToolTip, _, TIMER_REPEAT);
	
	// Fetch CVars
	cv_noblock = FindConVar("mp_solid_teammates");
	cv_wardenIconPath.GetString(WardenIconPath, sizeof(WardenIconPath));
	
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
	
	if(cv_wardenIcon.IntValue == 1) {
		PrecacheModelAnyDownload(WardenIconPath);
	}
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

public void CreateIcon(int client) {
	if(!IsValidClient(client) || !IsClientWarden(client))
		return;
	
	if(cv_wardenIcon.IntValue != 1)
		return;
	
	RemoveIcon(client);
	
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);
	
	iIcon[client] = CreateEntityByName("env_sprite");
	
	if (!iIcon[client]) 
		return;
	
	char iconbuffer[256];
	
	Format(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", WardenIconPath);
	
	DispatchKeyValue(iIcon[client], "model", iconbuffer);
	DispatchKeyValue(iIcon[client], "classname", "env_sprite");
	DispatchKeyValue(iIcon[client], "spawnflags", "1");
	DispatchKeyValue(iIcon[client], "scale", "0.3");
	DispatchKeyValue(iIcon[client], "rendermode", "1");
	DispatchKeyValue(iIcon[client], "rendercolor", "255 255 255");
	DispatchSpawn(iIcon[client]);
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] = origin[2] + 90.0;
	
	TeleportEntity(iIcon[client], origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(iIcon[client], "SetParent", iIcon[client], iIcon[client], 0);
	
	SDKHook(iIcon[client], SDKHook_SetTransmit, Should_TransmitW);
}

public void RemoveIcon(int client) {
	if(iIcon[client] > 0 && IsValidEdict(iIcon[client])) {
		AcceptEntityInput(iIcon[client], "Kill");
		iIcon[client] = -1;
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
	
	CPrintToChatAll("{bluegrey}[Warden] {team2}%N :{default} %s", client, message);
	return Plugin_Handled;
	
}

public Action Should_TransmitW(int entity, int client) {
	char m_ModelName[PLATFORM_MAX_PATH];
	char iconbuffer[256];

	Format(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", WardenIconPath);

	GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));

	if (StrEqual(iconbuffer, m_ModelName))
	{
		return Plugin_Continue;
	}

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
	
	SetEntityRenderColor(client, cv_colorR.IntValue, cv_colorG.IntValue, cv_colorB.IntValue);
	
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
	
	CreateIcon(client);
	
	return true;
}
public int Native_RemoveWarden(Handle plugin, int numParams) {
	if(!WardenExists())
		return false;
	
	if(cv_wardenTwice.IntValue == 1) {
		prevWarden = curWarden;
	}
	
	RemoveIcon(GetCurrentWarden());
	
	curWarden = -1;
	curWardenStat = "None..";
	
	return true;
}
public int Native_GetCurrentWarden(Handle plugin, int numParams) {
	return curWarden;
}
public int Native_IsClientWardenAdmin(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	char admflag[32];
	GetConVarString(cv_admFlag, admflag, sizeof(admflag));
	
	if(IsValidClient(client, false, true)) {
		if((GetUserFlagBits(client) & ReadFlagString(admflag) == ReadFlagString(admflag)) || GetUserFlagBits(client) & ADMFLAG_ROOT)
			return true;
	}
	
	return false;
}