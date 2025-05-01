#include <sourcemod>
#include <sdkhooks>

Handle g_hCookieAA = INVALID_HANDLE;
Handle g_hCookieBhop = INVALID_HANDLE;
Handle g_hCookieAuto = INVALID_HANDLE;
Handle g_hCookieFriction = INVALID_HANDLE;
Handle g_hCookieAccelerate = INVALID_HANDLE;

ConVar sv_airaccelerate = null;
ConVar sv_enablebunnyhopping = null;
ConVar sv_autobunnyhopping = null;
ConVar sv_friction = null;
ConVar sv_accelerate = null;

enum struct Settings
{
	float fAA;
	bool bBhop;
	bool bAuto;
	float fFriction;
	float fAccelerate;
}

Settings g_Settings[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "QuakeCS Movement Settings Menu",
	author = "olivia",
	description = "Change movement settings",
	version = "C:",
	url = "https://quakecs.net"
}

public void OnPluginStart()
{
	g_hCookieDefaultsSet = RegClientCookie("menu_defaultsset", "reset defaults cookie", CookieAccess_Protected);
	g_hCookieAA = RegClientCookie("menu_aa", "sv_airaccelerate cookie", CookieAccess_Protected);
	g_hCookieBhop = RegClientCookie("menu_bhop", "sv_enablebhopping cookie", CookieAccess_Protected);
	g_hCookieAuto = RegClientCookie("menu_auto", "sv_enableautobunnyhopping cookie", CookieAccess_Protected);
	g_hCookieFriction = RegClientCookie("menu_friction", "sv_friction cookie", CookieAccess_Protected);
	g_hCookieAccelerate = RegClientCookie("menu_accelerate", "sv_accelerate cookie", CookieAccess_Protected);
	
	RegConsoleCmd("sm_style", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_styles", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_diff", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_difficulty", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_movement", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_aa", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_airaccelerate", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_bhop", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_bunnyhop", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_auto", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_autohop", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_autobhop", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_friction", Command_Settings, "Choose your movement settings.");
	RegConsoleCmd("sm_accelerate", Command_Settings, "Choose your movement settings.");
	
	sv_airaccelerate = FindConVar("sv_airaccelerate");
	sv_airaccelerate.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	sv_enablebunnyhopping = FindConVar("sv_enablebunnyhopping");
	sv_enablebunnyhopping.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
	sv_autobunnyhopping.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	sv_accelerate = FindConVar("sv_accelerate");
	sv_accelerate.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	sv_friction = FindConVar("sv_friction");
	sv_friction.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client) || !IsClientInGame(client))
	{
		return;
	}
	
	char sCookie[8];
	
	GetClientCookie(client, g_hCookieAA, sCookie, 8);
	gSettings[client].fAA = (strlen(sCookie) > 0)? view_as<float>(StringToFloat(sCookie)):10.0;
	
	GetClientCookie(client, g_hCookieBhop, sCookie, 8);
	g_Settings[client].bBhop = (strlen(sCookie) > 0)? view_as<bool>(StringToInt(sCookie)):false;
	
	GetClientCookie(client, g_hCookieAuto, sCookie, 8);
	g_Settings[client].bAuto = (strlen(sCookie) > 0)? view_as<bool>(StringToInt(sCookie)):false;
	
	GetClientCookie(client, g_hCookieFriction, sCookie, 8);
	gSettings[client].fFriction = (strlen(sCookie) > 0)? view_as<float>(StringToFloat(sCookie)):4.0;
	
	GetClientCookie(client, g_hCookieAccelerate, sCookie, 8);
	gSettings[client].fAccelerate = (strlen(sCookie) > 0)? view_as<float>(StringToFloat(sCookie)):5.0;
	
	UpdateSettings(client);
}

public void OnClientPutInServer(int client)
{
	if(!IsClientConnected(client) || IsFakeClient(client))
	{
		return;
	}
	
	if(AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
	
	SDKHook(client, SDKHook_PreThinkPost, PreThinkPost);
}

public void Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	UpdateSettings(client);
}

public void PreThinkPost(int client)
{
	if(IsPlayerAlive(client))
	{
		sv_airaccelerate.FloatValue = g_Settings[client].fAA;
		sv_enablebunnyhopping.BoolValue = g_Settings[client].bBhop;
		sv_autobunnyhopping.BoolValue = g_Settings[client].bAuto;
		sv_friction.FloatValue = g_Settings[client].fFriction;
		sv_accelerate.FloatValue = g_Settings[client].fAccelerate;
	}
}

public Action Command_Settings(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	ShowSettingsMenu(client);
	return Plugin_Handled;
}

