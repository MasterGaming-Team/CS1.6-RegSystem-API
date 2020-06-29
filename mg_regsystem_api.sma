/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_regsystem_api_const>
#include <sqlx>

#define PLUGIN "[MG] RegSystem API"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define TASKID1 615
#define TASKID2 4215

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new gAccountId[33], gGameTime[33]
new gLoggedIn, gAutoLogin, gLoadingUser

new Array:arrayUserLoadingSql[33]

new Handle:gSqlRegTuple

new gForwardClientSuccessRegister, gForwardClientFailedRegister
new gForwardClientSuccessLogin, gForwardClientProcessLogin, gForwardClientFailedLogin
new gForwardClientLogout
new gForwardClientClean, gForwardClientSqlSave

enum _:dataTypes
{
	dt_id,
	dt_username[MAX_USERNAME_LENGTH+1],
	dt_password[MAX_PASSWORD_LENGTH+1],
	dt_email[MAX_EMAIL_LENGTH+1]
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	gForwardClientSuccessRegister = CreateMultiForward("mg_fw_client_register_success", ET_CONTINUE, FP_CELL)
	gForwardClientFailedRegister = CreateMultiForward("mg_fw_client_register_failed", ET_CONTINUE, FP_CELL, FP_CELL)
	gForwardClientSuccessLogin = CreateMultiForward("mg_fw_client_login_success", ET_CONTINUE, FP_CELL)
	gForwardClientProcessLogin = CreateMultiForward("mg_fw_client_login_process", ET_CONTINUE, FP_CELL)
	gForwardClientFailedLogin = CreateMultiForward("mg_fw_client_login_failed", ET_CONTINUE, FP_CELL, FP_CELL)
	gForwardClientLogout = CreateMultiForward("mg_fw_client_logout", ET_CONTINUE, FP_CELL)
	gForwardClientClean = CreateMultiForward("mg_fw_client_clean", ET_CONTINUE, FP_CELL)
	gForwardClientSqlSave = CreateMultiForward("mg_fw_client_sql_save", ET_CONTINUE, FP_CELL, FP_CELL)
}

public plugin_cfg()
{
	new sqlText[256]

	formatex(sqlText, charsmax(sqlText), "UPDATE regSystemAccounts SET accountActiveCS1=^"%d^";", 0)
	SQL_ThreadQuery(gSqlRegTuple, "sqlGeneralHandle", sqlText)
}

public plugin_natives()
{	
	gSqlRegTuple = SQL_MakeDbTuple("127.0.0.1", "root", "MG2020asdMK", "account_informations")
	
	register_native("mg_reg_user_loading", "native_reg_user_loading")
	register_native("mg_reg_user_loggedin", "native_reg_user_loggedin")
	register_native("mg_reg_user_register", "native_reg_user_register")
	register_native("mg_reg_user_login", "native_reg_user_login")
	register_native("mg_reg_user_logout", "native_reg_user_logout")
	register_native("mg_reg_user_sqlload_start", "native_reg_user_sqlload_start")
	register_native("mg_reg_user_sqlload_finished", "native_reg_user_sqlload_finished")
}

public sqlRegisterHandle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
	new id = data[dt_id]
	
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		new retValue
		
		log_amx("%s", error)
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientFailedRegister, retValue, id, ERROR_SQL_ERROR)
		return
	}
	
	if(SQL_NumRows(Query) > 0)
	{
		new retValue
		
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientFailedRegister, retValue, id, ERROR_ACCOUNT_USED)
		return
	}
	
	new sqlText[500], len, subData[1]
	new lSteamId[MAX_AUTHID_LENGTH+1], lName[MAX_NAME_LENGTH+1], lSetinfoPwHash[MAX_SETINFOPW_LENGTH+1], lRegDate[30]
	
	subData[0] = id

	get_user_authid(id, lSteamId, charsmax(lSteamId))
	get_user_name(id, lName, charsmax(lName))
	getSetinfoPwHash(id, lSetinfoPwHash, charsmax(lSetinfoPwHash))
	get_time("%Y.%m.%d. - %H:%M:%S", lRegDate, charsmax(lRegDate))
	
	len += formatex(sqlText[len], charsmax(sqlText) - len, "INSERT INTO regSystemAccounts ")
	len += formatex(sqlText[len], charsmax(sqlText) - len, "(userName, passWord, eMail, lastName, lastSteamId, lastSetinfoPwHash, regName, regSteamId, regDate) ")
	len += formatex(sqlText[len], charsmax(sqlText) - len, "VALUE ")
	len += formatex(sqlText[len], charsmax(sqlText) - len, "(^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^", ^"%s^");",
				data[dt_username], data[dt_password], data[dt_email], lName, lSteamId, lSetinfoPwHash, lName, lSteamId, lRegDate)
	SQL_ThreadQuery(gSqlRegTuple, "sqlRegisterInsertHandle", sqlText, subData, 1)
}

