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

	Format(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", g_sWardenIconPath);

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
	if(!IsValidClient(client))
		return Plugin_Stop;
		
	if(!IsClientWarden(client)) {
		SetEntityRenderColor(client);
		return Plugin_Stop;
	}
	
	SetEntityRenderColor(client, gc_iColorR.IntValue, gc_iColorG.IntValue, gc_iColorB.IntValue);
	
	return Plugin_Continue;
}

public Action JBToolTip(Handle timer) {
	if(IsHnsActive())
		return Plugin_Handled;
	
	PrintHintTextToAll("%t\n%t", "Current Warden Hint", g_sCurWardenStat, "Players Stat Hint", g_iAliveCT, g_iTotalCT, g_iAliveTerrorists, g_iTotalTerrorists);
	
	return Plugin_Continue;
}