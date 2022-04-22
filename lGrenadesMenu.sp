#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

#define DEBUG

#define PLUGIN_AUTHOR "lukash"
#define PLUGIN_VERSION "1.1.1"
#define PLUGIN_NAME "lGrenadesMenu"
#define PLUGIN_DESCRIPTION "Pozwala VIPom ustawić sobie 4 granaty"
#define PLUGIN_URL "https://steamcommunity.com/id/lukasz11772/"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

Handle COOKIE_Flash;
Handle COOKIE_HE;
Handle COOKIE_Smoke;
Handle COOKIE_FireGrenade;
Handle COOKIE_Decoy;

int g_iHe[MAXPLAYERS + 1] = 0;
int g_iFlash[MAXPLAYERS + 1] = 0;
int g_iSmoke[MAXPLAYERS + 1] = 0;
int g_iFire[MAXPLAYERS + 1]  = 0;
int g_iDec[MAXPLAYERS + 1] = 0;
int g_iSlots[MAXPLAYERS + 1] = 4;

int g_iOShe;
int g_iOSflash;
int g_iOSsmoke;
int g_iOSinc;
int g_iOSmol;
int g_iOSdec;

int iRounds = 0;

ConVar cv_VipFlag;
ConVar cv_Rounds;

public void OnPluginStart()
{
    RegConsoleCmd("sm_granaty", CMD_GrenadesMenu);
    RegConsoleCmd("sm_grenades", CMD_GrenadesMenu);

    HookEvent("player_spawn", OnPlayerSpawn);

    HookEvent("round_start", OnRoundStart);

    HookEvent("announce_phase_end", ResetAfterTeamChange);
	HookEvent("cs_intermission", ResetAfterTeamChange);
	HookEvent("cs_match_end_restart", ResetAfterTeamChange);

    COOKIE_Flash = RegClientCookie("sm_flash", "Zapisuje czy gracz wybrał flasha", CookieAccess_Private);
    COOKIE_HE = RegClientCookie("sm_he", "Zapisuje czy gracz wybrał he", CookieAccess_Private);
    COOKIE_Smoke = RegClientCookie("sm_smoke", "Zapisuje czy gracz wybrał smoke", CookieAccess_Private);
    COOKIE_FireGrenade = RegClientCookie("sm_firegrenade", "Zapisuje czy gracz wybrał granat podpalajacy", CookieAccess_Private);
    COOKIE_Decoy = RegClientCookie("sm_decoy", "Zapisuje czy gracz wybrał decoy", CookieAccess_Private);

    AddCommandListener(RestartGame_Callback, "mp_restartgame");
	AddCommandListener(RestartGame_Callback, "mp_swapteams");

    cv_VipFlag = CreateConVar("gr_flag", "o", "Jaką flage musi posiadać gracz aby widzieć | \"\" = Dla każdego");
    cv_Rounds = CreateConVar("gr_Rounds", "4", "Od której rundy ma dawać granaty?");

    AutoExecConfig(true, "lGrenadesMenu");
}

public Action RestartGame_Callback(int client, const char[] command, int argc)
{
	iRounds = 0;
    return Plugin_Continue;
}

public Action CMD_GrenadesMenu(int client, int args)
{
    if(!IsVIP(client))
    {
        PrintToChat(client, "ERROR! Ta komenda jest zadedykowana tylko VIP'om!");
        return;
    }
    CMD_GrenadesMenuAdd(client);
}

public void CMD_GrenadesMenuAdd(int client)
{
    char sTitle[128];
    char sItem[128];
    Format(sTitle, sizeof(sTitle), "» Witaj %N, wybierz działania", client);
    Format(sTitle, sizeof(sTitle), "%s\n» Ilość dostępnych slotów: %i", sTitle, g_iSlots[client]);
    Menu Add = new Menu(Add_Handler);
    Add.SetTitle(sTitle);
    Add.AddItem("remove", "» [ ] Usuwanie");
    Format(sItem, sizeof(sItem), "» [%i/1] HE", g_iHe[client]);
    if(g_iHe[client] >= 1 || g_iSlots[client] <= 0)
        Add.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Add.AddItem("1", sItem);

    Format(sItem, sizeof(sItem), "» [%i/2] Flash", g_iFlash[client]);
    if(g_iFlash[client] >= 2 || g_iSlots[client] <= 0)
        Add.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Add.AddItem("2", sItem);

    Format(sItem, sizeof(sItem), "» [%i/1] Smoke", g_iSmoke[client]);
    if(g_iSmoke[client] >= 1 || g_iSlots[client] <= 0)
        Add.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Add.AddItem("3", sItem);

    Format(sItem, sizeof(sItem), "» [%i/1] Molotov/INC", g_iFire[client]);
    if(g_iFire[client] >= 1 || g_iSlots[client] <= 0)
        Add.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Add.AddItem("4", sItem);

    Format(sItem, sizeof(sItem), "» [%i/1] Decoy", g_iDec[client]);
    if(g_iDec[client] >= 1 || g_iSlots[client] <= 0)
        Add.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Add.AddItem("5", sItem);
    Add.Display(client, 60);
}