public sqlRegisterInsertHandle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
	new id, retValue
	
	id = data[0]

	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", error)
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientFailedRegister, retValue, id, ERROR_SQL_ERROR)
		return
	}
	
	flag_unset(gLoadingUser, id)
	ExecuteForward(gForwardClientSuccessRegister, retValue, id)
}

public sqlLoginHandle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
	new retValue
	new id = data[0]
	
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		if(flag_get(gAutoLogin, id))
		{
			log_amx("%s", error)
			flag_unset(gLoadingUser, id)
			flag_unset(gAutoLogin, id)
			ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_DONT_NOTIFY)
			return
		}
		
		log_amx("%s", error)
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_SQL_ERROR)
		return
	}
	
	if(SQL_NumRows(Query) <= 0)
	{
		if(flag_get(gAutoLogin, id))
		{
			flag_unset(gLoadingUser, id)
			flag_unset(gAutoLogin, id)
			ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_DONT_NOTIFY)
			return
		}
		
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_ACCOUNT_NOT_FOUND)
		return
	}
	
	new activeAccount = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "accountActiveCS1"))
	
	if(activeAccount)
	{
		if(flag_get(gAutoLogin, id))
		{
			flag_unset(gLoadingUser, id)
			flag_unset(gAutoLogin, id)
			ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_DONT_NOTIFY)
			return
		}
		
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_ACCOUNT_USED)
		return
	}
	
	if(!is_user_connected(id))
	{
		flag_unset(gLoadingUser, id)
		flag_unset(gAutoLogin, id)
		ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_DONT_NOTIFY)
		return
	}
	
	if(flag_get(gAutoLogin, id))
	{
		new lAutoLogin = false
		
		while(SQL_MoreResults(Query) && !lAutoLogin)
		{
			if(SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "settingAutoLoginSteamId")))
			{
				new lSteamIdSql[MAX_AUTHID_LENGTH+1], lSteamId[MAX_AUTHID_LENGTH+1]
				
				SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "lastSteamId"), lSteamIdSql, charsmax(lSteamIdSql))
				get_user_authid(id, lSteamId, charsmax(lSteamId))
				
				if(!equal(lSteamIdSql, lSteamId))
				{
					lAutoLogin = false
					SQL_NextRow(Query)
					continue
				}
				
				lAutoLogin = true
			}
			
			if(SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "settingAutoLoginName")))
			{
				new lNameSql[MAX_NAME_LENGTH+1], lName[MAX_NAME_LENGTH+1]
				
				SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "lastName"), lNameSql, charsmax(lNameSql))
				get_user_name(id, lName, charsmax(lName))
				
				if(!equal(lNameSql, lName))
				{
					lAutoLogin = false
					SQL_NextRow(Query)
					continue
				}
				
				lAutoLogin = true
			}
			
			if(SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "settingAutoLoginSetinfoPw")))
			{
				new lSetinfoPwSql[MAX_NAME_LENGTH+1], lSetinfoPw[MAX_NAME_LENGTH+1]
				
				SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "lastSetinfoPwHash"), lSetinfoPwSql, charsmax(lSetinfoPwSql))
				getSetinfoPwHash(id, lSetinfoPw, charsmax(lSetinfoPw))
				
				if(!equal(lSetinfoPwSql, lSetinfoPw))
				{
					lAutoLogin = false
					SQL_NextRow(Query)
					continue
				}
				
				lAutoLogin = true
			}

			if(lAutoLogin)
				break

			SQL_NextRow(Query)
		}
		
		if(!lAutoLogin)
		{
			flag_unset(gLoadingUser, id)
			flag_unset(gAutoLogin, id)
			ExecuteForward(gForwardClientFailedLogin, retValue, id, ERROR_DONT_NOTIFY)
			return
		}
	}
	
	gAccountId[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "accountId"))
	gGameTime[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "gameTime"))

	new sqlText[256]
	
	formatex(sqlText, charsmax(sqlText), "UPDATE regSystemAccounts SET accountActiveCS1=^"%d^" WHERE accountId=^"%d^";", 1, gAccountId[id])
	SQL_ThreadQuery(gSqlRegTuple, "sqlGeneralHandle", sqlText)
	
	ExecuteForward(gForwardClientProcessLogin, retValue, id)
	
	if(!retValue)
	{
		flag_set(gLoggedIn, id)
		flag_unset(gAutoLogin, id)
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientSuccessLogin, retValue, id)
	}
}

