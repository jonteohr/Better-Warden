#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colorvariables>
#include <betterwarden>
#include <wardenmenu>
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

// Modules
#include "BetterWarden/commands.sp"
#include "BetterWarden/actions.sp"
#include "BetterWarden/events.sp"

public Plugin myinfo = {
	name = "[CS:GO] Better Warden",
	author = "Hypr",
	description = "A better, more advanced warden plugin for jailbreak.",
	version = VERSION,
	url = "https://condolent.xyz"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Game is not supported. CS:GO ONLY");
	}
	
	CreateNative("IsClientWarden", Native_IsClientWarden);
	CreateNative("WardenExists", Native_WardenExists);
	CreateNative("SetWarden", Native_SetWarden);
	CreateNative("RemoveWarden", Native_RemoveWarden);
	CreateNative("GetCurrentWarden", Native_GetCurrentWarden);
	CreateNative("GetTeamAliveClientCount", Native_GetTeamAliveClientCount);
	CreateNative("IsClientWardenAdmin", Native_IsClientWardenAdmin);
	RegPluginLibrary("betterwarden");
	
	// Global forwards
	gF_OnWardenDeath = CreateGlobalForward("OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnect = CreateGlobalForward("OnWardenDisconnect", ET_Ignore, Param_Cell);
	gF_OnWardenRetire = CreateGlobalForward("OnWardenRetire", ET_Ignore, Param_Cell);
	gF_OnAdminRemoveWarden = CreateGlobalForward("OnAdminRemoveWarden", ET_Ignore, Param_Cell, Param_Cell);
	gF_OnWardenCreated = CreateGlobalForward("OnWardenCreated", ET_Ignore, Param_Cell);
	gF_OnWardenCreatedByAdmin = CreateGlobalForward("OnWardenCreatedByAdmin", ET_Ignore, Param_Cell, Param_Cell);
	
	return APLRes_Success;
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
	cv_wardenIconPath = CreateConVar("sm_warden_icon_path", "decals/BetterWarden/warden", "The path to the icon. Do not include file extensions!\nThe path here should be from whithin the materials/ folder.", FCVAR_NOTIFY);
	
	// Translation stuff
	LoadTranslations("BetterWarden.phrases");
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