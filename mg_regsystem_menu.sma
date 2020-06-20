#include <amxmodx>
#include <amxmisc>
#include <mg_regsystem_api>

#define PLUGIN "[MG] Regsystem Menu"
#define VERSION "1.0"
#define AUTHOR "Vieni"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("USERNAME_L", "msgLoginUsername")
	register_clcmd("PASSWORD_L", "msgLoginPassword")
	register_clcmd("USERNAME_R", "msgRegUsername")
	register_clcmd("PASSWORD1_R", "msgRegPassword")
	register_clcmd("PASSWORD2_R", "msgRegPasswordCheck")
    register_clcmd("EMAIL_R", "msgRegEmail")
	register_clcmd("PASSWORD_A", "msgAutologinPassword")
}

public msgLoginUsername(id)
{
	if(flag_get(gLoadingUser, id))
	{
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_USERSLOADING")
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
	if(flag_get(gLoadingUser, id))
	{
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_USERSLOADING")
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
	if(flag_get(gLoadingUser, id))
	{
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_USERSLOADING")
		show_menu_register(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		copy(gUsername[id], charsmax(gUsername[]), msg) 
	}
	
	show_menu_register(id)
	return PLUGIN_HANDLED
}

public msgRegPassword(id)
{
	if(flag_get(gLoadingUser, id))
	{
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_USERSLOADING")
		show_menu_register(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		copy(gPassword[id], charsmax(gPassword[]), msg) 
	}
	
	show_menu_register(id)
	return PLUGIN_HANDLED
}

public msgRegPasswordCheck(id)
{
	if(flag_get(gLoadingUser, id))
	{
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_USERSLOADING")
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

public msgAutologinPassword(id)
{
	if(flag_get(gLoadingUser, id))
	{
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_USERSLOADING")
		show_menu_loggedin(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		
		if(equal(gPassword[id], msg))
		{
			client_cmd(id, "setinfo ^"_ebareg^" ^"%s//%s^"", gUsername[id], gPassword[id])
			eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_AUTOLOGIN", gUsername[id], gPassword[id])
		}
	}
	else
		eba_cmessage(id, CM_FIX, "%s%L", chatPrefix, id, "CHAT_WRONGPASSWORD")
	
	show_menu_loggedin(id)
	return PLUGIN_HANDLED
}