public sqlGeneralHandle(FailState, Handle:Query, error[],errcode, data[], datasize)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("%s", error)
		return
	}
}

public checkSqlArray(taskId)
{
	new id = taskId - TASKID2
	
	if(arrayUserLoadingSql[id] && !ArraySize(arrayUserLoadingSql[id]))
	{
		new retValue

		ArrayDestroy(arrayUserLoadingSql[id])
		flag_set(gLoggedIn, id)
		flag_unset(gAutoLogin, id)
		flag_unset(gLoadingUser, id)
		ExecuteForward(gForwardClientSuccessLogin, retValue, id)
	}
}

public saveAccountData(taskId)
{
	static id, loggingOut
	id = taskId - TASKID1
	
	loggingOut = false
	
	if(id > 32)
	{
		loggingOut = true
		id /= 33
	}
	
	if(!flag_get(gLoggedIn, id) || flag_get(gLoadingUser, id) || !gAccountId[id])
		return
	
	static sqlText[2048]
	static len
	static retValue

	static lSteamId[MAX_AUTHID_LENGTH+1], lName[MAX_NAME_LENGTH+1], lSetinfoPwHash[MAX_SETINFOPW_LENGTH+1]

	if(loggingOut)
	{
		lSteamId[0] = EOS
		lName[0] = EOS
		lSetinfoPwHash[0] = EOS
		
		get_user_authid(id, lSteamId, charsmax(lSteamId))
		get_user_name(id, lName, charsmax(lName))
		getSetinfoPwHash(id, lSetinfoPwHash, charsmax(lSetinfoPwHash))
	}
	
	sqlText[0] = EOS
	len = 0
	retValue = 0
	
	len += formatex(sqlText[len], charsmax(sqlText) - len, "UPDATE regSystemAccounts SET")
	len += formatex(sqlText[len], charsmax(sqlText) - len, " gameTime = ^"%d^"", gGameTime[id]+get_user_time(id, 1))
	
	if(loggingOut)
		len += formatex(sqlText[len], charsmax(sqlText) - len, ", lastSteamId = ^"%s^", lastName = ^"%s^", lastSetinfoPwHash = ^"%s^"", lSteamId, lName, lSetinfoPwHash)
	
	len += formatex(sqlText[len], charsmax(sqlText) - len, " WHERE gameId=^"%d^";", gAccountId[id])
	SQL_ThreadQuery(gSqlRegTuple, "sqlGeneralHandle", sqlText)
	
	if(loggingOut)
		ExecuteForward(gForwardClientSqlSave, retValue, id, SQL_SAVETYPE_LOGOUT)
	else
	{
		ExecuteForward(gForwardClientSqlSave, retValue, id, SQL_SAVETYPE_REGULAR)
		set_task(30.0, "sqlSaveData", TASKID1+id)
	}
}

public native_reg_user_loading(plugin_id, param_num)
{
	return flag_get(gLoadingUser, get_param(1))
}

