#include <sourcemod>
#include <sdktools>
#include "include\colors.inc"
//#pragma semicolon 1
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define CVAR_FLAGS FCVAR_NONE

#define MAX_LINE_WIDTH 64
#define L4D_MAXPLAYERS 32
#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZC_HUNTER 3
#define MAX_TOP_PLAYERS 6
// #define MAX_NAME_LENGTH

int ZC_TANK = 5;

ConVar counters_show_frags = null;
ConVar counters_show_tank_damage = null;
ConVar counters_show_witch_damage = null;
ConVar counters_show_tank_hp = null;

int Kills[L4D_MAXPLAYERS + 1];
int TankDamage[L4D_MAXPLAYERS + 1];
int WitchDamage[L4D_MAXPLAYERS + 1];
int LastPrintTime;
int Time_TankSpawn;
bool TankHPPrinted;
bool FragsPrinted;
bool IsSpamTagsRemoved = false;

char TankName[MAX_NAME_LENGTH];

public Plugin myinfo = 
{
	name = "Left 4 Dead 1,2 Counters",
	author = "Jonny",
	description = "Some counters here.",
	version = "1.1.7",
	url = ""
}

public void OnPluginStart()
{
	counters_show_frags = CreateConVar("counters_show_frags", "0", "0 = disabled, 1 = normal (once per map), 2 = after each kill", FCVAR_NONE);
	counters_show_witch_damage = CreateConVar("counters_show_witch_damage", "0", "", FCVAR_NONE);
	counters_show_tank_damage = CreateConVar("counters_show_tank_damage", "0", "", FCVAR_NONE);
	counters_show_tank_hp = CreateConVar("counters_show_tank_hp", "0", "", FCVAR_NONE);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_bot_replace", Event_Replace);
	HookEvent("bot_player_replace", Event_Replace);
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("tank_frustrated", Event_TankFrustrated, EventHookMode_Post);
	HookEvent("tank_killed", Event_TankKilled, EventHookMode_Post);
	RegConsoleCmd("sm_frags", Command_Frags);

	char moddir[24];
	GetGameFolderName(moddir, sizeof(moddir));
	if (StrEqual(moddir, "left4dead2", false))
	{
		ZC_TANK = 8;
	}
}

public void OnMapStart()
{
	ClearKillsCounter();
	ClearWitchDamageCounter();
	ClearTankDamageCounter();
}

public Action Command_Frags(int client, int args)
{
	PrintTotalFrags(2);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsSpamTagsRemoved) return;
	IsSpamTagsRemoved = true;
}

int ClearKillsCounter()
{
	FragsPrinted = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		Kills[i] = 0;
	}
}

int ClearWitchDamageCounter()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		WitchDamage[i] = 0;
	}
}

int ClearTankDamageCounter()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		TankDamage[i] = 0;
	}
}

int PrintTotalFrags(int mode)
{
	if (mode < 2)
	{
		if (LastPrintTime + 15 > GetTime() || FragsPrinted)
		{
			return;
		}
		else
		{
			FragsPrinted = true;
			LastPrintTime = GetTime();
		}
	}

	char Message[256];
	char TempMessage[64];
	Message = "\x01Frags: ";
	bool more_than_one = false;

	int Fraggers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Kills[i] > 0)
		{
			if (IsClientConnected(i) && !IsFakeClient(i)) Fraggers++;
		}
	}
	int Kills2D[L4D_MAXPLAYERS + 1][2];
	for (int i = 1; i <= MaxClients; i++)
	{
		Kills2D[i][0] = i;
		if (IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			Kills2D[i][1] = Kills[i];
		}
		else
		{
			Kills2D[i][1] = 0;
		}
	}
	SortCustom2D(Kills2D, MaxClients, Sort_Function);
	if (Fraggers > MAX_TOP_PLAYERS) Fraggers = MAX_TOP_PLAYERS;
	for (int i = 0; i < Fraggers; i++)
	{
		if (more_than_one)
		{
			if (GetClientTeam(Kills2D[i][0]) == TEAM_SURVIVORS) Format(TempMessage, sizeof(TempMessage), "\x01, {blue}%N: \x01%d", Kills2D[i][0], Kills[Kills2D[i][0]]);
			if (GetClientTeam(Kills2D[i][0]) == TEAM_INFECTED) Format(TempMessage, sizeof(TempMessage), "\x01, \x04%N: \x01%d", Kills2D[i][0], Kills[Kills2D[i][0]]);
			if (GetClientTeam(Kills2D[i][0]) == TEAM_SPECTATORS) Format(TempMessage, sizeof(TempMessage), "\x01, \x03%N: \x01%d", Kills2D[i][0], Kills[Kills2D[i][0]]);
		}
		else
		{
			if (GetClientTeam(Kills2D[i][0]) == TEAM_SURVIVORS) Format(TempMessage, sizeof(TempMessage), "{blue}%N: \x01%d", Kills2D[i][0], Kills[Kills2D[i][0]]);
			if (GetClientTeam(Kills2D[i][0]) == TEAM_INFECTED) Format(TempMessage, sizeof(TempMessage), "\x04%N: \x01%d", Kills2D[i][0], Kills[Kills2D[i][0]]);
			if (GetClientTeam(Kills2D[i][0]) == TEAM_SPECTATORS) Format(TempMessage, sizeof(TempMessage), "\x03%N: \x01%d", Kills2D[i][0], Kills[Kills2D[i][0]]);
		}
		more_than_one = true;
		StrCat(view_as<char>(Message), sizeof(Message), TempMessage);
	}	
	if (Fraggers == 0) return;
	CPrintToChatAll(Message);
}

