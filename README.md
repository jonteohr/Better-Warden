# Better-Warden [![Build Status](https://travis-ci.org/condolent/Better-Warden.svg?branch=master)](https://travis-ci.org/condolent/Better-Warden)
An improved and more advanced warden plugin with a warden-menu for CS:GO jailbreak servers!  
[~~AlliedModders~~](https://forums.alliedmods.net/)

## Installation
1. [Download the plugin package](https://github.com/condolent/Better-Warden/releases)
2. Drag and drop the containing _addons_ folder to your root folder. _By default, the root folder is named csgo._
3. Restart your server or change map for the plugin to load with its translations etc.
4. Make desired changes in the configs located in _root/cfg/BetterWarden_.
5. Type in server console _sm plugins reload betterwarden_ & _sm plugins reload cmenu_.
6. Done!

## Dependencies
* [SmartJailDoors](https://forums.alliedmods.net/showthread.php?t=264100) _by Kailo_

## CVars
### BetterWarden
| ConVar      | Default | Description   |
|:----------- |:-------:|:------------- |
|`sm_warden_version`|**0.3**|Current version running. Debugging purposes only! Do NOT change this!|
|`sm_warden_admin`|**b**|The flag used for admin commands.|
|`sm_warden_noblock`|**1**|Give the warden the ability to toggle noblock via sm_noblock? 1 = Enable. 0 = Disable.|
|`sm_warden_cellscmd`|**1**|Give the warden ability to toggle cell-doors via sm_open? Cell doors on every map needs to be setup with SmartJailDoors for this to work! 1 = Enable. 0 = Disable.|
|`sm_warden_same_twice`|**0**|Prevent the same warden from becoming warden next round instantly? This should only be used on populated servers for obvious reasons. 1 = Enable. 0 = Disable.|

### CMenu
| ConVar      | Default | Description   |
|:----------- |:-------:|:------------- |
|`sm_cmenu_version`|**0.2**|Current version running. Debugging purposes only! Do NOT change this!|
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