public native_reg_user_loggedin(plugin_id, param_num)
{
	new id = get_param(1)
	
	if(!is_user_connected(id))
	{
		log_amx("[LOGGEDIN] User's not connected! (%d)", id)
		return false
	}
	
	if(flag_get(gLoadingUser, id))
		return false
	
	return flag_get(gLoggedIn, id)
}

public native_reg_user_register(plugin_id, param_num)
{
	new id = get_param(1)
	new lUsername[33], lPassword[33], lEMail[MAX_EMAIL_LENGTH+1]
	get_string(2, lUsername, charsmax(lUsername))
	get_string(3, lPassword, charsmax(lPassword))
	get_string(4, lEMail, charsmax(lEMail))
	
	if(!is_user_connected(id))
	{
		log_amx("[REGISTER] User's not connected! (%d)", id)
		return false
	}
	
	if(flag_get(gLoggedIn, id))
	{
		log_amx("[REGISTER] User's already logged in! (%d)", gAccountId[id])
		return false
	}
	
	if(flag_get(gLoadingUser, id))
	{
		new lName[MAX_NAME_LENGTH+1]
		
		get_user_name(id, lName, charsmax(lName))
		
		log_amx("[REGISTER] User's account is loading! (%d)", lName)
		return false
	}
	
	return userRegister(id, lUsername, lPassword, lEMail)
}

public native_reg_user_login(plugin_id, param_num)
{
	new id = get_param(1)
	new lUsername[33], lPassword[33]
	get_string(2, lUsername, charsmax(lUsername))
	get_string(3, lPassword, charsmax(lPassword))
	
	if(!is_user_connected(id))
	{
		log_amx("[LOGIN] User's not connected! (%d)", id)
		return false
	}
	
	if(flag_get(gLoggedIn, id))
	{
		log_amx("[LOGIN] User's already logged in! (%d)", gAccountId[id])
		return false
	}
	
	if(flag_get(gLoadingUser, id))
	{
		new lName[MAX_NAME_LENGTH+1]
		
		get_user_name(id, lName, charsmax(lName))
		
		log_amx("[LOGIN] User's account is loading! (%d)", lName)
		return false
	}
	
	return userLogin(id, lUsername, lPassword)
}

public native_reg_user_logout(plugin_id, param_num)
{
	new id = get_param(1)
	
	if(!is_user_connected(id))
	{
		log_amx("[LOGOUT] User's not connected! (%d)", id)
		return false
	}
	
	if(!flag_get(gLoggedIn, id))
	{
		new lName[MAX_NAME_LENGTH+1]
		
		get_user_name(id, lName, charsmax(lName))
		
		log_amx("[LOGOUT] User is not logged in! (%s)", lName)
		return false
	}
	
	if(flag_get(gLoadingUser, id))
	{
		new lName[MAX_NAME_LENGTH+1]
		
		get_user_name(id, lName, charsmax(lName))
		
		log_amx("[LOGOUT] User's account is loading! (%s)", lName)
		return false
	}
	
	userLogout(id)
	return true
}

public native_reg_user_sqlload_start(plugin_id, param_num)
{
	new id = get_param(1)
	new lSqlId = get_param(2)
	
	if(!is_user_connected(id))
	{
		log_amx("[LOGIN] User's not connected! (%d)", id)
		return false
	}
	
	if(!arrayUserLoadingSql[id])
		arrayUserLoadingSql[id] = ArrayCreate(1)
	
	ArrayPushCell(arrayUserLoadingSql[id], lSqlId)

	return true
}

public native_reg_user_sqlload_finished(plugin_id, param_num)
{
	new id = get_param(1)
	new lSqlId = get_param(2)
	
	if(!is_user_connected(id))
	{
		log_amx("[LOGIN] User's not connected! (%d)", id)
		return false
	}
	
	ArrayDeleteItem(arrayUserLoadingSql[id], lSqlId)
	
	remove_task(TASKID2+id)
	set_task(0.5, "checkSqlArray", TASKID2+id)

	return true
}

public client_putinserver(id)
{
	client_clean(id)
	flag_set(gAutoLogin, id)
	userLogin(id)
}

public client_disconnected(id)
{
	client_clean(id, true)
}

