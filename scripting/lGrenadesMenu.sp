#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "lGrenadesMenu",
	author = "lukashdev",
	description = "Pozwala sobie ustawić zestaw granatów",
	version = "2.0.0",
	url = "lukashdev.pl"
};

enum struct GrenadeSet {
    int iFlesh;
    int iMolotov;
    int iHE;
    int iSmoke;
    int iDecoy;
    int GetAll() {
        return this.iFlesh+this.iMolotov+this.iHE+this.iSmoke+this.iDecoy;
    }
}

enum struct GrenadeSetMax {
    int iFlesh;
    int iMolotov;
    int iHE;
    int iSmoke;
    int iDecoy;
    int iMax;
}

enum struct AmmoType {
    int iFlesh;
    int iMolotov;
    int iINC;
    int iHE;
    int iSmoke;
    int iDecoy;
    bool bIsSet;
}

enum struct Settings {
    int iRound;
    char sVipFlag[8];
}

static const CSWeaponID g_iGrenadesIDs[] =
{
    CSWeapon_HEGRENADE,
    CSWeapon_SMOKEGRENADE,
    CSWeapon_FLASHBANG,
    CSWeapon_MOLOTOV,
    CSWeapon_INCGRENADE,
    CSWeapon_DECOY,
};

AmmoType g_eAmmoType;
Settings g_eSettings;
GrenadeSetMax g_eGrenadeSetMax;
GrenadeSet g_eGrenadeSet[MAXPLAYERS + 1];

Handle COOKIE_Grenades;

public void OnPluginStart()
{
    RegConsoleCmd("sm_granaty", CMD_Granaty);
    RegConsoleCmd("sm_grenades", CMD_Granaty);
    HookEvent("player_spawn", OnPlayerSpawn);
    LoadTranslations("lGrenadesMenu.phrases");
    LoadConfig();
    COOKIE_Grenades = RegClientCookie("lGrenadesMenu", "", CookieAccess_Private);
}

public void LoadConfig()
{
    if(!FileExists("addons/sourcemod/configs/lPlugins/lGrenadesMenu.cfg"))
        CreateConfig();

    KeyValues kv = CreateKeyValues("GrenadesMenu - lukash");
    FileToKeyValues(kv, "addons/sourcemod/configs/lPlugins/lGrenadesMenu.cfg");

    if(kv.JumpToKey("Settings"))
    {
        kv.GetString("Vip flag", g_eSettings.sVipFlag, 8);
        g_eSettings.iRound = kv.GetNum("Start round");
        kv.GoBack();
    }

    if(kv.JumpToKey("Max Grenade Set"))
    {
        g_eGrenadeSetMax.iMax = kv.GetNum("Max");
        g_eGrenadeSetMax.iDecoy = kv.GetNum("Decoy");
        g_eGrenadeSetMax.iFlesh = kv.GetNum("Flesh");
        g_eGrenadeSetMax.iHE = kv.GetNum("HE");
        g_eGrenadeSetMax.iSmoke = kv.GetNum("Smoke");
        g_eGrenadeSetMax.iMolotov = kv.GetNum("Molotov or INC");
    }

    delete kv;
}

public void CreateConfig()
{
    KeyValues kv = CreateKeyValues("GrenadesMenu - lukash");
    if(kv.JumpToKey("Settings", true))
    {
        kv.SetString("Vip flag", "o");
        kv.SetNum("Start round", 1);
        kv.GoBack();
    }

    if(kv.JumpToKey("Max Grenade Set", true))
    {
        kv.SetNum("Max", 4);
        kv.SetNum("Decoy", 1);
        kv.SetNum("Flesh", 2);
        kv.SetNum("HE", 1);
        kv.SetNum("Smoke", 1);
        kv.SetNum("Molotov or INC", 1);
    }

    kv.Rewind();
    if(!DirExists("addons/sourcemod/configs/lPlugins"))
        CreateDirectory("addons/sourcemod/configs/lPlugins", 488);
    char sFilePath[128];
    BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "configs/lPlugins/lGrenadesMenu.cfg");
    KeyValuesToFile(kv, sFilePath);
    delete kv;
}

public Action CMD_Granaty(int client, int args)
{
    if(IsVip(client))
        GrenadesMenu(client, 0);
    return Plugin_Continue;
}