int PrintTotalWitchDamage()
{
	char Message[256];
	char TempMessage[64];
	Message = "\x04Witch \x01was killed by: ";
	bool more_than_one = false;

	int Fraggers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (WitchDamage[i] > 0)
		{
			if (!IsFakeClient(i)) Fraggers++;
		}
	}
	int WitchDamage2D[L4D_MAXPLAYERS + 1][2];
	for (int i = 1; i <= MaxClients; i++)
	{
		WitchDamage2D[i][0] = i;
		if (IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			WitchDamage2D[i][1] = WitchDamage[i];
		}
		else
		{
			WitchDamage2D[i][1] = 0;
		}
	}
	SortCustom2D(WitchDamage2D, MaxClients, Sort_Function);
	if (Fraggers > MAX_TOP_PLAYERS) Fraggers = MAX_TOP_PLAYERS;
	for (int i = 0; i < Fraggers; i++)
	{
		if (more_than_one)
		{
			if (GetClientTeam(WitchDamage2D[i][0]) == TEAM_SURVIVORS) Format(TempMessage, sizeof(TempMessage), "\x01, {blue}%N: \x01%d", WitchDamage2D[i][0], WitchDamage[WitchDamage2D[i][0]]);
			if (GetClientTeam(WitchDamage2D[i][0]) == TEAM_INFECTED) Format(TempMessage, sizeof(TempMessage), "\x01, \x04%N: \x01%d", WitchDamage2D[i][0], WitchDamage[WitchDamage2D[i][0]]);
			if (GetClientTeam(WitchDamage2D[i][0]) == TEAM_SPECTATORS) Format(TempMessage, sizeof(TempMessage), "\x01, \x03%N: \x01%d", WitchDamage2D[i][0], WitchDamage[WitchDamage2D[i][0]]);
		}
		else
		{
			if (GetClientTeam(WitchDamage2D[i][0]) == TEAM_SURVIVORS) Format(TempMessage, sizeof(TempMessage), "{blue}%N: \x01%d", WitchDamage2D[i][0], WitchDamage[WitchDamage2D[i][0]]);
			if (GetClientTeam(WitchDamage2D[i][0]) == TEAM_INFECTED) Format(TempMessage, sizeof(TempMessage), "\x04%N: \x01%d", WitchDamage2D[i][0], WitchDamage[WitchDamage2D[i][0]]);
			if (GetClientTeam(WitchDamage2D[i][0]) == TEAM_SPECTATORS) Format(TempMessage, sizeof(TempMessage), "\x03%N: \x01%d", WitchDamage2D[i][0], WitchDamage[WitchDamage2D[i][0]]);
		}
		more_than_one = true;
		StrCat(view_as<char>(Message), sizeof(Message), TempMessage);
	}	
	if (Fraggers == 0) return;
	CPrintToChatAll(Message);
}