public int Add_Handler(Menu Add, MenuAction action, int client, int Position)
{
    if(action == MenuAction_Select)
    {
	    char Item[32];
	    Add.GetItem(Position, Item, sizeof(Item));
	    if(StrEqual(Item, "1"))
	    {
            g_iHe[client]++;
            g_iSlots[client]--;
            CMD_GrenadesMenuAdd(client);
        }
        else if(StrEqual(Item, "2"))
	    {
            g_iFlash[client]++;
            g_iSlots[client]--;
            CMD_GrenadesMenuAdd(client);
        }
        else if(StrEqual(Item, "3"))
	    {
            g_iSmoke[client]++;
            g_iSlots[client]--;
            CMD_GrenadesMenuAdd(client);
        }
        else if(StrEqual(Item, "4"))
	    {
            g_iFire[client]++;
            g_iSlots[client]--;
            CMD_GrenadesMenuAdd(client);
        }
        else if(StrEqual(Item, "5"))
	    {
            g_iDec[client]++;
            g_iSlots[client]--;
            CMD_GrenadesMenuAdd(client);
        }
        else if(StrEqual(Item, "remove"))
	    {
            CMD_GrenadesMenuRemove(client);
        }

    }
    else if(action == MenuAction_End)
    	delete Add;
}

public void CMD_GrenadesMenuRemove(int client)
{
    char sTitle[128];
    char sItem[128];
    Format(sTitle, sizeof(sTitle), "» Witaj %N, wybierz działania", client);
    Format(sTitle, sizeof(sTitle), "%s\n» Ilość dostępnych slotów: %i", sTitle, g_iSlots[client]);
    Menu Remove = new Menu(Remove_Handler);
    Remove.SetTitle(sTitle);
    Remove.AddItem("remove", "» [X] Usuwanie");
    Format(sItem, sizeof(sItem), "» [%i/1] HE", g_iHe[client]);
    if(g_iHe[client] <= 0)
        Remove.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Remove.AddItem("1", sItem);

    Format(sItem, sizeof(sItem), "» [%i/2] Flash", g_iFlash[client]);
    if(g_iFlash[client] <= 0)
        Remove.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Remove.AddItem("2", sItem);

    Format(sItem, sizeof(sItem), "» [%i/1] Smoke", g_iSmoke[client]);
    if(g_iSmoke[client] <= 0)
        Remove.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Remove.AddItem("3", sItem);

    Format(sItem, sizeof(sItem), "» [%i/1] Molotov/INC", g_iFire[client]);
    if(g_iFire[client] <= 0)
        Remove.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Remove.AddItem("4", sItem);

    Format(sItem, sizeof(sItem), "» [%i/1] Decoy", g_iDec[client]);
    if(g_iDec[client] <= 0)
        Remove.AddItem("", sItem, ITEMDRAW_DISABLED);
    else
        Remove.AddItem("5", sItem);
    Remove.Display(client, 60);
}

public int Remove_Handler(Menu Remove, MenuAction action, int client, int Position)
{
    if(action == MenuAction_Select)
    {
	    char Item[32];
	    Remove.GetItem(Position, Item, sizeof(Item));
	    if(StrEqual(Item, "1"))
	    {
            g_iHe[client]--;
            g_iSlots[client]++;
            CMD_GrenadesMenuRemove(client);
        }
        else if(StrEqual(Item, "2"))
	    {
            g_iFlash[client]--;
            g_iSlots[client]++;
            CMD_GrenadesMenuRemove(client);
        }
        else if(StrEqual(Item, "3"))
	    {
            g_iSmoke[client]--;
            g_iSlots[client]++;
            CMD_GrenadesMenuRemove(client);
        }
        else if(StrEqual(Item, "4"))
	    {
            g_iFire[client]--;
            g_iSlots[client]++;
            CMD_GrenadesMenuRemove(client);
        }
        else if(StrEqual(Item, "5"))
	    {
            g_iDec[client]--;
            g_iSlots[client]++;
            CMD_GrenadesMenuRemove(client);
        }
        else if(StrEqual(Item, "remove"))
	    {
            CMD_GrenadesMenuAdd(client);
        }

    }
    else if(action == MenuAction_End)
    	delete Remove;
}

public void OnMapStart()
{
    iRounds = 0;
    GrenadeOffsets();
}

public void GrenadeOffsets()
{
	int ent;
	
	ent = CreateEntityByName("weapon_hegrenade");
	DispatchSpawn(ent);
	g_iOShe = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
	AcceptEntityInput(ent, "Kill");
	
	ent = CreateEntityByName("weapon_flashbang");
	DispatchSpawn(ent);
	g_iOSflash = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
	AcceptEntityInput(ent, "Kill");
	
	ent = CreateEntityByName("weapon_smokegrenade");
	DispatchSpawn(ent);
	g_iOSsmoke = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
	AcceptEntityInput(ent, "Kill");
	
	ent = CreateEntityByName("weapon_incgrenade");
	DispatchSpawn(ent);
	g_iOSinc = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
	AcceptEntityInput(ent, "Kill");
	
	ent = CreateEntityByName("weapon_molotov");
	DispatchSpawn(ent);
	g_iOSmol = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
	AcceptEntityInput(ent, "Kill");
	
	ent = CreateEntityByName("weapon_decoy");
	DispatchSpawn(ent);
	g_iOSdec = GetEntProp(ent, Prop_Send, "m_iPrimaryAmmoType");
	AcceptEntityInput(ent, "Kill");
}

