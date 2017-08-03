/*************************************************************
*															 *
*						Warden Menu							 *
*						Author: Hypr						 *
*															 *
*************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <menus>
#include <colorvariables>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <cmenu>
#include <adminmenu>
#define REQUIRE_PLUGIN
#include <betterwarden>
#undef REQUIRE_PLUGIN

#define VERSION "0.1"

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

// ## CVars ##
ConVar cvVersion;
ConVar cvAutoOpen;
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
	RegPluginLibrary("cmenu");
}

public OnPluginStart() {
	
	LoadTranslations("cmenu.phrases.txt");
	SetGlobalTransTarget(LANG_SERVER);
	
	AutoExecConfig(true, "cmenu");
	
	cvVersion = CreateConVar("sm_cmenu_version", VERSION, "Current version running. Debugging purposes only!\nDo NOT change this!", FCVAR_DONTRECORD|FCVAR_NOTIFY); // Not visible in config
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
	
	
	RegAdminCmd("sm_abortgames", sm_abortgames, b);
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

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}
public void OnClientDisconnect(int client) {
	
	if(IsPlayerAlive(client)) {
		if(GetClientTeam(client) == CS_TEAM_T) {
			aliveTs--;
		}
	}
		
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientWarden(client)) {
		abortGames();
	}
	
	if(GetClientTeam(client) == CS_TEAM_T) {
		aliveTs--;
	}
	
	if(IsHnsActive()) {
		// Check if HnS should end
		if(hnsWinners == aliveTs) {
			abortGames();
			CPrintToChatAll("%s %t", cmenuPrefix, "HnS Over");
			
			Call_StartForward(gF_OnHnsOver);
			Call_Finish();
		} else {
			CPrintToChatAll("%s %t", cmenuPrefix, "HnS Players Left", aliveTs);
		}
	}
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	
	if(hnsActive == 1 && cvHnSGod.IntValue == 1) {
		if(IsValidClient(victim) && IsValidClient(inflictor) && GetClientTeam(victim) == CS_TEAM_CT && GetClientTeam(inflictor) == CS_TEAM_T) {
			CPrintToChat(inflictor, "%s %t", cmenuPrefix, "No Rebel HnS");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	abortGames();
	
	aliveTs = 0;
	for(int client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T) {
			aliveTs++;
		}
	}
}

public void OnMapStart() {
	abortGames();
	
	hnsTimes = 0;
	freedayTimes = 0;
	warTimes = 0;
	gravTimes = 0;
}

public void OnWardenCreated(int client) {
	CPrintToChat(client, "%s %t", cmenuPrefix, "Available to open menu");
	if(cvAutoOpen.IntValue == 1) {
		openMenu(client);
	} else {
		PrintToServer("Skipping auto open since it's disabled in config.");
	}
}

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

public Action sm_abortgames(int client, int args) {
	
	if(!IsGameActive) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Admin Abort Denied");
		return Plugin_Handled;
	}
	
	CPrintToChatAll("%s %t", cmenuPrefix, "Admin Aborted", client);
	abortGames();
	
	return Plugin_Handled;
}

public Action sm_days(int client, int args) {
	
	if(!IsValidClient(client) && GetClientTeam(client) != CS_TEAM_CT) {
		CPrintToChat(client, "%s %t", cmenuPrefix, "Neither alive or ct");
		return Plugin_Handled;
	}
	
	if(!IsClientWarden(client)) {
		error(client, 0);
		return Plugin_Handled;
	}
	
	openDaysMenu(client);
	
	return Plugin_Handled;
}

public void openMenu(int client) {
	Menu menu = new Menu(WardenMenuHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "Warden Menu Title");
	
	menu.SetTitle(title);
	
	if(cvEnableWeapons.IntValue == 1) {
		menu.AddItem(CHOICE1, "Choice 1"); // Weapons
	}
	
	menu.AddItem(CHOICE2, "Choice 2"); // Event Days
	
	if(cvEnablePlayerFreeday.IntValue == 1) {
		menu.AddItem(CHOICE4, "Choice 4"); // Player Freeday
	}
	
	if(cvEnableDoors.IntValue == 1) {
		menu.AddItem(CHOICE5, "Choice 5"); // Open Doors
	}
	
	if(cvNoblock.IntValue == 1) {
		menu.AddItem(CHOICE3, "Choice 3"); // Noblock
	}
	
	menu.AddItem(CHOICE8, "Choice 8"); // Leave warden
	
	menu.Display(client, 0);
	
	Call_StartForward(gF_OnCMenuOpened);
	Call_PushCell(client);
	Call_Finish();
	
}

public int WardenMenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch(action) {
		case MenuAction_Start:{} // Displaying menu to client
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%t\n----------------", "Warden Menu Title");
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(IsClientWarden(client)) {
				if(!StrEqual(info, CHOICE8)) {
					openMenu(client);
				}
				if(StrEqual(info, CHOICE1)) {
					openWeaponsMenu(client);
				}
				if(StrEqual(info, CHOICE2)) {
					openDaysMenu(client);
				}
				if(StrEqual(info, CHOICE3)) {
					FakeClientCommand(client, "sm_noblock");
				}
				if(StrEqual(info, CHOICE4)) {
					playerFreeday(client);
				}
				if(StrEqual(info, CHOICE5)) {
					FakeClientCommand(client, "sm_open");
				}
				if(StrEqual(info, CHOICE8)) {
					FakeClientCommand(client, "sm_uw");
				}
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
			} else if(StrEqual(info, CHOICE8)) {
				return ITEMDRAW_DEFAULT;
			} else if(StrEqual(info, CHOICE3)) {
				return ITEMDRAW_DEFAULT;
			} else if(StrEqual(info, CHOICE4)) {
				return ITEMDRAW_DEFAULT;
			} else if(StrEqual(info, CHOICE5)) {
				return ITEMDRAW_DEFAULT;
			} else if(StrEqual(info, SEP)) {
				return ITEMDRAW_DISABLED;
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
				Format(display, sizeof(display), "%t", "Weapons Menu Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE2)) {
				Format(display, sizeof(display), "%t", "Days Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE3)) {
				Format(display, sizeof(display), "%t", "Toggle Noblock Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE4)) {
				Format(display, sizeof(display), "%t", "Player Freeday Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE5)) {
				Format(display, sizeof(display), "%t", "Toggle doors");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE8)) {
				Format(display, sizeof(display), "%t\n----------------", "Leave Warden");
				return RedrawMenuItem(display);
			}
		}
	}
	
	return 0;
}

public void playerFreeday(int client) {
	Menu menu = new Menu(playerFreedayHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "Player Freeday Title");
	
	menu.SetTitle(title);
	AddTargetsToMenu(menu, 0, true, true);
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int playerFreedayHandler(Menu menu, MenuAction action, int client, int param2) {
	switch(action) {
		case MenuAction_Start:{} // Displaying the menu
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%t", "Player Freeday Title");
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
		case MenuAction_Select:
		{
			playerFreeday(client);
			char info[MAX_NAME_LENGTH];
			if(IsClientWarden(client)) {
				if(menu.GetItem(param2, info, sizeof(info))) {
					int target = GetClientOfUserId(StringToInt(info));
					
					if(!ClientHasFreeday(target)) {
						GiveClientFreeday(target);
						CPrintToChatAll("%s %t", cmenuPrefix, "Player Freeday Announce", target);
					} else {
						RemoveClientFreeday(target, true);
						CPrintToChatAll("%s %t", cmenuPrefix, "Player Freeday Removed", target);
					}
					
				}
			}
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack) {
				openMenu(client);
			}
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
			
			return style;
		}
	}
	
	return 0;
}

public void openDaysMenu(int client) {
	Menu menu = new Menu(DaysMenuHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "Days Menu Title");
	
	menu.SetTitle(title);
	if(cvFreeday.IntValue == 1) {
		menu.AddItem(CHOICE1, "Choice 1");
	}
	if(cvRestFreeday.IntValue == 1) {
		menu.AddItem(CHOICE2, "Choice 2");
	}
	if(cvHnS.IntValue == 1) {
		menu.AddItem(CHOICE3, "Choice 3");
	}
	if(cvWarday.IntValue == 1) {
		menu.AddItem(CHOICE4, "Choice 4");
	}
	if(cvGrav.IntValue == 1) {
		menu.AddItem(CHOICE5, "Choice 5");
	}
	menu.AddItem(SPACER, "Spacer");
	menu.AddItem(CHOICE8, "Choice 8");
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int DaysMenuHandler(Menu menu, MenuAction action, int client, int param2) {
	
	switch(action) {
		case MenuAction_Start:
		{
			// Displaying menu to client
		}
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%t", "Days Menu Title");
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(IsClientWarden(client)) {
				if(!IsGameActive) {
					if(StrEqual(info, CHOICE1)) {
						initFreeday(client);
					}
					if(StrEqual(info, CHOICE2)) {
						initRestFreeday(client);
					}
					if(StrEqual(info, CHOICE3)) {
						hnsConfig(client);
					}
					if(StrEqual(info, CHOICE4)) {
						initWarday(client);
					}
					if(StrEqual(info, CHOICE5)) {
						initGrav(client);
						Call_StartForward(gF_OnEventDayCreated);
						Call_Finish();
					}
				} else {
					if(StrEqual(info, CHOICE8)) {
						abortGames();
						CPrintToChatAll("%s %t", cmenuPrefix, "Warden Aborted");
						PrintHintTextToAll("%t", "Warden Aborted");
					} else if(StrEqual(info, CHOICE1) || StrEqual(info, CHOICE2) || StrEqual(info, CHOICE3) || StrEqual(info, CHOICE4) || StrEqual(info, CHOICE5)) {
						CPrintToChat(client, "%s %t", cmenuPrefix, "Cannot Exec Game");
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack) {
				openMenu(client);
			}
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
			
			// Disable all if a game is active!
			if(IsGameActive) {
				if(StrEqual(info, CHOICE1)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE2)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE3)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE4)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE5)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE8)) {
					return ITEMDRAW_DEFAULT;
				} else if(StrEqual(info, SPACER)) {
					return ITEMDRAW_SPACER;
				} else {
					return style;
				}
			} else {
				if(StrEqual(info, CHOICE8)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, SPACER)) {
					return ITEMDRAW_SPACER;
				} else {
					return style;
				}
			}
		}
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			char display[64];
			
			if(StrEqual(info, CHOICE1)) {
				Format(display, sizeof(display), "%t", "Freeday Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE2)) {
				Format(display, sizeof(display), "%t", "Restricted FD Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE3)) {
				Format(display, sizeof(display), "%t", "HnS Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE4)) {
				Format(display, sizeof(display), "%t", "Warday Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE5)) {
				Format(display, sizeof(display), "%t", "Gravity Freeday Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE8)) {
				Format(display, sizeof(display), "%t", "Abort Current Day");
				return RedrawMenuItem(display);
			}
		}
	}
	
	return 0;
}

public void hnsConfig(int client) {
	Menu menu = new Menu(hnsConfigHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "HnS Config Title");
	
	menu.SetTitle(title);
	
	menu.AddItem(CHOICE2, "Choice 2");
	menu.AddItem(CHOICE3, "Choice 3");
	
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int hnsConfigHandler(Menu menu, MenuAction action, int client, int param2) {
	switch(action) {
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%t", "HnS Config Title");
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if(IsClientWarden(client)) {
				if(StrEqual(info, CHOICE2)) {
					hnsWinners = 1;
					initHns(client, hnsWinners);
				}
				if(StrEqual(info, CHOICE3)) {
					hnsWinners = 2;
					initHns(client, hnsWinners);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack) {
				openDaysMenu(client);
			}
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
			
			if(StrEqual(info, CHOICE2) || StrEqual(info, CHOICE3)) {
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
			
			if(StrEqual(info, CHOICE2)) {
				Format(display, sizeof(display), "%t", "1 Winner Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE3)) {
				Format(display, sizeof(display), "%t", "2 Winner Entry");
				return RedrawMenuItem(display);
			}
		}
	}
	
	return 0;
}

public void openWeaponsMenu(int client) {
	Menu menu = new Menu(weaponsMenuHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "Weapons Menu Title");
	
	menu.SetTitle(title);
	menu.AddItem(CHOICE1, "Choice 1"); // AK47
	menu.AddItem(CHOICE2, "Choice 2"); // M4A1-S
	menu.AddItem(CHOICE3, "Choice 3"); // M4A4
	menu.AddItem(CHOICE4, "Choice 4"); // AWP
	menu.AddItem(CHOICE5, "Choice 5"); // P90
	menu.AddItem(CHOICE6, "Choice 6"); // Negev
	menu.AddItem(CHOICE7, "Choice 7"); // Scout
	menu.ExitBackButton = true;
	menu.Display(client, 0);
}

public int weaponsMenuHandler(Menu menu, MenuAction action, int client, int param2) {
	
	switch(action) {
		case MenuAction_Start:{} // Opening the menu to client
		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "%t", "Weapons Menu Title");
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if(IsClientWarden(client)) {
				openWeaponsMenu(client);
				
				if(StrEqual(info, CHOICE1)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_ak47");
					}
				}
				if(StrEqual(info, CHOICE2)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_m4a1_silencer");
					}
				}
				if(StrEqual(info, CHOICE3)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_m4a1");
					}
				}
				if(StrEqual(info, CHOICE4)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_awp");
					}
				}
				if(StrEqual(info, CHOICE5)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_p90");
					}
				}
				if(StrEqual(info, CHOICE6)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_negev");
					}
				}
				if(StrEqual(info, CHOICE7)) {
					if(IsValidClient(client)) {
						GivePlayerItem(client, "weapon_ssg08");
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack) {
				openMenu(client);
			}
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
			
			if(StrEqual(info, CHOICE1) || StrEqual(info, CHOICE2) || StrEqual(info, CHOICE3) || StrEqual(info, CHOICE4) || StrEqual(info, CHOICE5) || StrEqual(info, CHOICE6) || StrEqual(info, CHOICE7)) {
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
				Format(display, sizeof(display), "AK47");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE2)) {
				Format(display, sizeof(display), "M4A1-S");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE3)) {
				Format(display, sizeof(display), "M4A4");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE4)) {
				Format(display, sizeof(display), "AWP");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE5)) {
				Format(display, sizeof(display), "P90");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE6)) {
				Format(display, sizeof(display), "Negev");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE7)) {
				Format(display, sizeof(display), "Scout");
				return RedrawMenuItem(display);
			}
		}
	}
	
	return 0;
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

public void OnHnsOver() {
	PrintHintTextToAll("%t", "Small HNS Over");
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
		CPrintToChat(client, "%s %t", cmenuPrefix, "Not CT");
	}
}

/*
* Natives
*/
public int Native_IsEventDayActive(Handle plugin, int numParams)
{
	if(IsGameActive) {
		return true;
	}
	
	return false;
}

public int Native_IsHnsActive(Handle plugin, int numParams) {
	if(IsGameActive) {
		if(hnsActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_IsGravFreedayActive(Handle plugin, int numParams) {
	if(IsGameActive) {
		if(gravActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_IsWarActive(Handle plugin, int numParams) {
	if(IsGameActive) {
		if(wardayActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_IsFreedayActive(Handle plugin, int numParams) {
	if(IsGameActive) {
		if(freedayActive == 1) {
			return true;
		}
	}
	
	return true;
}

public int Native_ClientHasFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(IsValidClient(client)) {
		if(clientFreeday[client] == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_GiveClientFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(IsValidClient(client)) {
		clientFreeday[client] = 1;
		ServerCommand("sm_beacon %N", client);
		return true;
	}
	
	return false;
}

public int Native_RemoveClientFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	bool beacon = GetNativeCell(2);
	
	if(IsValidClient(client)) {
		clientFreeday[client] = 0;
		if(beacon) {
			ServerCommand("sm_beacon %N", client);
		}
		return true;
	}
	
	return false;
}