/*
 * WardenMenu - Natives
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
* Natives
*/
public int Native_IsEventDayActive(Handle plugin, int numParams) {
	if(g_bIsGameActive) {
		return true;
	}
	
	return false;
}

public int Native_IsHnsActive(Handle plugin, int numParams) {
	if(g_bIsGameActive) {
		if(g_iHnsActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_IsGravFreedayActive(Handle plugin, int numParams) {
	if(g_bIsGameActive) {
		if(g_iGravActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_IsWarActive(Handle plugin, int numParams) {
	if(g_bIsGameActive) {
		if(g_iWardayActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_IsFreedayActive(Handle plugin, int numParams) {
	if(g_bIsGameActive) {
		if(g_iFreedayActive == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_ClientHasFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(IsValidClient(client)) {
		if(g_iClientFreeday[client] == 1) {
			return true;
		}
	}
	
	return false;
}

public int Native_GiveClientFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(IsValidClient(client)) {
		g_iClientFreeday[client] = 1;
		SetClientBeacon(client, true);
		AddToBWLog("%N was given a freeday.", client);
		return true;
	}
	
	return false;
}

public int Native_RemoveClientFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(IsValidClient(client)) {
		g_iClientFreeday[client] = 0;
		SetClientBeacon(client, false);
		AddToBWLog("%N's freeday was cancelled.", client);
		return true;
	}
	
	return false;
}

public int Native_SetClientBeacon(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	bool beaconState = GetNativeCell(2);
	
	if(IsValidClient(client)) {
		if(beaconState == true) {
			CreateTimer(1.0, BeaconTimer, client, TIMER_REPEAT);
			g_iPlayerBeacon[client] = 1;
			
			return true;
		} else {
			g_iPlayerBeacon[client] = 0;
			
			return true;
		}
	}
	
	return false;
}

public int Native_ExecWarday(Handle plugin, int numParams) {
	int client = GetCurrentWarden();
	
	if(gc_iWardayTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Warday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Warday Begun");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Warday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iWardayActive = 1;
		g_bIsGameActive = true;
		AddToBWLog("A warday was executed.");
		return true;
	} else if(gc_iWardayTimes.IntValue != 0 && g_iWarTimes >= gc_iWardayTimes.IntValue) {
		CPrintToChat(client, "%s %t", "Too many wardays", g_iWarTimes, gc_iWardayTimes.IntValue);
		return false;
	} else if(gc_iWardayTimes.IntValue != 0 && g_iWarTimes < gc_iWardayTimes.IntValue) {
		PrintHintTextToAll("%t", "Warday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Warday Begun");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Warday Warning");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iWardayActive = 1;
		g_bIsGameActive = true;
		g_iWarTimes++;
		AddToBWLog("A warday was executed.");
		return true;
	}
	
	return false;
}

public int Native_ExecFreeday(Handle plugin, int numParams) {
	int client = GetCurrentWarden();
	
	if(gc_iFreedayTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iFreedayActive = 1;
		g_bIsGameActive = true;
		AddToBWLog("A Freeday was executed.");
		return true;
	} else if(gc_iFreedayTimes.IntValue != 0 && g_iFreedayTimes >= gc_iFreedayTimes.IntValue) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Too many freedays", g_iFreedayTimes, gc_iFreedayTimes.IntValue);
		return false;
	} else if(gc_iFreedayTimes.IntValue != 0 && g_iFreedayTimes < gc_iFreedayTimes.IntValue) {
		PrintHintTextToAll("%t", "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Freeday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iFreedayActive = 1;
		g_bIsGameActive = true;
		g_iFreedayTimes++;
		AddToBWLog("A Freeday was executed.");
		return true;
	}
	
	return false;
}

public int Native_ExecHnS(Handle plugin, int numParams) {
	int client = GetCurrentWarden();
	g_iHnsWinners = GetNativeCell(1);
	
	if(g_iHnsWinners != 0 || g_iHnsWinners <= 2) {
		if(gc_iHnSTimes.IntValue == 0) {
			CPrintToChatAll("{blue}-----------------------------------------------------");
			CPrintToChatAll("%s %t", g_sCMenuPrefix, "HnS Begun");
			CPrintToChatAll("%s %t", g_sCMenuPrefix, "Amount of Winners", g_iHnsWinners);
			CPrintToChatAll("{blue}-----------------------------------------------------");
			g_iHnsActive = 1;
			g_bIsGameActive = true;
			CreateTimer(0.5, HnSInfo, _, TIMER_REPEAT);
			AddToBWLog("A Hide n' Seek was executed.");
			return true;
			
		} else if(gc_iHnSTimes.IntValue != 0 && g_iHnsTimes >= gc_iHnSTimes.IntValue) {
			
			CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Too many hns", g_iHnsTimes, gc_iHnSTimes.IntValue);
			return false;
			
		} else if(gc_iHnSTimes.IntValue != 0 && g_iHnsTimes < gc_iHnSTimes.IntValue) {
			CPrintToChatAll("{blue}-----------------------------------------------------");
			CPrintToChatAll("%s %t", g_sCMenuPrefix, "HnS Begun");
			CPrintToChatAll("%s %t", g_sCMenuPrefix, "Amount of Winners", g_iHnsWinners);
			CPrintToChatAll("{blue}-----------------------------------------------------");
			g_iHnsActive = 1;
			g_bIsGameActive = true;
			g_iHnsTimes++;
			CreateTimer(0.5, HnSInfo, _, TIMER_REPEAT);
			AddToBWLog("A Hide n' Seek was executed.");
			return true;
		}
	} else {
		CPrintToChat(client, "%s {red}%t", g_sCMenuPrefix, "No Winners Selected");
		return false;
	}
	
	return false;
}

public int Native_ExecGravday(Handle plugin, int numParams) {
	int client = GetCurrentWarden();
	
	if(gc_iGravTimes.IntValue == 0) {
		PrintHintTextToAll("%t", "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iGravActive = 1;
		g_bIsGameActive = true;
		
		for(int i = 1; i <= MaxClients; i++) {
			if(gc_iGravTeam.IntValue == 0) {
				if(IsValidClient(i)) {
					SetEntityGravity(i, gc_fGravStrength.FloatValue);
				}
			} else if(gc_iGravTeam.IntValue == 1) {
				if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT) {
					SetEntityGravity(i, gc_fGravStrength.FloatValue);
				}
			} else if(gc_iGravTeam.IntValue == 2) {
				if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T) {
					SetEntityGravity(i, gc_fGravStrength.FloatValue);
				}
			}
		}
		AddToBWLog("A Gravity Freeday was executed.");
		return true;
		
	} else if(gc_iGravTimes.IntValue != 0 && g_iGravTimes >= gc_iGravTimes.IntValue) {
		CPrintToChat(client, "%s %t", g_sCMenuPrefix, "Too many gravdays", g_iGravTimes, gc_iGravTimes.IntValue);
		
		return false;
	} else if(gc_iGravTimes.IntValue != 0 && g_iGravTimes < gc_iGravTimes.IntValue) {
		PrintHintTextToAll("%t", "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		CPrintToChatAll("%s %t", g_sCMenuPrefix, "Gravday Begun");
		CPrintToChatAll("{blue}-----------------------------------------------------");
		g_iGravActive = 1;
		g_bIsGameActive = true;
		g_iGravTimes++;
		
		for(int usr = 1; usr <= MaxClients; usr++) {
			if(gc_iGravTeam.IntValue == 0) {
				if(IsValidClient(usr)) {
					SetEntityGravity(usr, gc_fGravStrength.FloatValue);
				}
			} else if(gc_iGravTeam.IntValue == 1) {
				if(IsValidClient(usr) && GetClientTeam(usr) == CS_TEAM_CT) {
					SetEntityGravity(usr, gc_fGravStrength.FloatValue);
				}
			} else if(gc_iGravTeam.IntValue == 2) {
				if(IsValidClient(usr) && GetClientTeam(usr) == CS_TEAM_T) {
					SetEntityGravity(usr, gc_fGravStrength.FloatValue);
				}
			}
		}
		AddToBWLog("A Gravity Freeday was executed.");
		return true;
	}
	
	return false;
}