int PrintTotalTankDamage(int mode)
{
//	PrintToConsoleAll("PrintTotalTankDamage(%d)", mode);
	char Message[256];
	char TempMessage[64];
	if (mode > 0)
	{
		Format(Message, sizeof(Message), "\x04%s \x01was killed by: ", TankName);
	}
	else
	{
		int TankID = GetTank();
		if (TankID)
		{
			GetClientName(TankID, TankName, MAX_NAME_LENGTH);
		}
		Format(Message, sizeof(Message), "\x04%s \x01was damaged by: ", TankName);
		
	}
	bool more_than_one = false;
	int Fraggers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (TankDamage[i] > 0)
		{
			if (IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i)) Fraggers++;
		}
	}
	int TankDamage2D[L4D_MAXPLAYERS + 1][2];
	for (int i = 1; i <= MaxClients; i++)
	{
		TankDamage2D[i][0] = i;
		if (IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			TankDamage2D[i][1] = TankDamage[i];
		}
		else
		{
			TankDamage2D[i][1] = 0;
		}
	}
	SortCustom2D(TankDamage2D, MaxClients, Sort_Function);
	if (Fraggers > MAX_TOP_PLAYERS) Fraggers = MAX_TOP_PLAYERS;
	for (int i = 0; i < Fraggers; i++)
	{
		if (more_than_one)
		{
			if (GetClientTeam(TankDamage2D[i][0]) == TEAM_SURVIVORS) Format(TempMessage, sizeof(TempMessage), "\x01, {blue}%N: \x01%d", TankDamage2D[i][0], TankDamage[TankDamage2D[i][0]]);
			if (GetClientTeam(TankDamage2D[i][0]) == TEAM_INFECTED) Format(TempMessage, sizeof(TempMessage), "\x01, \x04%N: \x01%d", TankDamage2D[i][0], TankDamage[TankDamage2D[i][0]]);
			if (GetClientTeam(TankDamage2D[i][0]) == TEAM_SPECTATORS) Format(TempMessage, sizeof(TempMessage), "\x01, \x03%N: \x01%d", TankDamage2D[i][0], TankDamage[TankDamage2D[i][0]]);
		}
		else
		{
			if (GetClientTeam(TankDamage2D[i][0]) == TEAM_SURVIVORS) Format(TempMessage, sizeof(TempMessage), "{blue}%N: \x01%d", TankDamage2D[i][0], TankDamage[TankDamage2D[i][0]]);
			if (GetClientTeam(TankDamage2D[i][0]) == TEAM_INFECTED) Format(TempMessage, sizeof(TempMessage), "\x04%N: \x01%d", TankDamage2D[i][0], TankDamage[TankDamage2D[i][0]]);
			if (GetClientTeam(TankDamage2D[i][0]) == TEAM_SPECTATORS) Format(TempMessage, sizeof(TempMessage), "\x03%N: \x01%d", TankDamage2D[i][0], TankDamage[TankDamage2D[i][0]]);
		}
		more_than_one = true;
		StrCat(view_as<char>(Message), sizeof(Message), TempMessage);
	}	
	if (Fraggers == 0) return;
	TankHPPrinted = true;
	CPrintToChatAll(Message);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearKillsCounter();
	ClearWitchDamageCounter();
	ClearTankDamageCounter();
	TankHPPrinted = false;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(counters_show_frags) > 0) PrintTotalFrags(1);
}

public Action Event_TankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	GetClientName(client, TankName, MAX_NAME_LENGTH);
	TankHPPrinted = false;
	Time_TankSpawn = GetTime();
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	if (client && GetClientTeam(client) == TEAM_INFECTED)
	{
		if (IsTank(client))
		{
			Event_TankKilled(event, name, dontBroadcast);
			return;
		}
	}
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVORS)
	{
		Kills[attacker]++;
		if (GetConVarInt(counters_show_frags) > 1 && attacker != client)
		{
			PrintCenterText(attacker, "%d", Kills[attacker]);
		}
	}
	if (TankHPPrinted) return;
	if (!IsPluginTankDamageEnabled() && !IsPlayersAlive())
	{
		int TankHP = GetTankHP();
		if (TankHP > 0)
		{
			TankHPPrinted = true;
			PrintToChatAll("\x01Tank had \x03%d\x01 health remaining!", TankHP);
			PrintTotalTankDamage(0);
		}
		if (GetConVarInt(counters_show_frags) > 0) PrintTotalFrags(1);
	}
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if (TankHPPrinted) return;
	if (!IsPlayersAlive() && !IsPluginTankDamageEnabled())
	{
		if (GetConVarInt(counters_show_tank_hp) > 0)
		{
			int TankHP = GetTankHP();
			if (TankHP > 0)
			{
				TankHPPrinted = true;
				PrintToChatAll("\x01Tank had \x03%d\x01 health remaining!", TankHP);
				PrintTotalTankDamage(0);
			}
		}
		if (GetConVarInt(counters_show_frags) > 0) PrintTotalFrags(1);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int enemy = GetClientOfUserId(event.GetInt("attacker"));
	int target = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(target)) return;
	if (GetConVarInt(counters_show_tank_damage) > 0 && IsTank(target))
	{
		if (IsValidClient(enemy) && !IsIncapacitated(target))
		{
			int damage_count = event.GetInt("dmg_health");
			TankDamage[enemy] += damage_count;
			TankDamage[0] = GetClientHealth(target);
		}
	}
}

