/*
 * WardenMenu - Menus
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

/*
*	Basic Warden menu
*/
public void openMenu(int client) {
	Menu menu = new Menu(WardenMenuHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "Warden Menu Title");
	
	menu.SetTitle(title);
	
	if(gc_bEnableWeapons.IntValue == 1)
		menu.AddItem(CHOICE1, "Choice 1"); // Weapons
	
	menu.AddItem(CHOICE2, "Choice 2"); // Event Days
	
	if(gc_bEnablePlayerFreeday.IntValue == 1)
		menu.AddItem(CHOICE4, "Choice 4"); // Player Freeday
	
	if(gc_bEnableDoors.IntValue == 1)
		menu.AddItem(CHOICE5, "Choice 5"); // Open Doors
	
	if(gc_bNoblock.IntValue == 1)
		menu.AddItem(CHOICE3, "Choice 3"); // Noblock
	
	if(g_bVotesLoaded)
		menu.AddItem(CHOICE6, "Choice 6"); // Allow votes
	
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
				if(StrEqual(info, CHOICE6)) {
					if(g_bAllowVotes) {
						g_bAllowVotes = false;
						CPrintToChatAll("%s %t", g_sPrefix, "Votes Closed");
					} else {
						g_bAllowVotes = true;
						CPrintToChatAll("%s %t", g_sPrefix, "Votes Opened");
					}
				}
				if(StrEqual(info, CHOICE8)) {
					FakeClientCommand(client, "sm_rw");
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
				if(!IsHnsActive())
					return ITEMDRAW_DEFAULT;
				if(IsHnsActive())
					return ITEMDRAW_DISABLED;
			} else if(StrEqual(info, CHOICE5)) {
				return ITEMDRAW_DEFAULT;
			} else if(StrEqual(info, CHOICE6)) {
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
			if(StrEqual(info, CHOICE6)) {
				if(!g_bAllowVotes)
					Format(display, sizeof(display), "%t", "Allow Votes");
				if(g_bAllowVotes)
					Format(display, sizeof(display), "%t", "Dis-Allow Votes");
				
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

/*
*	Player Freeday menu
*/
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
						CPrintToChatAll("%s %t", g_sCMenuPrefix, "Player Freeday Announce", target);
					} else {
						RemoveClientFreeday(target);
						CPrintToChatAll("%s %t", g_sCMenuPrefix, "Player Freeday Removed", target);
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

/*
*	Days Menu
*/
public void openDaysMenu(int client) {
	Menu menu = new Menu(DaysMenuHandler, MENU_ACTIONS_ALL);
	
	char title[64];
	Format(title, sizeof(title), "%t", "Days Menu Title");
	
	menu.SetTitle(title);
	if(gc_bFreeday.IntValue == 1)
		menu.AddItem(CHOICE1, "Choice 1");
	
	if(gc_bRestFreeday.IntValue == 1)
		menu.AddItem(CHOICE2, "Choice 2");
	
	if(gc_bHnS.IntValue == 1)
		menu.AddItem(CHOICE3, "Choice 3");
	
	if(gc_bWarday.IntValue == 1)
		menu.AddItem(CHOICE4, "Choice 4");
	
	if(g_bCatchLoaded == true)
		menu.AddItem(CHOICE6, "Choice 6"); // Catch
	
	if(g_bWWLoaded == true)
		menu.AddItem(CHOICE7, "Choice 7"); // Wild West
	
	if(g_bZombieLoaded == true)
		menu.AddItem(CHOICE9, "Choice 9"); // Zombie
		
	if(gc_bGrav.IntValue == 1)
		menu.AddItem(CHOICE5, "Choice 5");
	
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
				if(!g_bIsGameActive) {
					if(StrEqual(info, CHOICE1))
						ExecFreeday();
					
					if(StrEqual(info, CHOICE2))
						initRestFreeday(client);
					
					if(StrEqual(info, CHOICE3))
						hnsConfig(client);
					
					if(StrEqual(info, CHOICE4))
						ExecWarday();
					
					if(StrEqual(info, CHOICE5))
						ExecGravday();
					
					if(StrEqual(info, CHOICE6))
						initCatch();
					
					if(StrEqual(info, CHOICE7))
						initWW();
					
					if(StrEqual(info, CHOICE9))
						initZombie();
					
					Call_StartForward(gF_OnEventDayCreated);
					Call_Finish();
				} else {
					if(StrEqual(info, CHOICE8)) {
						abortGames();
						CPrintToChatAll("%s %t", g_sCMenuPrefix, "Warden Aborted");
						PrintHintTextToAll("%t", "Warden Aborted");
					} else if(StrEqual(info, CHOICE1) || StrEqual(info, CHOICE2) || StrEqual(info, CHOICE3) || StrEqual(info, CHOICE4) || StrEqual(info, CHOICE5) || StrEqual(info, CHOICE6) || StrEqual(info, CHOICE7) || StrEqual(info, CHOICE9)) {
						CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Cannot Exec Game");
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
			if(g_bIsGameActive) {
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
				} else if(StrEqual(info, CHOICE6)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE7)) {
					return ITEMDRAW_DISABLED;
				} else if(StrEqual(info, CHOICE9)) {
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
			if(StrEqual(info, CHOICE6)) {
				Format(display, sizeof(display), "%t", "Catch Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE7)) {
				Format(display, sizeof(display), "%t", "Wild West Entry");
				return RedrawMenuItem(display);
			}
			if(StrEqual(info, CHOICE9)) {
				Format(display, sizeof(display), "%t", "Zombie Entry");
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

/*
*	HnS Config
*/
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
					ExecHnS(1);
				}
				if(StrEqual(info, CHOICE3)) {
					ExecHnS(2);
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

/*
*	Weapons Menu
*/
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