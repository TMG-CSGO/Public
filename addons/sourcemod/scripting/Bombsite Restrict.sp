#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <autoexecconfig>

public Plugin myinfo = 
{
	name = "Bombsite Restrict", 
	author = "LanteJoula", 
	description = "Bombsite Restrict", 
	version = "1.2", 
	url = "https://steamcommunity.com/id/lantejoula/"
};

#define DEBUG

#pragma semicolon 1

#pragma newdecls required

//ENUM

enum
{
	BOMBSITE_INVALID = -1, 
	BOMBSITE_A = 0, 
	BOMBSITE_B = 1
}

// BOOL

bool BoolA = false;
bool BoolB = false;

bool BoolAMessage = true;
bool BoolBMessage = true;

// INT

int bombsite = BOMBSITE_INVALID;

// CONVARS

char g_ChatPrefix[256];
ConVar gConVar_Chat_Prefix;

ConVar gConVar_CTs;
ConVar gConVar_Announcer;
ConVar gConVar_Block;
ConVar gConVar_Messages;
ConVar gConVar_CountBots;

public void OnPluginStart()
{
	// TRANSLATIONS
	LoadTranslations("bombsite_restrict.phrases");
	
	// CONVARS
	AutoExecConfig_SetFile("plugin.bombsite_restrict");
	
	gConVar_Chat_Prefix = AutoExecConfig_CreateConVar("sm_bombsite_restrict_chat_prefix", "[ {green}TMG-BSr {default}]", "Chat Prefix");
	
	gConVar_Announcer = AutoExecConfig_CreateConVar("sm_bombsite_restrict_announcer", "2", "Bombsite Announcement ( 0 - Disable | 1 - Chat | 2 - Hud | 3 - Center | 4 - Hint )", 0, true, 0.0, true, 3.0);
	
	gConVar_CTs = AutoExecConfig_CreateConVar("sm_bombsite_restrict_cts", "5", "How many CTs does it have to be on the Server to Unlock Bombsites? ( Default = 4 )", 0, true, 1.0, true, 10.0);
	
	gConVar_Block = AutoExecConfig_CreateConVar("sm_bombsite_restrict_bombsite", "2", "Block which bombsite? ( 0 - Random Bombsite | 1 - Block Bombsite A | 2 - Block Bombsite B )", 0, true, 0.0, true, 2.0);
	
	gConVar_Messages = AutoExecConfig_CreateConVar("sm_bombsite_restrict_messages", "1", "Enable/Disable the Messages when Player try to Plant the Bomb on the Wrong Bombsite  (1 - Enable | 0 - Disable)", 0, true, 0.0, true, 1.0);
	
	gConVar_CountBots = AutoExecConfig_CreateConVar("sm_bombsite_restrict_countbots", "0", "Enable/Disable the Count Bots on CT Team (1 - Enable | 0 - Disable)", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	gConVar_Chat_Prefix.AddChangeHook(OnPrefixChange);
	
	// EVENTS	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

// PREFIX

public void SavePrefix()
{
	GetConVarString(gConVar_Chat_Prefix, g_ChatPrefix, sizeof(g_ChatPrefix));
}

public void OnConfigsExecuted()
{
	SavePrefix();
}

public void OnPrefixChange(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	SavePrefix();
}

// ROUND END

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	BoolA = false;
	BoolB = false;
	
	BoolAMessage = true;
	BoolBMessage = true;
}

// ROUND START

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (IsWarmup())
	{
		return;
	}
	
	if (CountCt() < gConVar_CTs.IntValue)
	{
		if (gConVar_Block.IntValue == 0) // RANDOM BOMBSITE
		{
			switch (GetRandomInt(1, 2))
			{
				case 1:
				{
					if (gConVar_Announcer.IntValue == 1)
						CPrintToChatAll("%s %t", g_ChatPrefix, "Bombsite A");
					
					if (gConVar_Announcer.IntValue == 2)
						CreateTimer(0.1, HudA);
					
					if (gConVar_Announcer.IntValue == 3)
						PrintCenterTextAll("%t", "Bombsite A");
					
					if (gConVar_Announcer.IntValue == 4)
						PrintHintTextToAll("%t", "Bombsite A");
					
					BoolB = true;
				}
				case 2:
				{
					if (gConVar_Announcer.IntValue == 1)
						CPrintToChatAll("%s %t", g_ChatPrefix, "Bombsite B");
					
					if (gConVar_Announcer.IntValue == 2)
						CreateTimer(0.1, HudB);
					
					if (gConVar_Announcer.IntValue == 3)
						PrintCenterTextAll("%t", "Bombsite B");
					
					if (gConVar_Announcer.IntValue == 4)
						PrintHintTextToAll("%t", "Bombsite B");
					
					BoolA = true;
				}
			}
		}
		
		if (gConVar_Block.IntValue == 1) // BLOCK BOMBSITE A
		{
			if (gConVar_Announcer.IntValue == 1)
				CPrintToChatAll("%s %t", g_ChatPrefix, "Bombsite B");
			
			if (gConVar_Announcer.IntValue == 2)
				CreateTimer(0.1, HudB);
			
			if (gConVar_Announcer.IntValue == 3)
				PrintCenterTextAll("%t", "Bombsite B");
			
			if (gConVar_Announcer.IntValue == 4)
				PrintHintTextToAll("%t", "Bombsite B");
			
			BoolA = true;
		}
		
		if (gConVar_Block.IntValue == 2) // BLOCK BOMBSITE B
		{
			if (gConVar_Announcer.IntValue == 1)
				CPrintToChatAll("%s %t", g_ChatPrefix, "Bombsite A");
			
			if (gConVar_Announcer.IntValue == 2)
				CreateTimer(0.1, HudA);
			
			if (gConVar_Announcer.IntValue == 3)
				PrintCenterTextAll("%t", "Bombsite A");
			
			if (gConVar_Announcer.IntValue == 4)
				PrintHintTextToAll("%t", "Bombsite A");
			
			BoolB = true;
		}
	}
	else
	{
		BoolA = false;
		BoolB = false;
	}
}

