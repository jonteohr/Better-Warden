<h1 align="center">Better Warden</h1>

<p align="center">
	<img src="http://i.imgur.com/WXfuF5Y.png" width="572px"><br/>
	<a href="https://travis-ci.org/condolent/Better-Warden">
		<img src="https://travis-ci.org/condolent/Better-Warden.svg?branch=master">
	</a>
	<a href="https://github.com/condolent/Better-Warden/wiki">
		<img src="https://img.shields.io/badge/Plugin-Wiki-orange.svg?style=flat">
	</a>
	<a href="https://github.com/condolent/Better-Warden/releases">
		<img src="https://img.shields.io/github/release/condolent/better-warden.svg">
	</a>
	<a href="https://github.com/condolent/Better-Warden/releases">
		<img src="https://img.shields.io/github/downloads/condolent/better-warden/total.svg">
	</a>
	<a href="https://github.com/condolent/Better-Warden/issues">
		<img src="https://img.shields.io/github/issues-raw/condolent/better-warden.svg">
	</a>
	<a href="https://forums.alliedmods.net/showthread.php?p=2541919#post2541919">
		<img src="https://img.shields.io/badge/SM-Thread-lightgrey.svg?style=flat">
	</a>
	<a href="https://github.com/condolent/Better-Warden/blob/master/LICENSE">
		<img src="https://img.shields.io/badge/License-GPL3-red.svg?style=flat">
	</a>
</p>
<p align="center">
	<sup><strong>An improved and more advanced warden plugin with a custom menu for CS:GO jailbreak servers!</strong></sup>
<p>

