package com.scholivax.app.ui.login

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.firebase.messaging.FirebaseMessaging
import com.scholivax.app.data.remote.ApiClient
import com.scholivax.app.databinding.ActivityLoginBinding
import com.scholivax.app.sync.SyncWorker
import com.scholivax.app.ui.admin.AdminHomeActivity
import com.scholivax.app.ui.parent.ParentHomeActivity
import com.scholivax.app.ui.student.StudentHomeActivity
import com.scholivax.app.ui.teacher.TeacherHomeActivity
import com.scholivax.app.util.SessionManager
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private lateinit var sessionManager: SessionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)
        sessionManager = SessionManager(this)

        // Already logged in from a previous session? Skip straight to the dashboard.
        lifecycleScope.launch {
            if (sessionManager.isLoggedIn()) {
                routeToDashboard(sessionManager.getUserType())
            }
        }

        binding.loginButton.setOnClickListener { attemptLogin() }
    }

    private fun attemptLogin() {
        val email = binding.emailInput.text?.toString()?.trim().orEmpty()
        val password = binding.passwordInput.text?.toString()?.trim().orEmpty()

        if (email.isEmpty() || password.isEmpty()) {
            binding.errorText.text = "Enter both email and password."
            return
        }

        setLoading(true)
        lifecycleScope.launch {
            try {
                val api = ApiClient.create(this@LoginActivity)
                val response = api.login(email, password)
                val body = response.body()

                if (response.isSuccessful && body?.status == "success" && body.token != null) {
                    sessionManager.saveSession(body.token, body.user_type ?: "", body.user_id ?: 0, body.name)
                    SyncWorker.schedulePeriodic(this@LoginActivity)

                    // Navigate immediately — never let push-notification setup block getting in.
                    routeToDashboard(body.user_type)

                    // Best-effort, fire-and-forget: register this device for push.
                    // Any failure here (Play Services missing, Firebase misconfigured,
                    // no network) must NOT stop the user from reaching their dashboard.
                    try {
                        val fcmToken = FirebaseMessaging.getInstance().token.await()
                        api.registerDevice(fcmToken)
                    } catch (e: Exception) {
                        android.util.Log.w("Login", "FCM registration skipped: ${e.message}")
                    }
                } else {
                    binding.errorText.text = body?.message ?: "Login failed (server said: ${response.code()})."
                }
            } catch (e: Exception) {
                // Show the REAL reason instead of a generic message, so it's
                // possible to diagnose from a screenshot alone.
                val detail = e.message ?: e.javaClass.simpleName
                binding.errorText.text = "Couldn't reach the server: $detail"
                android.widget.Toast.makeText(this@LoginActivity, "Login error: $detail", android.widget.Toast.LENGTH_LONG).show()
            } finally {
                setLoading(false)
            }
        }
    }

    private fun routeToDashboard(userType: String?) {
        val target = when (userType) {
            "teacher" -> TeacherHomeActivity::class.java
            "parent" -> ParentHomeActivity::class.java
            "student" -> StudentHomeActivity::class.java
            "admin" -> AdminHomeActivity::class.java
            else -> null
        }
        if (target != null) {
            startActivity(Intent(this, target))
            finish()
        } else {
            binding.errorText.text = "Logged in, but got an unrecognized role from the server: '$userType'"
        }
    }

    private fun setLoading(loading: Boolean) {
        binding.loginProgress.visibility = if (loading) View.VISIBLE else View.GONE
        binding.loginButton.isEnabled = !loading
        binding.errorText.text = ""
    }
}
