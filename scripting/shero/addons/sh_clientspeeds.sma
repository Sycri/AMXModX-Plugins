/* AMX Mod X script.
*
*   SuperHero Client Speeds (sh_clientspeeds.sma)
*   Copyright (C) 2006 vittu
*
*   This program is free software; you can redistribute it and/or
*   modify it under the terms of the GNU General Public License
*   as published by the Free Software Foundation; either version 2
*   of the License, or (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, write to the Free Software
*   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*
*   In addition, as a special exception, the author gives permission to
*   link the code of this program with the Half-Life Game Engine ("HL
*   Engine") and Modified Game Libraries ("MODs") developed by Valve,
*   L.L.C ("Valve"). You must obey the GNU General Public License in all
*   respects for all of the code used other than the HL Engine and MODs
*   from Valve. If you modify this file, you may extend this exception
*   to your version of the file, but you are not obligated to do so. If
*   you do not wish to do so, delete this exception statement from your
*   version.
*
****************************************************************************
*
*               ******** AMX Mod X Only ********
*
*  Description:
*     This plugin will set a clients cl_ speeds to their max possible
*      setting of 2000 when the client is placed in the server.
*
*  Why:
*     A clients default cl_ speeds are set to 400, meaning the user will not
*      be able to move faster then a speed of 400. This becomes a problem if
*      a hero has a speed set higher than 400, as the user will not be able
*      to take full advantage of the increased speed.
*
*  Who:
*     This plugin is intended for SuperHero Mod servers that have heroes set
*      to speeds higher then 400.
*
*  Known Issues:
*     HLGaurd by default may set cl_ speeds to the default 400 if it is not
*      configured not to do so. Also, this script does change a users configed
*      cl_ speeds unwillingly.
*
****************************************************************************
*
*  http://shero.rocks-hideout.com/
*
*  Notes: Currently there are no cvars, plugin will not change cl_ speeds
*       when sh mod is off. If sh mod is turned on only clients connecting
*       will have their cl_ speeds changed.
*
*  Changelog:
*   v1.1 - vittu - 02/20/07
*	    - Max possible speed was found to be 2000 not 999
*   v1.0 - vittu - 07/21/06
*	    - Initial Release
*
****************************************************************************/

#include <amxmodx>
#include <superheromod>

static const PLUGIN_NAME[] = "SuperHero Client Speeds"
static const VERSION[] = "1.1"
static const AUTHOR[] = "vittu"
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	register_plugin(PLUGIN_NAME, VERSION, AUTHOR)
}
//----------------------------------------------------------------------------------------------
public client_putinserver(id)
{
	if ( !shModActive() || !is_user_connected(id) || is_user_bot(id) )
		return

	// Wait a bit to set the speeds, thanks to OneEyed for finding out
	set_task(5.0, "set_cl_speeds", id)
}
//----------------------------------------------------------------------------------------------
public set_cl_speeds(id)
{
	if ( !shModActive() || !is_user_connected(id) )
		return

	// 2000 is max even if speed is set higher, 2000 is max value possible
	client_cmd(id, "cl_forwardspeed 2000")
	client_cmd(id, "cl_sidespeed 2000")
	client_cmd(id, "cl_backspeed 2000")
}
//----------------------------------------------------------------------------------------------