## Repository Index
* [Installation](#installation)
* [Dependencies](#dependencies)
* [Features](#features)
* [CVars](#cvars)
* [Commands](https://github.com/condolent/Better-Warden/wiki/Commands)
* [API](https://github.com/condolent/Better-Warden/wiki/API)
* [Translations](#translations)

## Installation
1. [Download the plugin package](https://github.com/condolent/Better-Warden/releases)
2. In the `SERVER FILES` folder, drag all of its' content to your servers root folder (`csgo`)
3. Everything in the `FASTDL` folder should be uploaded to your FastDL webserver
4. Add the database entry named `betterwarden` to your databases.cfg file in _root/addons/sourcemod/configs_
5. Restart your server or change map
6. Make your desired changes in the configs located in `csgo/cfg/BetterWarden` folder
7. Change map or restart the server
8. Done!

## Dependencies
* [SmartJailDoors](https://forums.alliedmods.net/showthread.php?t=264100) _by Kailo_
* [SteamWorks Extension](https://forums.alliedmods.net/showthread.php?t=229556) _for Automatic Updates (Included in plugin package)_

## Features
The major function this plugin offers is that the warden can choose special event days to play out for the round. Each day has some special server rules & features that applies in order to make it much more fun for the players!  
1. Hide and Seek
2. Freeday
3. Warday
4. Gravity Freeday

Also introducing gangs. Prisoners can now create gangs where they can communicate in their own gangchat and such.

There's also some other functions in the menu that the warden can take advantage of in order to make the game more comfortable.  
Some of the other entries in the menu include:  
1. Toggle noblock
2. Weapons menu, allowing the warden to spawn in the selected weapon to himself
3. Give a specific player(s) freeday, marked with beacons

## CVars
### BetterWarden
| ConVar      | Default | Description   |
|:----------- |:-------:|:------------- |
|`sm_warden_version`|**_Plugin Version_**|Current version running. Debugging purposes only! Do NOT change this!|
|`sm_warden_admin`|**b**|The flag used for admin commands.|
|`sm_warden_noblock`|**1**|Give the warden the ability to toggle noblock via sm_noblock? 1 = Enable. 0 = Disable.|
|`sm_warden_cellscmd`|**1**|Give the warden ability to toggle cell-doors via sm_open? Cell doors on every map needs to be setup with SmartJailDoors for this to work! 1 = Enable. 0 = Disable.|
|`sm_warden_same_twice`|**0**|Prevent the same warden from becoming warden next round instantly? This should only be used on populated servers for obvious reasons. 1 = Enable. 0 = Disable.|
|`sm_warden_stats`|**1**|Have a hint message up during the round with information about who's warden, how many players there are etc. 1 = Enable. 0 = Disable.|
|`sm_warden_colorR`|**33**|The Red value of the color the warden gets.|
|`sm_warden_colorG`|**114**|The Green value of the color the warden gets.|
|`sm_warden_colorB`|**255**|The Blue value of the color the warden gets.|
|`sm_warden_icon`|**1**|Have an icon above the wardens' head? 1 = Enable. 0 = Disable.|
|`sm_warden_icon_path`|**decals/BetterWarden/warden**|The path to the icon. Do not include file extensions! The path here should be from whithin the materials/ folder.|
|`sm_warden_deathsound`|**1**|Play a sound telling everyone the warden has died? 1 = Enable. 0 = Disable.|
|`sm_warden_createsound`|**1**|Play a sound to everyone when someone becomes warden 1 = Enable. 0 = Disable.|
|`sm_warden_logs`|**0**|Do you want the plugin to write logs? Generally only necessary when you're experiencing any sort of issue. 1 = Enable. 0 = Disable.|
|`sm_warden_nolr`|**1**|Allow warden to control if terrorists can do a !lastrequest or !lr when available? 1 = Enable. 0 = Disable.|
|`sm_warden_servertag`|**1**|Add Better Warden tags to your servers sv_tags?|

### WardenMenu
| ConVar      | Default | Description   |
|:----------- |:-------:|:------------- |
|`sm_cmenu_hns`|**1**|Add an option for Hide and Seek in the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_hns_godmode`|**1**|Makes CT's invulnerable against attacks from T's during HnS to prevent rebels. 0 = Disable. 1 = Enable.|
|`sm_cmenu_hns_rounds`|**2**|How many times is HnS allowed per map? Set to 0 for unlimited.|
|`sm_cmenu_freeday`|**1**|Add an option for a freeday in the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_freeday_rounds`|**2**|How many times is a Freeday allowed per map? Set to 0 for unlimited.|
|`sm_cmenu_warday`|**1**|Add an option for Warday in the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_warday_rounds`|**1**|How many times is a Warday allowed per map? Set to 0 for unlimited.|
|`sm_cmenu_gravity`|**1**|Add an option for a gravity freeday in the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_gravity_team`|**2**|Which team should get a special gravity on Gravity Freedays? 0 = All teams. 1 = Counter-Terrorists. 2 = Terorrists.|
|`sm_cmenu_gravity_strength`|**0.5**|What should the gravity be set to on Gravity Freedays?|
|`sm_cmenu_gravity_rounds`|**1**|How many times is a Gravity Freeday allowed per map? Set to 0 for unlimited.|
|`sm_cmenu_noblock`|**1**|_sm_warden_noblock needs to be set to 1 for this to work!_ Add an option for toggling noblock in the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_auto_open`|**1**|Automatically open the menu when a user becomes warden? 0 = Disable. 1 = Enable.|
|`sm_cmenu_weapons`|**1**|Add an option for giving the warden a list of weapons via the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_restricted_freeday`|**1**|Add an option for a restricted freeday in the menu? This event uses the same configuration as a normal freeday. 0 = Disable. 1 = Enable.|
|`sm_cmenu_player_freeday`|**1**|Add an option for giving a specific player a freeday in the menu? 0 = Disable. 1 = Enable.|
|`sm_cmenu_doors`|**1**|sm_warden_cellscmd needs to be set to 1 for this to work! Add an option for opening doors via the menu. 0 = Disable. 1 = Enable|

## Translations
* English ✓
* Swedish ✓
* French ✓
* Russian ×