public void GrenadesMenu(int client, int mode)
{
    char sBuffer[64];
    Menu menu = new Menu(mode == 0 ? GrenadesMenuAdd_Handler : GrenadesMenuRemove_Handler);
    menu.SetTitle("%T", "set grenade set", client, g_eGrenadeSet[client].GetAll(), g_eGrenadeSetMax.iMax);
    mode != 0 ? Format(sBuffer, sizeof(sBuffer), "%T", "add grenades", client) : Format(sBuffer, sizeof(sBuffer), "%T", "remove grenades", client);
    menu.AddItem("", sBuffer);
    Format(sBuffer, sizeof(sBuffer), "%T", "decoy", client, g_eGrenadeSet[client].iDecoy, g_eGrenadeSetMax.iDecoy);
    menu.AddItem("decoy", sBuffer, (mode == 0 && g_eGrenadeSet[client].iDecoy < g_eGrenadeSetMax.iDecoy && g_eGrenadeSet[client].GetAll() < g_eGrenadeSetMax.iMax) || (mode != 0 && g_eGrenadeSet[client].iDecoy > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    Format(sBuffer, sizeof(sBuffer), "%T", "flesh", client, g_eGrenadeSet[client].iFlesh, g_eGrenadeSetMax.iFlesh);
    menu.AddItem("flesh", sBuffer, (mode == 0 && g_eGrenadeSet[client].iFlesh < g_eGrenadeSetMax.iFlesh && g_eGrenadeSet[client].GetAll() < g_eGrenadeSetMax.iMax) || (mode != 0 && g_eGrenadeSet[client].iFlesh > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    Format(sBuffer, sizeof(sBuffer), "%T", "smoke", client, g_eGrenadeSet[client].iSmoke, g_eGrenadeSetMax.iSmoke);
    menu.AddItem("smoke", sBuffer, (mode == 0 && g_eGrenadeSet[client].iSmoke < g_eGrenadeSetMax.iSmoke && g_eGrenadeSet[client].GetAll() < g_eGrenadeSetMax.iMax) || (mode != 0 && g_eGrenadeSet[client].iSmoke > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    Format(sBuffer, sizeof(sBuffer), "%T", "he", client, g_eGrenadeSet[client].iHE, g_eGrenadeSetMax.iHE);
    menu.AddItem("he", sBuffer, (mode == 0 && g_eGrenadeSet[client].iHE < g_eGrenadeSetMax.iHE && g_eGrenadeSet[client].GetAll() < g_eGrenadeSetMax.iMax) || (mode != 0 && g_eGrenadeSet[client].iHE > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    Format(sBuffer, sizeof(sBuffer), "%T", "molotov", client, g_eGrenadeSet[client].iMolotov, g_eGrenadeSetMax.iMolotov);
    menu.AddItem("molotov", sBuffer, (mode == 0 && g_eGrenadeSet[client].iMolotov < g_eGrenadeSetMax.iMolotov && g_eGrenadeSet[client].GetAll() < g_eGrenadeSetMax.iMax) || (mode != 0 && g_eGrenadeSet[client].iMolotov > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.Display(client, MENU_TIME_FOREVER);
}

int GrenadesMenuAdd_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select: {
            switch(param2)
            {
                case 0: {
                    GrenadesMenu(param1, 1);
                    return 0;
                }
                case 1: g_eGrenadeSet[param1].iDecoy++;
                case 2: g_eGrenadeSet[param1].iFlesh++;
                case 3: g_eGrenadeSet[param1].iSmoke++;
                case 4: g_eGrenadeSet[param1].iHE++;
                case 5: g_eGrenadeSet[param1].iMolotov++;
            }
            GrenadesMenu(param1, 0);
        }
        case MenuAction_End: delete menu;
    }
    return 0;
}

int GrenadesMenuRemove_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select: {
            switch(param2)
            {
                case 0: {
                    GrenadesMenu(param1, 0);
                    return 0;
                }
                case 1: g_eGrenadeSet[param1].iDecoy--;
                case 2: g_eGrenadeSet[param1].iFlesh--;
                case 3: g_eGrenadeSet[param1].iSmoke--;
                case 4: g_eGrenadeSet[param1].iHE--;
                case 5: g_eGrenadeSet[param1].iMolotov--;
            }
            GrenadesMenu(param1, 1);
        }
        case MenuAction_End: delete menu;
    }
    return 0;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsValidClient(client))
        return;

    int iRounds =  CS_GetTeamScore(CS_TEAM_T) + CS_GetTeamScore(CS_TEAM_CT);
    if(iRounds > 15)
        iRounds -= 15;

    if(g_eSettings.iRound-1 <= iRounds && IsVip(client) && GameRules_GetProp("m_bWarmupPeriod") != 1)
        CreateTimer(0.5, TimerPlayerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void StripPlayerGrenades(int client)
{
    int iWeaponsCount = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
    for(int i; i < iWeaponsCount; i++)
    {
        int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
        if(IsGrenade(GetWeaponEntityID(iWeapon)))
            DeleteWeapon(client, iWeapon);
    }

    SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_eAmmoType.iHE);
    SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_eAmmoType.iSmoke);
    SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_eAmmoType.iFlesh);
    SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_eAmmoType.iMolotov);
    SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_eAmmoType.iINC);
    SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_eAmmoType.iDecoy);
}

public void GetAmmoTypes()
{
    g_eAmmoType.iHE = GetAmmoType("weapon_hegrenade");
    g_eAmmoType.iSmoke = GetAmmoType("weapon_smokegrenade");
    g_eAmmoType.iFlesh = GetAmmoType("weapon_flashbang");
    g_eAmmoType.iMolotov = GetAmmoType("weapon_molotov");
    g_eAmmoType.iINC = GetAmmoType("weapon_incgrenade");
    g_eAmmoType.iDecoy = GetAmmoType("weapon_decoy");
    g_eAmmoType.bIsSet = true;
}

int GetAmmoType(const char[] classname)
{
    int ent = CreateEntityByName(classname);
    DispatchSpawn(ent);
    int type = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
    AcceptEntityInput(ent, "Kill");
    return type;
}

public Action TimerPlayerSpawn(Handle timer, int client)
{
    if(IsPlayerAlive(client))
        GivePlayerGrenades(client);
    return Plugin_Continue;
}

public void GivePlayerGrenades(int client)
{
    if(!g_eAmmoType.bIsSet)
        GetAmmoTypes();

    int iCount;
    if(g_eGrenadeSet[client].iDecoy)
    {
        iCount = g_eGrenadeSet[client].iDecoy-GetEntProp(client, Prop_Send, "m_iAmmo", _, g_eAmmoType.iDecoy);
        for(int i; i < iCount; i++)
            GivePlayerItem(client, "weapon_decoy");
    }

    if(g_eGrenadeSet[client].iHE)
    {
        iCount = g_eGrenadeSet[client].iHE-GetEntProp(client, Prop_Send, "m_iAmmo", _, g_eAmmoType.iHE);
        for(int i; i < iCount; i++)
            GivePlayerItem(client, "weapon_hegrenade");
    }

    if(g_eGrenadeSet[client].iSmoke)
    {
        iCount = g_eGrenadeSet[client].iSmoke-GetEntProp(client, Prop_Send, "m_iAmmo", _, g_eAmmoType.iSmoke);
        for(int i; i < iCount; i++)
            GivePlayerItem(client, "weapon_smokegrenade");
    }

    if(g_eGrenadeSet[client].iFlesh)
    {
        iCount = g_eGrenadeSet[client].iFlesh-GetEntProp(client, Prop_Send, "m_iAmmo", _, g_eAmmoType.iFlesh);
        for(int i; i < iCount; i++)
            GivePlayerItem(client, "weapon_flashbang");
    }

    if(g_eGrenadeSet[client].iMolotov)
    {
        iCount = g_eGrenadeSet[client].iMolotov-GetEntProp(client, Prop_Send, "m_iAmmo", _, g_eAmmoType.iMolotov);
        if(GetClientTeam(client) == 2)
            for(int i; i < iCount; i++)
                GivePlayerItem(client, "weapon_molotov");
        else
            for(int i; i < iCount; i++)
                GivePlayerItem(client, "weapon_incgrenade");
    }

}

public void OnClientDisconnect(int client)
{
    if(!AreClientCookiesCached(client))
        return;

    char sBuffer[16];
    Format(sBuffer, sizeof(sBuffer), "%i;%i;%i;%i;%i", g_eGrenadeSet[client].iDecoy, g_eGrenadeSet[client].iHE, g_eGrenadeSet[client].iMolotov, g_eGrenadeSet[client].iSmoke, g_eGrenadeSet[client].iFlesh);
    SetClientCookie(client, COOKIE_Grenades, sBuffer);
}

public void OnClientCookiesCached(int client)
{
    char sBuffer[32], sBufferSplit[8][4];
    GetClientCookie(client, COOKIE_Grenades, sBuffer, sizeof(sBuffer));
    if(IsEmptyString(sBuffer))
        return;
    ExplodeString(sBuffer, ";", sBufferSplit, 6, 4);
    g_eGrenadeSet[client].iDecoy = StringToInt(sBufferSplit[0]);
    g_eGrenadeSet[client].iHE =  StringToInt(sBufferSplit[1]);
    g_eGrenadeSet[client].iMolotov =  StringToInt(sBufferSplit[2]);
    g_eGrenadeSet[client].iSmoke =  StringToInt(sBufferSplit[4]);
    g_eGrenadeSet[client].iFlesh =  StringToInt(sBufferSplit[5]);
}

bool IsValidClient(int client)
{
    if (client <= 0)return false;
    if (client > MaxClients)return false;
    if (!IsClientConnected(client))return false;
    if (IsFakeClient(client))return false;
    return IsClientInGame(client);
}

bool IsVip(int client)
{
    if(IsEmptyString(g_eSettings.sVipFlag) || GetUserFlagBits(client) & ReadFlagString(g_eSettings.sVipFlag) || GetUserFlagBits(client) & ADMFLAG_ROOT)
        return true;
    return false;
}

bool IsGrenade(CSWeaponID weapon)
{
    for(int i; i < sizeof(g_iGrenadesIDs); i++)
    {
        if(g_iGrenadesIDs[i] == weapon)
            return true;
    }
    return false;
}

void DeleteWeapon(int client, int weapon)
{
    SDKHooks_DropWeapon(client, weapon);
    RemoveEntity(weapon);
}

CSWeaponID GetWeaponEntityID(int weapon)
{
    if (weapon <= MaxClients)
        return CSWeapon_NONE;

    int def = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    return CS_ItemDefIndexToID(def);
}

stock bool IsEmptyString(const char[] string) 
{
	return (!string[0]);
}