// HUD A

public Action HudA(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			SetHudTextParams(-1.0, -0.1, 3.0, 255, 50, 163, 100, 0, 1.0, 0.0, 0.0);
			ShowHudText(i, 1, "%t", "Bombsite A");
		}
	}
}

// HUD B

public Action HudB(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			SetHudTextParams(-1.0, -0.1, 3.0, 0, 255, 255, 100, 0, 1.0, 0.0, 0.0);
			ShowHudText(i, 1, "%t", "Bombsite B");
		}
	}
}

// BLOCK PLANT

public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	if (buttons & IN_ATTACK || buttons & IN_USE)
	{
		if (weapon != -1)
		{
			if (HasBomb(client))
			{
				if (GetEntProp(client, Prop_Send, "m_bInBombZone"))
				{
					bombsite = GetNearestBombsite(client);
					
					if (BoolA)
					{
						if (bombsite == BOMBSITE_A)
						{
							if (buttons & IN_ATTACK)
								buttons &= ~IN_ATTACK;
							
							if (buttons & IN_USE)
								buttons &= ~IN_USE;
							
							if (BoolAMessage)
							{
								if (gConVar_Messages.BoolValue)
									CPrintToChat(client, "%s %t", g_ChatPrefix, "Cant plant on bombsite A");
							}
							
							BoolAMessage = false;
							
							CreateTimer(3.0, ResetBoolMessage);
							
							return Plugin_Changed;
						}
					}
					
					if (BoolB)
					{
						if (bombsite == BOMBSITE_B)
						{
							if (buttons & IN_ATTACK)
								buttons &= ~IN_ATTACK;
							
							if (buttons & IN_USE)
								buttons &= ~IN_USE;
							
							if (BoolBMessage)
							{
								if (gConVar_Messages.BoolValue)
									CPrintToChat(client, "%s %t", g_ChatPrefix, "Cant plant on bombsite B");
							}
							
							BoolBMessage = false;
							
							CreateTimer(3.0, ResetBoolMessage);
							
							return Plugin_Changed;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

// TIMER RESET BOOL MESSAGE

public Action ResetBoolMessage(Handle timer)
{
	BoolAMessage = true;
	BoolBMessage = true;
}

// HAVE BOMB

stock bool HasBomb(int client)
{
	return GetPlayerWeaponSlot(client, 4) != -1;
}

// GET BOMBSITE

stock int GetNearestBombsite(int client)
{
	int playerResource = GetPlayerResourceEntity();
	
	if (playerResource == INVALID_ENT_REFERENCE)
	{
		return BOMBSITE_INVALID;
	}
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	float aCenter[3], bCenter[3];
	GetEntPropVector(playerResource, Prop_Send, "m_bombsiteCenterA", aCenter);
	GetEntPropVector(playerResource, Prop_Send, "m_bombsiteCenterB", bCenter);
	
	float aDist = GetVectorDistance(aCenter, pos, true);
	float bDist = GetVectorDistance(bCenter, pos, true);
	
	return (aDist < bDist) ? BOMBSITE_A : BOMBSITE_B;
}

// WARMUP

stock bool IsWarmup()
{
	return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

// NUMBER OF CTS

public int CountCt()
{
	int g_CTs = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			if (gConVar_CountBots.BoolValue)
			{
				if (!IsFakeClient(i))
					g_CTs++;
				
			}
			else
			{
				g_CTs++;
			}
		}
	}
	
	return g_CTs;
}

// ISVALIDCLIENT

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client));
}
