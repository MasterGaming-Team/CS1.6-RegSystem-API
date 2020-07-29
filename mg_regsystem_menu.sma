#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core>
#include <mg_regsystem_api>

#define PLUGIN "[MG] Regsystem Menu"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define flag_get(%1,%2) %1 & ((1 << (%2 & 31)))
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new gUsername[33][MAX_USERNAME_LENGTH+1], gPassword[33][MAX_PASSWORD_LENGTH+1], gPasswordCheck[33][MAX_PASSWORD_LENGTH+1], gEMail[33][MAX_EMAIL_LENGTH+1]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	mg_core_command_reg("reg", "cmdReg")
	mg_core_command_reg("login", "cmdReg")
	mg_core_command_reg("register", "cmdReg")	

	register_clcmd("USERNAME_L", "msgLoginUsername")
	register_clcmd("PASSWORD_L", "msgLoginPassword")
	register_clcmd("USERNAME_R", "msgRegUsername")
	register_clcmd("PASSWORD1_R", "msgRegPassword")
	register_clcmd("PASSWORD2_R", "msgRegPasswordCheck")
	register_clcmd("EMAIL_R", "msgRegEMail")	

	register_menu("RegUserInfo Menu", KEYSMENU, "menu_userinfo")
	register_menu("RegLoggedIn Menu", KEYSMENU, "menu_loggedin")
	register_menu("RegLogin Menu", KEYSMENU, "menu_login")
	register_menu("RegRegister Menu", KEYSMENU, "menu_register")

	register_dictionary("mg_regsystem.txt")
}

public cmdReg(id)
{
	if(!show_menu_loggedin(id))
		show_menu_userinfo(id)
	
	return PLUGIN_HANDLED
}

show_menu_loggedin(id)
{
	if(!is_user_connected(id) || !mg_reg_user_loggedin(id))
		return false
		
	new menu[500], title[60], len

	mg_core_menu_title_create(id, "REG_TITLE_LOGGEDIN", title, charsmax(title))
			
	len += formatex(menu[len], charsmax(menu) - len, "%s^n", title)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "REG_MENU_LOGGEDIN1")
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L: %L^n", id, "REG_MENU_LOGGEDIN5", id, mg_reg_user_setting_get(id) ? "REG_MENU_SETTINGON":"REG_MENU_SETTINGOFF")
	if(mg_reg_user_setting_get(id))
	{
		len += formatex(menu[len], charsmax(menu) - len, "\r   6.\w %L: %L^n", id, "REG_MENU_LOGGEDIN6", id, mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINAUTHID) ? "REG_MENU_SETTINGON":"REG_MENU_SETTINGOFF")
		len += formatex(menu[len], charsmax(menu) - len, "\r   7.\w %L: %L^n", id, "REG_MENU_LOGGEDIN7", id, mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINNAME) ? "REG_MENU_SETTINGON":"REG_MENU_SETTINGOFF")
		len += formatex(menu[len], charsmax(menu) - len, "\r   8.\w %L: %L^n", id, "REG_MENU_LOGGEDIN8", id, mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINSETINFO) ? "REG_MENU_SETTINGON":"REG_MENU_SETTINGOFF")
	}
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "REG_MENU_BACKTOMAIN")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "RegLoggedIn Menu")
	
	return true
}

public menu_loggedin(id, key)
{
	switch(key)
	{
		case 0:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGOUTPROCESS")
			mg_reg_user_logout(id)
		}
		case 4:
		{
			if(mg_reg_user_setting_get(id))
			{
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, false)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, false)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, false)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, false)
			}
			else
			{
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, true)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, true)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, true)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, true)
			}
			show_menu_loggedin(id)
		}
		case 5:
		{
			if(mg_reg_user_setting_get(id))
			{
				if(mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINAUTHID))
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, false)
				else
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, true)
			}
			show_menu_loggedin(id)
		}
		case 6:
		{
			if(mg_reg_user_setting_get(id))
			{
				if(mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINNAME))
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, false)
				else
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, true)
			}
			show_menu_loggedin(id)
		}
		case 7:
		{
			checkUserSetinfoPW(id)

			if(mg_reg_user_setting_get(id))
			{
				if(mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINSETINFO))
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, false)
				else
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, true)
			}
			show_menu_loggedin(id)
		}
	}
	
	return PLUGIN_HANDLED
}

show_menu_userinfo(id)
{
	if(!is_user_connected(id) || mg_reg_user_loggedin(id))
		return false
		
	new menu[500], title[60], len
	
	mg_core_menu_title_create(id, "REG_TITLE_USERINFO", title, charsmax(title))

	len += formatex(menu[len], charsmax(menu) - len, "%s^n", title)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "REG_MENU_USERINFO1")
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "REG_MENU_USERINFO2")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "REG_MENU_USERINFO4")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "REG_MENU_BACKTOMAIN")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "RegUserInfo Menu")
	
	return true
}

public menu_userinfo(id, key)
{
	switch(key)
	{
		case 0: show_menu_login(id)
		case 1: show_menu_register(id)
		case 2:
		{
			// IDE NYELVVÁLTÁST
			show_menu_userinfo(id)
		}
		//case 9: mód főmenüjének megnyitása
	}
	
	return PLUGIN_HANDLED
}

