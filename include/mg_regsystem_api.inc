#if defined _mg_regsystem_api_included
  #endinput
#endif

#define _mg_regsystem_api_included

#include <mg_regsystem_api_const>

/**
 * Returns the bool of loggedin.
 *
 * @param id			Player index.
 *
 * @return			True if the player's logged in, false otherwise.
 */
native mg_reg_user_loggedin(id)

/**
 * Sends a login message to our regapi plugin.
 *
 * @param id			Player index.
 * @param userName		The username.
 * @param hashPassword		The password(md5 hash coded).
 *
 * @return			True if the player's not logged in, false otherwise.
 */
native mg_reg_user_login(id, const userName[MAX_USERNAME_LENGTH+1], const hashPassword[33])

/**
 * Sends a logout message to our regapi plugin.
 * Only neccessary by manual logout, at disconnect the api handles it
 *
 * @param id			Player index.
 *
 * @return			True if the player's logged out, false otherwise.
 */
native mg_reg_user_logout(id)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
