/*
 * BetterWarden - Actions
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

/////////////////////////////
//		   ACTIONS		   //
/////////////////////////////
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