public Action ShowSettingsMenu(int client)
{
	Handle hMenu = CreateMenu(SettingsMenuHandler);
	char buf[64];
	
	SetMenuTitle(hMenu, "Movement Settings");
	
	Format(buf, sizeof(buf), "sv_airaccelerate %.0f", g_PlayerStates[client].fAA);
	AddMenuItem(hMenu, "aa", buf);
	
	Format(buf, sizeof(buf), "sv_enablebunnyhopping %s", g_PlayerStates[client].bBhop?"1":"0");
	AddMenuItem(hMenu, "bhop", buf);
	
	Format(buf, sizeof(buf), "sv_autobunnyhopping %s", g_PlayerStates[client].bAuto?"1":"0");
	AddMenuItem(hMenu, "auto", buf);
	
	Format(buf, sizeof(buf), "sv_friction %.0f", g_PlayerStates[client].fFriction);
	AddMenuItem(hMenu, "friction", buf);
	
	Format(buf, sizeof(buf), "sv_accelerate %.0f \n ", g_PlayerStates[client].fAccelerate);
	AddMenuItem(hMenu, "accelerate", buf);
	
	Format(buf, sizeof(buf), "Reset Defaults");
	AddMenuItem(hMenu, "reset", buf);
	
	DisplayMenu(hMenu, client, 0);
	
	return Plugin_Handled;
}

public int SettingsMenuHandler(Handle hMenu, MenuAction ma, int client, int nItem)
{
	switch(ma)
	{
		case MenuAction_Select:
		{
			char strInfo[16];
			
			if(!GetMenuItem(hMenu, nItem, strInfo, sizeof(strInfo)))
			{
				LogError("rip menu...");
				return Plugin_Handled;
			}
			
			if(!strcmp(strInfo, "aa"))
			{
				switch(g_Settings[client].fAA)
				{
					case 10.0:
						g_Settings[client].fAA = 100.0;
					case 100.0:
						g_Settings[client].fAA = 1000.0;
					default:
						g_Settings[client].fAA = 10.0;
				}
				SetCookie(client, g_hCookieAA, g_Settings[client].fAA);
			}
			else if(!strcmp(strInfo, "bhop"))
			{
				g_Settings[client].bBhop = !g_Settings[client].bBhop;
				SetCookie(client, g_hCookieBhop, g_Settings[client].bBhop);
			}
			else if(!strcmp(strInfo, "auto"))
			{
				g_Settings[client].bAuto = !g_Settings[client].bAuto;
				SetCookie(client, g_hCookieAuto, g_Settings[client].bAuto);
			}
			else if(!strcmp(strInfo, "friction"))
			{
				if(g_Settings[client].fFriction < 10.0)
				{
					g_Settings[client].fFriction += 1.0;
				}
				else
				{
					g_Settings[client].fFriction = 1.0;
				}
				SetCookie(client, g_hCookieFriction, g_Settings[client].fFriction);
			}
			else if(!strcmp(strInfo, "accelerate"))
			{
				if(g_Settings[client].fAccelerate < 10.0)
				{
					g_Settings[client].fAccelerate += 1.0;
				}
				else
				{
					g_Settings[client].fAccelerate = 1.0;
				}
				SetCookie(client, g_hCookieAccelerate, g_Settings[client].fAccelerate);
			}
			else if(!strcmp(strInfo, "reset"))
			{
				g_Settings[client].fAA = 10.0;
				SetFloatCookie(client, g_hCookieAA, g_Settings[client].fAA);
				g_Settings[client].bBhop = false;
				SetCookie(client, g_hCookieBhop, g_Settings[client].bBhop);
				g_Settings[client].bAuto = false;
				SetCookie(client, g_hCookieAuto, g_Settings[client].bAuto);
				g_Settings[client].fFriction = 4.0;
				SetFloatCookie(client, g_hCookieFriction, g_Settings[client].fFriction);
				g_Settings[client].fAccelerate = 5.0;
				SetFloatCookie(client, g_hCookieAccelerate, g_Settings[client].fAccelerate);
			}
			UpdateSettings(client);
			ShowSettingsPanel(client);
		}
	}
	return Plugin_Handled;
}

public void SetFloatCookie(int client, Handle hCookie, float n)
{
	char strCookie[64];
	
	FloatToString(n, strCookie, sizeof(strCookie));

	SetClientCookie(client, hCookie, strCookie);
}

public void SetCookie(int client, Handle hCookie, int n)
{
	char strCookie[64];
	
	IntToString(n, strCookie, sizeof(strCookie));

	SetClientCookie(client, hCookie, strCookie);
}

void UpdateSettings(int client)
{
	UpdateCvar(client, g_Settings[client].fAA, "aa");
	sv_enablebunnyhopping.ReplicateToClient(client, g_Settings[client].bBhop?"1":"0");
	sv_autobunnyhopping.ReplicateToClient(client, g_Settings[client].bAuto?"1":"0");
	UpdateCvar(client, g_Settings[client].fFriction, "friction");
	UpdateCvar(client, g_Settings[client].fAccelerate, "accelerate");
}

void UpdateCvar(int client, float value, char[] cvar)
{
	char sValue[8];
	FloatToString(value, sValue, 8);
	if(!strcmp(cvar, "aa"))
		sv_airaccelerate.ReplicateToClient(client, sValue);
	else if(!strcmp(cvar, "friction"))
		sv_friction.ReplicateToClient(client, sValue);
	else if(!strcmp(cvar, "accelerate"))
		sv_accelerate.ReplicateToClient(client, sValue);
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}