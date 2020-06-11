#if defined _mg_regsystem_api_included
  #endinput
#endif

#define _mg_regsystem_api_included

#include <mg_regsystem_api_const>

/*
 * Returns the bool of loading.
 *
 * @param id			Player index.
 *
 * @return			True if the player's loading, false otherwise.
 */
native mg_reg_user_loading(id);

/*
 * Returns the bool of loggedin.
 *
 * @param id			Player index.
 *
 * @return			True if the player's logged in, false otherwise.
 */
native mg_reg_user_loggedin(id);

/*
 * Sends a register message to our regapi plugin.
 *
 * @param id			Player index.
 * @param userName		The username.
 * @param hashPassword		The password(md5 hash coded).
 * @param eMail			The e-mail.
 *
 * @return			True if the player's not logged in, false otherwise.
 */
native mg_reg_user_register(id, const userName[MAX_USERNAME_LENGTH+1], const hashPassword[33], const eMail[MAX_EMAIL_LENGTH+1]);

/*
 * Sends a login message to our regapi plugin.
 *
 * @param id			Player index.
 * @param userName		The username.
 * @param hashPassword		The password(md5 hash coded).
 *
 * @return			True if the player's not logged in, false otherwise.
 */
native mg_reg_user_login(id, const userName[MAX_USERNAME_LENGTH+1], const hashPassword[33]);

/*
 * Sends a logout message to our regapi plugin.
 * Only neccessary by manual logout, at disconnect the api handles it
 *
 * @param id			Player index.
 *
 * @return			True if the player's logged out, false otherwise.
 */
native mg_reg_user_logout(id);

/*
 * Must be called in mg_fw_client_login_process(id)!
 *
 * @param id			Player index.
 * @param sqlId			For Ids, see mg_regsystem_api_const.inc(MG_SQLID_*)
 *
 * @return			False if user is not connected.
 */
native mg_reg_user_sqlload_start(id, sqlId);

/*
 * Must be called in after the sql load is finished!
 * Even must be called when a problem accured!(Connection was not made | Wrong connection)
 * If problem accured the not saving must be handled by the user plugin.
 *
 * @param id			Player index.
 * @param sqlId			For Ids, see mg_regsystem_api_const.inc(MG_SQLID_*)
 *
 * @return			False if user is not connected.
 */
native mg_reg_user_sqlload_finished(id, sqlId);

/*
 * Called at successful registration.
 *
 * @param id			Player index.
 *
 * @noreturn
 */
forward mg_fw_client_register_success(id);

/*
 * Called at failed registration.
 *
 * @param id			Player index.
 * @param errorType		Error type, see mg_regsystem_api_const.inc (ERROR_*)
 *
 * @noreturn
 */
forward mg_fw_client_register_failed(id, errorType);

/*
 * Called at successful login.
 *
 * @param id			Player index.
 *
 * @noreturn
 */
forward mg_fw_client_login_success(id);

/*
 * Called at successful authorization.
 * Must return a non-zero value if mg_reg_user_sqlload_start(id, sqlId) used!
 * It's important, so with the return the user not logs in instantly, waits until all sqlloads are finished!
 *
 * @param id			Player index.
 *
 * @noreturn
 */
forward mg_fw_client_login_process(id);

/*
 * Called at failed login.
 *
 * @param id			Player index.
 * @param errorType		Error type, see mg_regsystem_api_const.inc (ERROR_*)
 *
 * @noreturn
 */
forward mg_fw_client_login_failed(id, errorType);

/*
 * Called when client's being cleaned.
 * Called after logging out!
 *
 * @param id			Player index.
 *
 * @noreturn
 */
forward mg_fw_client_clean(id);

/*
 * Called when client's data's being saved.
 *
 * @param id			Player index.
 * @param saveType		Save type, see mg_regsystem_api_const.inc (SQL_SAVETYPE_*).
 *
 * @noreturn
 */
forward mg_fw_client_sql_save(id, saveType);

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
