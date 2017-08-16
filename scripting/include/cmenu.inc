/*
* https://github.com/condolent/Better-Warden
*/

#if defined cmenuincluded
 #endinput
#endif
#define cmenuincluded

/**
* Called when a warden opens the warden menu. Also called when a player becomes a warden if sm_cmenu_auto_open is set to 1.
*
* @param client index of the one opening the menu
*/
forward void OnCMenuOpened(int client);

/**
* Called when an event day is created.
*/
forward void OnEventDayCreated();

/**
* Called when an event day is aborted.
*/
forward void OnEventDayAborted();

/**
* Called when Hide and Seek is won.
*/
forward void OnHnsOver();

/**
* Check if there is a event day currently active.
* 
* @return     true if yes
*/
native bool IsEventDayActive();

/**
* Check if a Hide and Seek game is running.
*
* @return     true if yes
*/
native bool IsHnsActive();

/**
* Check if a Gravity Freeday is running.
*
* @return     true if yes
*/
native bool IsGravFreedayActive();

/**
* Check if a warday is running.
*
* @return     true if yes
*/
native bool IsWarActive();

/**
* Check if a freeday is running.
*
* @return     true if yes
*/
native bool IsFreedayActive();

/**
* Check if the specified client already has a freeday.
*
* @param     client index
* @return     true if yes
*/
native bool ClientHasFreeday(int client);

/**
* Give a client a freeday
*
* @param      client index
* @return     true if successful
*/
native bool GiveClientFreeday(int client);

/**
* Remove a client's freeday
*
* @param      client index
* @param      set a beacon
* @return     true if successful
*/
native bool RemoveClientFreeday(int client);

/**
* Sets a beacon on a client. Just like the one in the SM Admin Menu.
*
* @param client index
* @param state of the beacon.
* @return true if successful
*/
native bool SetClientBeacon(int client, bool beaconState);