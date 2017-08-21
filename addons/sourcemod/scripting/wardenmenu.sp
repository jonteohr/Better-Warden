/*************************************************************
*															 *
*						Warden Menu							 *
*						Author: Hypr						 *
*				  Module for BetterWarden					 *
*															 *
*************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <menus>
#include <colorvariables>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <wardenmenu>
#include <adminmenu>
#define REQUIRE_PLUGIN
#include <betterwarden>
#undef REQUIRE_PLUGIN

#define CHOICE1 "#choice1"
#define CHOICE2 "#choice2"
#define CHOICE3 "#choice3"
#define CHOICE4 "#choice4"
#define CHOICE5 "#choice5"
#define CHOICE6 "#choice6"
#define CHOICE7 "#choice7"
#define SPACER "#spacer"
#define SEP "#sep"
#define CHOICE8 "#choice8"

bool IsGameActive = false;
char cmenuPrefix[] = "[{bluegrey}WardenMenu{default}] ";
char g_BlipSound[PLATFORM_MAX_PATH];

// Current game
int hnsActive = 0;
int freedayActive = 0;
int wardayActive = 0;
int gravActive = 0;

// Track number of games played
int hnsTimes = 0;
int freedayTimes = 0;
int warTimes = 0;
int gravTimes = 0;

// Misc
int clientFreeday[MAXPLAYERS +1];
int hnsWinners;
int aliveTs;
int g_BeamSprite = -1;
int g_HaloSprite = -1;
int playerBeacon[MAXPLAYERS + 1];

// ## CVars ##
ConVar cvAutoOpen;
ConVar cvBeaconRadius;
// Convars to add different menu entries
ConVar cvHnS;
ConVar cvHnSGod;
ConVar cvHnSTimes;
ConVar cvFreeday;
ConVar cvFreedayTimes;
ConVar cvWarday;
ConVar cvWardayTimes;
ConVar cvGrav;
ConVar cvGravTeam;
ConVar cvGravStrength;
ConVar cvGravTimes;
ConVar cvRestFreeday;
ConVar cvNoblock;
ConVar cvEnableWeapons;
ConVar cvEnablePlayerFreeday;
ConVar cvEnableDoors;

Handle gF_OnCMenuOpened = null;
Handle gF_OnEventDayCreated = null;
Handle gF_OnEventDayAborted = null;
Handle gF_OnHnsOver = null;

#include "BetterWarden/WardenMenu/commands.sp"
#include "BetterWarden/WardenMenu/menus.sp"
#include "BetterWarden/WardenMenu/forwards.sp"
#include "BetterWarden/WardenMenu/natives.sp"

public Plugin myinfo = {
	name = "[CS:GO] Warden Menu",
	author = "Hypr",
	description = "Gives wardens access to a special menu",
	version = VERSION,
	url = "https://condolent.xyz"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("IsEventDayActive", Native_IsEventDayActive);
	CreateNative("IsHnsActive", Native_IsHnsActive);
	CreateNative("IsGravFreedayActive", Native_IsGravFreedayActive);
	CreateNative("IsWarActive", Native_IsWarActive);
	CreateNative("IsFreedayActive", Native_IsFreedayActive);
	CreateNative("ClientHasFreeday", Native_ClientHasFreeday);
	CreateNative("GiveClientFreeday", Native_GiveClientFreeday);
	CreateNative("RemoveClientFreeday", Native_RemoveClientFreeday);
	CreateNative("SetClientBeacon", Native_SetClientBeacon);
	RegPluginLibrary("cmenu");
	
	return APLRes_Success;
}

public OnPluginStart() {
	
	LoadTranslations("BetterWarden.Menu.phrases");
	LoadTranslations("betterwarden.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig(true, "menu", "BetterWarden");
	
	cvHnS = CreateConVar("sm_cmenu_hns", "1", "Add an option for Hide and Seek in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvHnSGod = CreateConVar("sm_cmenu_hns_godmode", "1", "Makes CT's invulnerable against attacks from T's during HnS to prevent rebels.\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvHnSTimes = CreateConVar("sm_cmenu_hns_rounds", "2", "How many times is HnS allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	cvFreeday = CreateConVar("sm_cmenu_freeday", "1", "Add an option for a freeday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvFreedayTimes = CreateConVar("sm_cmenu_freeday_rounds", "2", "How many times is a Freeday allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	cvWarday = CreateConVar("sm_cmenu_warday", "1", "Add an option for Warday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvWardayTimes = CreateConVar("sm_cmenu_warday_rounds", "1", "How many times is a Warday allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	cvGrav = CreateConVar("sm_cmenu_gravity", "1", "Add an option for a gravity freeday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvGravTeam = CreateConVar("sm_cmenu_gravity_team", "2", "Which team should get a special gravity on Gravity Freedays?\n0 = All teams.\n1 = Counter-Terrorists.\n2 = Terorrists.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvGravStrength = CreateConVar("sm_cmenu_gravity_strength", "0.5", "What should the gravity be set to on Gravity Freedays?", FCVAR_NOTIFY);
	cvGravTimes = CreateConVar("sm_cmenu_gravity_rounds", "1", "How many times is a Gravity Freeday allowed per map?\nSet to 0 for unlimited.", FCVAR_NOTIFY);
	cvNoblock = CreateConVar("sm_cmenu_noblock", "1", "sm_warden_noblock needs to be set to 1 for this to work!\nAdd an option for toggling noblock in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvAutoOpen = CreateConVar("sm_cmenu_auto_open", "1", "Automatically open the menu when a user becomes warden?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvEnableWeapons = CreateConVar("sm_cmenu_weapons", "1", "Add an option for giving the warden a list of weapons via the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvRestFreeday = CreateConVar("sm_cmenu_restricted_freeday", "1", "Add an option for a restricted freeday in the menu?\nThis event uses the same configuration as a normal freeday.\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvEnablePlayerFreeday = CreateConVar("sm_cmenu_player_freeday", "1", "Add an option for giving a specific player a freeday in the menu?\n0 = Disable.\n1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvEnableDoors = CreateConVar("sm_cmenu_doors", "1", "sm_warden_cellscmd needs to be set to 1 for this to work!\nAdd an option for opening doors via the menu.\n0 = Disable.\n1 = Enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_abortgames", sm_abortgames);
	RegConsoleCmd("sm_cmenu", sm_cmenu);
	RegConsoleCmd("sm_wmenu", sm_cmenu);
	RegConsoleCmd("sm_days", sm_days);
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	for(int client = 1; client <= MaxClients; client++) {
		if(!IsClientInGame(client)) 
			continue;
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	}
	
	// Forwards
	gF_OnCMenuOpened = CreateGlobalForward("OnCMenuOpened", ET_Ignore, Param_Cell);
	gF_OnEventDayCreated = CreateGlobalForward("OnEventDayCreated", ET_Ignore);
	gF_OnEventDayAborted = CreateGlobalForward("OnEventDayAborted", ET_Ignore);
	gF_OnHnsOver = CreateGlobalForward("OnHnsOver", ET_Ignore);
	
}

public void OnAllPluginsLoaded() {
	cvBeaconRadius = FindConVar("sm_beacon_radius");
}

public void abortGames() {
	if(IsGameActive) {
		// Reset
		IsGameActive = false;
		hnsActive = 0;
		wardayActive = 0;
		freedayActive = 0;
		gravActive = 0;
		for(int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				SetEntityGravity(client, 1.0);
			}
		}
		
		Call_StartForward(gF_OnEventDayAborted);
		Call_Finish();
	} else {
		PrintToServer("%t", "Failed to abort Server");
	}
}

public void initHns(int client, int winners) {
	if(hnsWinners != 0 || hnsWinners <= 2) {
		if(cvHnSTimes.IntValue == 0) {
			CPrintToChatAll("{blue}-----------------------------------------------------");
			CPrintToChatAll("%s %t", cmenuPrefix, "HnS Begun");
			CPrintToChatAll("%s %t", cmenuPrefix, "Amount of Winners", hnsWinners);
			CPrintToChatAll("{blue}-----------------------------------------------------");
			hnsActive = 1;
			IsGameActive = true;
			CreateTimer(0.5, HnSInfo, _, TIMER_REPEAT);
		} else if(cvHnSTimes.IntValue != 0 && hnsTimes >= cvHnSTimes.IntValue) {
			
			CPrintToChat(client, "%s %t", cmenuPrefix, "Too many hns", hnsTimes, cvHnSTimes.IntValue);
			
		} else if(cvHnSTimes.IntValue != 0 && hnsTimes < cvHnSTimes.IntValue) {
			CPrintToChatAll("{blue}-----------------------------------------------------");
			CPrintToChatAll("%s %t", cmenuPrefix, "HnS Begun");
			CPrintToChatAll("%s %t", cmenuPrefix, "Amount of Winners", hnsWinners);
			CPrintToChatAll("{blue}-----------------------------------------------------");
			hnsActive = 1;
			IsGameActive = true;
			hnsTimes++;
			CreateTimer(0.5, HnSInfo, _, TIMER_REPEAT);
		}
	} else {
		CPrintToChat(client, "%s {red}%t", cmenuPrefix, "No Winners Selected");
	}
}

public Action HnSInfo(Handle timer) {
	if(!IsHnsActive())
		return Plugin_Handled;
	
	char msg1[64];
	Format(msg1, sizeof(msg1), "%t", "Contesters Left", aliveTs);
	
	char msg2[64];
	Format(msg2, sizeof(msg2), "%t", "HnS Winners Info", hnsWinners);
	
	PrintHintTextToAll("%s\n%s", msg1, msg2);
	
	return Plugin_Continue;
}

public void initFreeday(int client) {
	
	/*
	* What to do to the server here??
	* Probably nothing that needs to be done..
	*/
	
	if(cvFreedayTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		freedayActive = 1;
		IsGameActive = true;
	} else if(cvFreedayTimes.IntValue != 0 && freedayTimes >= cvFreedayTimes.IntValue) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Too many freedays", freedayTimes, cvFreedayTimes.IntValue);
	} else if(cvFreedayTimes.IntValue != 0 && freedayTimes < cvFreedayTimes.IntValue) {
		PrintHintTextToAll("%t", "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		freedayActive = 1;
		IsGameActive = true;
		freedayTimes++;
	}
}