client_clean(id, bool:disconnect = false)
{
	if(disconnect)
	{
		remove_task(TASKID1+id)
		saveAccountData(TASKID1+(id*33))
	}
	
	new sqlText[128], retValue
	
	formatex(sqlText, charsmax(sqlText), "UPDATE regSystemAccounts SET accountActiveCS1=^"%d^" WHERE accountId=^"%d^";", 0, gAccountId[id])
	SQL_ThreadQuery(gSqlRegTuple, "sqlGeneralHandle", sqlText)
	
	ArrayDestroy(arrayUserLoadingSql[id])

	flag_unset(gLoadingUser, id)
	flag_unset(gLoggedIn, id)
	flag_unset(gAutoLogin, id)
	gAccountId[id] = 0
	gGameTime[id] = 0
	
	remove_task(TASKID1+id)
	
	ExecuteForward(gForwardClientClean, retValue, id)
}

userRegister(id, const username[], const password[], eMail[])
{
	if(!is_user_connected(id) || flag_get(gLoggedIn, id) || flag_get(gLoadingUser, id))
		return false
	
	flag_set(gLoadingUser, id)

	new lSqlTxt[250], data[dataTypes]
	
	data[dt_id] = id
	copy(data[dt_username], charsmax(data[dt_username]), username)
	copy(data[dt_password], charsmax(data[dt_password]), password)
	copy(data[dt_email], charsmax(data[dt_email]), eMail)
	
	formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT * FROM regSystemAccounts WHERE userName=^"%s^";", username)
	SQL_ThreadQuery(gSqlRegTuple, "sqlRegisterHandle", lSqlTxt, data, sizeof(data))
	
	return true
}

userLogin(id, const username[]="", const password[]="")
{
	if(!is_user_connected(id) || flag_get(gLoggedIn, id) || flag_get(gLoadingUser, id))
		return false
	
	flag_set(gLoadingUser, id)
	
	new lSqlTxt[250], data[1]
	
	data[0] = id
	
	if(!flag_get(gAutoLogin, id))
		formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT * FROM regSystemAccounts WHERE userName=^"%s^" AND passWord=^"%s^";", username, password)
	else
	{
		new lSteamId[MAX_AUTHID_LENGTH+1], lName[MAX_NAME_LENGTH+1], lSetinfoPwHash[MAX_SETINFOPW_LENGTH+1]
		
		get_user_authid(id, lSteamId, charsmax(lSteamId))
		get_user_name(id, lName, charsmax(lName))
		getSetinfoPwHash(id, lSetinfoPwHash, charsmax(lSetinfoPwHash))
		
		formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT * FROM regSystemAccounts WHERE lastSteamId=^"%s^" OR lastName=^"%s^" OR (lastSetinfoPwHash=^"%s^" AND lastSetinfoPwHash!=^"^");", lSteamId, lName, lSetinfoPwHash)
	}
	SQL_ThreadQuery(gSqlRegTuple, "sqlLoginHandle", lSqlTxt, data, 1)
	
	return true
}

userLogout(id)
{
	flag_set(gLoadingUser, id)

	remove_task(TASKID1+id)
	saveAccountData(TASKID1+(id*33)) // *33, so the save forward will send the save all message
	
	new sqlText[128], retValue
	
	formatex(sqlText, charsmax(sqlText), "UPDATE regSystemAccounts SET accountActiveCS1=^"%d^" WHERE accountId=^"%d^";", 0, gAccountId[id])
	SQL_ThreadQuery(gSqlRegTuple, "sqlGeneralHandle", sqlText)
	
	remove_task(TASKID2+id)

	ArrayDestroy(arrayUserLoadingSql[id])

	flag_unset(gLoadingUser, id)
	flag_unset(gLoggedIn, id)
	flag_unset(gAutoLogin, id)
	gAccountId[id] = 0
	gGameTime[id] = 0
	
	ExecuteForward(gForwardClientClean, retValue, id)
	ExecuteForward(gForwardClientLogout, retValue, id)
	flag_unset(gLoadingUser, id)
}

getSetinfoPwHash(id, string[], len)
{
	get_user_info(id, "_pw", string, len)
	hash_string(string, Hash_Md5, string, len)
	return true
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