show_menu_login(id)
{
	if(!is_user_connected(id) || mg_reg_user_loggedin(id))
		return false
		
	new menu[500], title[60], len

	mg_core_menu_title_create(id, "REG_TITLE_LOGIN", title, charsmax(title))
			
	len += formatex(menu[len], charsmax(menu) - len, "%s^n", title)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	
	if(gUsername[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L \r%s^n", id, "REG_MENU_LOGIN1", gUsername[id])
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L \r%L^n", id, "REG_MENU_LOGIN1", id, "REG_MENU_NOUSERNAME")
	
	if(gPassword[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L \r*****^n", id, "REG_MENU_LOGIN2")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L \r%L^n", id, "REG_MENU_LOGIN2", id, "REG_MENU_NOPASSWORD")
	
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "REG_MENU_LOGIN3")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L^n", id, "REG_MENU_LOGIN4")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "REG_MENU_STEPBACK")
			
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "RegLogin Menu")
	
	return true
}

public menu_login(id, key)
{
	if(mg_reg_user_loggedin(id))
		return PLUGIN_HANDLED

	switch(key)
	{
		case 0:
		{
			client_cmd(id, "messagemode USERNAME_L")
		}
		case 1:
		{
			client_cmd(id, "messagemode PASSWORD_L")
		}
		case 2:
		{
			if(mg_reg_user_loading(id))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
				show_menu_login(id)
				return PLUGIN_HANDLED
			}
			
			if(!gUsername[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOUSERNAMEGIVEN")
				show_menu_login(id)
				return PLUGIN_HANDLED
			}
			
			if(!gPassword[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOPASSWORDGIVEN")
				show_menu_login(id)
				return PLUGIN_HANDLED
			}
			
			new lHashPassword[33]
			hash_string(gPassword[id], Hash_Md5, lHashPassword, charsmax(lHashPassword))

			mg_reg_user_login(id, gUsername[id], lHashPassword)
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINPLSWAIT")
		}
		case 3:
		{
			// IDE NYELVVÁLTÁST
			show_menu_login(id)
		}
		case 9:
		{
			show_menu_userinfo(id)
		}
	}
	
	return PLUGIN_HANDLED
}

show_menu_register(id)
{
	if(!is_user_connected(id) || mg_reg_user_loggedin(id))
		return false
		
	new menu[500], title[60], len

	mg_core_menu_title_create(id, "REG_TITLE_REGISTER", title, charsmax(title))
			
	len += formatex(menu[len], charsmax(menu) - len, "%s^n", title)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	
	if(gUsername[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L \r%s^n", id, "REG_MENU_REGISTER1", gUsername[id])
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L \r%L^n", id, "REG_MENU_REGISTER1", id, "REG_MENU_NOUSERNAME")
	
	if(gPassword[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L \r*****^n", id, "REG_MENU_REGISTER2")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L \r%L^n", id, "REG_MENU_REGISTER2", id, "REG_MENU_NOPASSWORD")
	
	
	if(gPasswordCheck[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L \r*****^n", id, "REG_MENU_REGISTER3")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L \r%L^n", id, "REG_MENU_REGISTER3", id, "REG_MENU_NOPASSWORD")

	if(gEMail[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L \r%s^n", id, "REG_MENU_REGISTER4", gEMail[id])
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L \r%s^n", id, "REG_MENU_REGISTER4", "......@****.***")
	
	len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n", id, "REG_MENU_REGISTER5")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w %L^n", id, "REG_MENU_REGISTER6")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "REG_MENU_STEPBACK")
			
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "RegRegister Menu")
	
	return true
}

public menu_register(id, key)
{
	if(mg_reg_user_loggedin(id))
		return PLUGIN_HANDLED
	
	switch(key)
	{
		case 0:
		{
			client_cmd(id, "messagemode USERNAME_R")
		}
		case 1:
		{
			client_cmd(id, "messagemode PASSWORD1_R")
		}
		case 2:
		{
			client_cmd(id, "messagemode PASSWORD2_R")
		}
		case 3:
		{
			client_cmd(id, "messagemode EMAIL_R")
		}
		case 4:
		{
			if(mg_reg_user_loading(id))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
				show_menu_login(id)
				return PLUGIN_HANDLED
			}
			
			if(!gUsername[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOUSERNAMEGIVEN")
				show_menu_register(id)
				return PLUGIN_HANDLED
			}
			
			if(!gPassword[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOPASSWORDGIVEN")
				show_menu_register(id)
				return PLUGIN_HANDLED
			}
			
			if(!gPasswordCheck[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOPASSWORD2GIVEN")
				show_menu_register(id)
				return PLUGIN_HANDLED
			}

			if(!gEMail[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_EMAILGIVEN")
				show_menu_register(id)
				return PLUGIN_HANDLED
			}
			
			if(!equal(gPassword[id], gPasswordCheck[id]))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_PASSWORDSNOTSAME")
				show_menu_register(id)
				return PLUGIN_HANDLED
			}
			
			new lHashPassword[33]
			hash_string(gPassword[id], Hash_Md5, lHashPassword, charsmax(lHashPassword))

			mg_reg_user_register(id, gUsername[id], lHashPassword, gEMail[id])
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGPLSWAIT")
		}
		case 5:
		{
			// IDE NYELVVÁLTÁST
			show_menu_register(id)
		}
		case 9:
		{
			show_menu_userinfo(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public msgLoginUsername(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		show_menu_login(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)

		copy(gUsername[id], charsmax(gUsername[]), msg) 
	}
	
	show_menu_login(id)
	return PLUGIN_HANDLED
}

public msgLoginPassword(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		show_menu_login(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		copy(gPassword[id], charsmax(gPassword[]), msg) 
	}
	
	show_menu_login(id)
	return PLUGIN_HANDLED
}

public msgRegUsername(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		show_menu_register(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)

		if(strlen(msg) > MAX_USERNAME_LENGTH || strlen(msg) < MIN_USERNAME_LENGTH)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDSIZE", MAX_USERNAME_LENGTH, MIN_USERNAME_LENGTH)
			show_menu_register(id)
			return PLUGIN_HANDLED
		}

		copy(gUsername[id], charsmax(gUsername[]), msg) 
	}
	
	show_menu_register(id)
	return PLUGIN_HANDLED
}

public msgRegPassword(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		show_menu_register(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		
		if(strlen(msg) > MAX_PASSWORD_LENGTH || strlen(msg) < MIN_PASSWORD_LENGTH)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDSIZE", MAX_PASSWORD_LENGTH, MIN_PASSWORD_LENGTH)
			show_menu_register(id)
			return PLUGIN_HANDLED
		}

		copy(gPassword[id], charsmax(gPassword[]), msg) 
	}
	
	show_menu_register(id)
	return PLUGIN_HANDLED
}

public msgRegPasswordCheck(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		show_menu_register(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		copy(gPasswordCheck[id], charsmax(gPasswordCheck[]), msg) 
	}
	
	show_menu_register(id)
	return PLUGIN_HANDLED
}

public msgRegEMail(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		show_menu_register(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)

		if(strlen(msg) > MAX_EMAIL_LENGTH || strlen(msg) < MIN_EMAIL_LENGTH)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDSIZE", MAX_EMAIL_LENGTH, MIN_EMAIL_LENGTH)
			show_menu_register(id)
			return PLUGIN_HANDLED
		}

		if(contain(msg, "@") == -1 || contain(msg, ".") == -1)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDEMAIL")
			show_menu_register(id)
			return PLUGIN_HANDLED
		}

		copy(gEMail[id], charsmax(gEMail[]), msg) 
	}
	
	show_menu_register(id)
	return PLUGIN_HANDLED
}

public mg_fw_client_register_failed(id, errorType)
{
	switch(errorType)
	{
		case ERROR_SQL_ERROR:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGSQLERROR", "SQLERROR_REG")
			show_menu_register(id)
		}
		case ERROR_ACCOUNT_USED:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGUSERNAMETAKEN")
			show_menu_register(id)
		}
	}
}

public mg_fw_client_register_success(id)
{
	new lHashPassword[33]

	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGSUCCESSFUL")
	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINLOADING")

	hash_string(gPassword[id], Hash_Md5, lHashPassword, charsmax(lHashPassword))

	mg_reg_user_login(id, gUsername[id], lHashPassword)
}

public mg_fw_client_login_failed(id, errorType)
{
	switch(errorType)
	{
		case ERROR_ACCOUNT_NOT_FOUND:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINNOSUCHACCOUNT")
			show_menu_login(id)
		}
		case ERROR_SQL_ERROR:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINSQLERROR", "SQLERROR_LOGIN")
			show_menu_login(id)
		}
		case ERROR_ACCOUNT_USED:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINACCOUNTINUSE")
			show_menu_login(id)
		}
	}
}

public mg_fw_client_login_success(id)
{
	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINSUCCESSFUL")
}

public mg_fw_client_logout(id)
{
	gUsername[id][0] = EOS
	gPassword[id][0] = EOS
	gPasswordCheck[id][0] = EOS
	gEMail[id][0] = EOS
	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGOUT")
}

public client_connect(id)
{
	client_clean(id)
}

public client_disconnected(id)
{
	client_clean(id)
}

client_clean(id)
{
	gUsername[id][0] = EOS
	gPassword[id][0] = EOS
	gEMail[id][0] = EOS
}

checkUserSetinfoPW(id)
{
	new lSetinfoPW[33]
	get_user_info(id, "_pw", lSetinfoPW, charsmax(lSetinfoPW))

	if(!lSetinfoPW[0])
	{
		GenerateString(lSetinfoPW, 8)
		set_user_info(id, "_pw", lSetinfoPW)
		client_print(id, print_chat, "trueee")
	}
	client_print(id, print_chat, "%s", lSetinfoPW)
}

//By Exolent[jNr]
GenerateString(output[], const len)
{
	new choices[62] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWYZ0123456789"

	for(new i = 0; i < len; i++)
	{
		output[i] = choices[random(charsmax(choices))]
	}
    
	return len
}