public Action OnRoundStart(Event event, const char[] name, bool DontBroadcast)
{
    if(GameRules_GetProp("m_bWarmupPeriod") != 1)
		iRounds =  CS_GetTeamScore(CS_TEAM_T) + CS_GetTeamScore(CS_TEAM_CT);
}

public Action ResetAfterTeamChange(Event event, const char[] name, bool DontBroadcast)
{
	iRounds = 0;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool DontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(((iRounds >= cv_Rounds.IntValue && iRounds <= 15) || cv_Rounds.IntValue <= iRounds-15) && IsVIP(client) && GameRules_GetProp("m_bWarmupPeriod") != 1)
        CreateTimer(1.0, TimerPlayerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerPlayerSpawn(Handle timer, int client)
{
	if(GetEntProp(client, Prop_Send, "m_iAmmo", _, g_iOShe) < 1)
        if(g_iHe[client] > 0)
            GivePlayerItem(client, "weapon_hegrenade");

	if(GetEntProp(client, Prop_Send, "m_iAmmo", _, g_iOSflash) < 1)
        if(g_iFlash[client] > 0)
            for(int i = 1; i <= g_iFlash[client]; i++)
                GivePlayerItem(client, "weapon_flashbang");
	
	if(GetEntProp(client, Prop_Send, "m_iAmmo", _, g_iOSsmoke) < 1)
        if(g_iSmoke[client] > 0)
            GivePlayerItem(client, "weapon_smokegrenade");
	
	if (GetEntProp(client, Prop_Send, "m_iAmmo", _, g_iOSdec) < 1)
        if(g_iDec[client] > 0)
            GivePlayerItem(client, "weapon_decoy");
	
	if(GetEntProp(client, Prop_Send, "m_iAmmo", _, g_iOSinc) < 1 && GetEntProp(client, Prop_Send, "m_iAmmo", _, g_iOSmol) < 1)
        if(g_iFire[client] > 0) 
        {
            if(GetClientTeam(client) == CS_TEAM_CT)
                GivePlayerItem(client, "weapon_incgrenade");
            else if(GetClientTeam(client) == CS_TEAM_T)
                GivePlayerItem(client, "weapon_molotov");
        }
}

public void OnClientPutInServer(int client)
{
    char sBuffer[4];
    GetClientCookie(client, COOKIE_HE, sBuffer, sizeof(sBuffer));
    g_iHe[client] = StringToInt(sBuffer);

    GetClientCookie(client, COOKIE_Flash, sBuffer, sizeof(sBuffer));
    g_iFlash[client] = StringToInt(sBuffer);

    GetClientCookie(client, COOKIE_Smoke, sBuffer, sizeof(sBuffer));
    g_iSmoke[client] = StringToInt(sBuffer);

    GetClientCookie(client, COOKIE_FireGrenade, sBuffer, sizeof(sBuffer));
    g_iFire[client] = StringToInt(sBuffer);

    GetClientCookie(client, COOKIE_Decoy, sBuffer, sizeof(sBuffer));
    g_iDec[client] = StringToInt(sBuffer);

    g_iSlots[client] = 4;
    g_iSlots[client] = g_iSlots[client] - g_iHe[client] - g_iFlash[client] - g_iSmoke[client] - g_iFire[client] - g_iDec[client];
}

public void OnClientDisconnect(int client)
{
    char sBuffer[4];
    IntToString(g_iHe[client], sBuffer, sizeof(sBuffer));
    SetClientCookie(client, COOKIE_HE, sBuffer);

    IntToString(g_iFlash[client], sBuffer, sizeof(sBuffer));
    SetClientCookie(client, COOKIE_Flash, sBuffer);

    IntToString(g_iSmoke[client], sBuffer, sizeof(sBuffer));
    SetClientCookie(client, COOKIE_Smoke, sBuffer);

    IntToString(g_iFire[client], sBuffer, sizeof(sBuffer));
    SetClientCookie(client, COOKIE_FireGrenade, sBuffer);

    IntToString(g_iDec[client], sBuffer, sizeof(sBuffer));
    SetClientCookie(client, COOKIE_Decoy, sBuffer);
}

bool IsVIP(int client)
{
    char sFlag[10];
	GetConVarString(cv_VipFlag, sFlag, sizeof(sFlag));
    if(StrEqual(sFlag, "") || strlen(sFlag) <= 0)
        return true;
    if(GetUserFlagBits(client) & ReadFlagString(sFlag) || GetUserFlagBits(client) & ADMFLAG_ROOT)
        return true;
    return false;
}