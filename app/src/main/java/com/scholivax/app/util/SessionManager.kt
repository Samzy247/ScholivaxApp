package com.scholivax.app.util

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first

private val Context.dataStore by preferencesDataStore(name = "scholivax_session")

/**
 * Holds the logged-in user's token/role/id on-device so the app can open
 * straight to the right dashboard, and so every API call can attach
 * "Authorization: Bearer <token>" without hitting the network first.
 */
class SessionManager(private val context: Context) {

    companion object {
        val TOKEN = stringPreferencesKey("token")
        val USER_TYPE = stringPreferencesKey("user_type")
        val USER_ID = intPreferencesKey("user_id")
        val NAME = stringPreferencesKey("name")
        // Used by the "install" prompt logic on first run.
        val HAS_LAUNCHED_BEFORE = stringPreferencesKey("has_launched_before")
    }

    suspend fun saveSession(token: String, userType: String, userId: Int, name: String?) {
        context.dataStore.edit { prefs ->
            prefs[TOKEN] = token
            prefs[USER_TYPE] = userType
            prefs[USER_ID] = userId
            prefs[NAME] = name ?: ""
        }
    }

    suspend fun clearSession() {
        context.dataStore.edit { prefs ->
            prefs.remove(TOKEN)
            prefs.remove(USER_TYPE)
            prefs.remove(USER_ID)
            prefs.remove(NAME)
        }
    }

    suspend fun getToken(): String? = context.dataStore.data.first()[TOKEN]
    suspend fun getUserType(): String? = context.dataStore.data.first()[USER_TYPE]
    suspend fun getUserId(): Int? = context.dataStore.data.first()[USER_ID]
    suspend fun getName(): String? = context.dataStore.data.first()[NAME]

    suspend fun isLoggedIn(): Boolean = getToken() != null
}
