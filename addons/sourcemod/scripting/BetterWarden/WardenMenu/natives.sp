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
		SetClientBeacon(client, true);
		return true;
	}
	
	return false;
}

public int Native_RemoveClientFreeday(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	
	if(IsValidClient(client)) {
		clientFreeday[client] = 0;
		SetClientBeacon(client, false);
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
			playerBeacon[client] = 1;
			
			return true;
		} else {
			playerBeacon[client] = 0;
			
			return true;
		}
	}
	
	return false;
}