public void initRestFreeday(int client) {
	if(cvFreedayTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Rest Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Rest Freeday Begun");
		CPrintToChatAll("%s %t", cmenuPrefix, "Rest Freeday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		freedayActive = 1;
		IsGameActive = true;
	} else if(cvFreedayTimes.IntValue != 0 && freedayTimes >= cvFreedayTimes.IntValue) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Too many freedays", freedayTimes, cvFreedayTimes.IntValue);
	} else if(cvFreedayTimes.IntValue != 0 && freedayTimes < cvFreedayTimes.IntValue) {
		PrintHintTextToAll("%t", "Rest Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Rest Freeday Begun");
		CPrintToChatAll("%s %t", cmenuPrefix, "Rest Freeday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		freedayActive = 1;
		IsGameActive = true;
		freedayTimes++;
	}
}

public void initWarday(int client) {
	
	/*
	* Same here. Anything to do to the server?
	*/
	
	if(cvWardayTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Warday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Warday Begun");
		CPrintToChatAll("%s %t", cmenuPrefix, "Warday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		wardayActive = 1;
		IsGameActive = true;
	} else if(cvWardayTimes.IntValue != 0 && warTimes >= cvWardayTimes.IntValue) {
		CPrintToChat(client, "%s %t", "Too many wardays", warTimes, cvWardayTimes.IntValue);
	} else if(cvWardayTimes.IntValue != 0 && warTimes < cvWardayTimes.IntValue) {
		PrintHintTextToAll("%t", "Warday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Warday Begun");
		CPrintToChatAll("%s %t", cmenuPrefix, "Warday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		wardayActive = 1;
		IsGameActive = true;
		warTimes++;
	}
	
}

public void initGrav(int client) {
	if(cvGravTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		gravActive = 1;
		IsGameActive = true;
		
		for(int usr = 1; usr <= MaxClients; usr++) {
			if(cvGravTeam.IntValue == 0) {
				if(IsValidClient(usr)) {
					SetEntityGravity(client, cvGravStrength.FloatValue);
				}
			} else if(cvGravTeam.IntValue == 1) {
				if(IsValidClient(usr) && GetClientTeam(usr) == CS_TEAM_CT) {
					SetEntityGravity(usr, cvGravStrength.FloatValue);
				}
			} else if(cvGravTeam.IntValue == 2) {
				if(IsValidClient(usr) && GetClientTeam(usr) == CS_TEAM_T) {
					SetEntityGravity(usr, cvGravStrength.FloatValue);
				}
			}
		}
	} else if(cvGravTimes.IntValue != 0 && gravTimes >= cvGravTimes.IntValue) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Too many gravdays", gravTimes, cvGravTimes.IntValue);
	} else if(cvGravTimes.IntValue != 0 && gravTimes < cvGravTimes.IntValue) {
		PrintHintTextToAll("%t", "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", cmenuPrefix, "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		gravActive = 1;
		IsGameActive = true;
		
		for(int usr = 1; usr <= MaxClients; usr++) {
			if(cvGravTeam.IntValue == 0) {
				if(IsValidClient(usr)) {
					SetEntityGravity(usr, cvGravStrength.FloatValue);
				}
			} else if(cvGravTeam.IntValue == 1) {
				if(IsValidClient(usr) && GetClientTeam(usr) == CS_TEAM_CT) {
					SetEntityGravity(usr, cvGravStrength.FloatValue);
				}
			} else if(cvGravTeam.IntValue == 2) {
				if(IsValidClient(usr) && GetClientTeam(usr) == CS_TEAM_T) {
					SetEntityGravity(usr, cvGravStrength.FloatValue);
				}
			}
		}
		
	}
}

public void error(int client, int errorCode) {
	if(errorCode == 0) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Not Warden");
	}
	if(errorCode == 1) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Not Alive");
	}
	if(errorCode == 2) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Client Not CT");
	}
}

public Action BeaconTimer(Handle timer, any client) {

	if(!IsValidClient(client))
		return Plugin_Stop;
		
	if(playerBeacon[client] == 0)
		return Plugin_Stop;
	
	int beamColor[4] = {
		74,
		255,
		111,
		255
	};
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	if(g_BeamSprite > -1 && g_HaloSprite > -1) {
		
		TE_SetupBeamRingPoint(vec, 10.0, cvBeaconRadius.FloatValue, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, beamColor, 10, 0);
		TE_SendToAll();
		
	}
	if(g_BlipSound[0]) {
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_BlipSound, vec, client, SNDLEVEL_RAIDSIREN);
	}
	
	return Plugin_Continue;
}