public Action Event_Replace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	Kills[player] = 0;
	Kills[bot] = 0;
	TankDamage[player] = 0;
	TankDamage[bot] = 0;
	WitchDamage[player] = 0;
	WitchDamage[bot] = 0;
}

public Action Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{	
	int entityid = event.GetInt("entityid");
	char class_name[128];
	GetEdictClassname(entityid, class_name, sizeof(class_name));
	if (!StrEqual(class_name, "witch", false)) return Plugin_Continue;
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(attacker)) return Plugin_Continue;
	WitchDamage[attacker] += event.GetInt("amount");
	WitchDamage[0] = GetEntityHealth(entityid);
	return Plugin_Continue;
}

public Action Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(counters_show_witch_damage) < 1) return;
	int userid = GetClientOfUserId(event.GetInt("userid"));
	WitchDamage[userid] += WitchDamage[0];
	PrintTotalWitchDamage();
	ClearWitchDamageCounter();
}

public Action Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
//	PrintToConsoleAll("[counters DEBUG INFO] Event_TankKilled spawn time+5 = %d, time = %d", Time_TankSpawn + 5, GetTime());
	if (GetConVarInt(counters_show_tank_damage) < 1) return;
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));
	GetClientName(client, TankName, MAX_NAME_LENGTH);
	if (Time_TankSpawn + 5 > GetTime() || GetTankHP() > 0)
	{
		CreateTimer(1.0, Timer_TankKilledConfirm, attacker);
		return;
	}
	TankDamage[attacker] += TankDamage[0];
	PrintTotalTankDamage(1);
	ClearTankDamageCounter();
}

public Action Timer_TankKilledConfirm(Handle timer, any client)
{
	if (GetTankHP() == 0)
	{
//		PrintToConsoleAll("[Timer_TankKilledConfirm] %N IsTank(%b)", client, IsTank(client));
		TankDamage[client] += TankDamage[0];
		PrintTotalTankDamage(1);
		ClearTankDamageCounter();
	}
	else
	{
		CreateTimer(0.3, Timer_TankKilledConfirm, client);
		return;
	}
}

stock int GetClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientConnected(i) && IsClientInGame(i))
		{
			if (!IsFakeClient(i)) return i;
		}
	}
	return 0;
}

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsValidEntity(client))	return false;
	return true;
}

stock int GetClientZC(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

bool IsTank(int client)
{
	if (GetClientZC(client) == ZC_TANK) return true;
	char modelname[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
	if (StrEqual(modelname, "models/infected/hulk.mdl", false))
	{
//		PrintToConsoleAll("Found tank with wrong class: %d", GetClientZC(client));
		return true;
	}
	return false;
}

bool IsPluginTankDamageEnabled()
{
	ConVar l4d_tankdamage_enabled = null;
	l4d_tankdamage_enabled = FindConVar("l4d_tankdamage_enabled");
	if (l4d_tankdamage_enabled == null) return false;
	if (GetConVarInt(l4d_tankdamage_enabled) > 0) return true;
	return false;
}

bool IsIncapacitated(int client)
{
	int isIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if (isIncap) return true;
	return false;
}

bool IsPlayersAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i) && !IsIncapacitated(i)) return true;
	}
	return false;
}

stock int GetTankHP()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientConnected(i) && IsClientInGame(i))
		{
			if (IsTank(i) && IsPlayerAlive(i))
			{
				if (IsIncapacitated(i)) return 0;
				return GetClientHealth(i);
			}
		}
	}
	return 0;
}

stock int GetTank()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientConnected(i) && IsClientInGame(i))
		{
			if (IsTank(i))
			{
				return i;
			}
		}
	}
	return 0;
}

public int Sort_Function(int[] array1, int[] array2, int[][] completearray, Handle hndl)
{
	//sort function for our crown array
	if (array1[1] > array2[1]) return -1;
	if (array1[1] == array2[1]) return 0;
	return 1;
}

/* stock PrintToConsoleAll(const String:format[], any:...)
{
	decl String:buffer[192];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToConsole(i, "%s", buffer);
		}
	}
} */

public int GetEntityHealth(int client)
{
	return GetEntProp(client, Prop_Data, "m_iHealth");
}
