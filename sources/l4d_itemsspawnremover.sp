//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define PLUGIN_NAME "[L4D 1,2] ItemSpawnRemover"
#define PLUGIN_AUTHOR "Jonny"
#define PLUGIN_DESCRIPTION "Item Spawns Remover"
#define PLUGIN_VERSION "1.7.3"
#define PLUGIN_URL ""

ConVar Cvar_Plugin_Enabled;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	HookEvent("round_start_post_nav", Event_RoundStart);
	Cvar_Plugin_Enabled = CreateConVar("l4d_remove_item_spawns", "0", "", FCVAR_NONE);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RemoveItemSpawns();
}

public void OnMapStart()
{
	RemoveItemSpawns();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (GetConVarInt(Cvar_Plugin_Enabled) > 0 && entity > MAXPLAYERS && IsWeaponSpawn(classname))
	{
//		Log(classname);
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

public void OnEntitySpawned(int entity)
{
	AcceptEntityInput(entity, "Kill");
}

bool IsWeaponSpawn(const char[] classname)
{
	if (StrContains(classname, "spawn", false) < 0) return false;
	if (StrContains(classname, "weapon", false) < 0) return false;
	if (StrEqual(classname, "weapon_item_spawn", false)) return false;
	if (StrEqual(classname, "weapon_scavenge_item_spawn", false)) return false;
	if (StrEqual(classname, "weapon_ammo_spawn", false)) return false;
	return true;
}

int RemoveItemSpawns()
{
	if (GetConVarInt(Cvar_Plugin_Enabled) < 1) return;
	int entity;
// guns
	while ((entity = FindEntityByClassname(entity, "weapon_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_pistol_magnum_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_smg_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_smg_silenced_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_pumpshotgun_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_shotgun_chrome_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_autoshotgun_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_shotgun_spas_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_rifle_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_rifle_ak47_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_rifle_m60_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_rifle_desert_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_sniper_military_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_grenade_launcher_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_chainsaw_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
// health
	while ((entity = FindEntityByClassname(entity, "weapon_defibrillator_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_pain_pills_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_first_aid_kit_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_adrenaline_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
// throw
	while ((entity = FindEntityByClassname(entity, "weapon_vomitjar_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_molotov_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_pipe_bomb_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
// upgrades	
	while ((entity = FindEntityByClassname(entity, "weapon_upgradepack_explosive_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
	while ((entity = FindEntityByClassname(entity, "weapon_upgradepack_incendiary_spawn")) != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "Kill");
}

//Log(const String:LogReport[])
//{
//	decl String:file[PLATFORM_MAX_PATH];
//	BuildPath(Path_SM, file, sizeof(file), "logs/items.log");
//	LogToFileEx(file, "classname = %s", LogReport);
//	return;
//}