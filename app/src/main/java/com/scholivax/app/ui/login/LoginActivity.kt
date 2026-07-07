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

                    // Register this device for push notifications right away.
                    val fcmToken = FirebaseMessaging.getInstance().token.await()
                    try { api.registerDevice(fcmToken) } catch (_: Exception) { /* retried on next launch */ }

                    SyncWorker.schedulePeriodic(this@LoginActivity)
                    routeToDashboard(body.user_type)
                } else {
                    binding.errorText.text = body?.message ?: "Login failed."
                }
            } catch (e: Exception) {
                binding.errorText.text = "Couldn't reach the server. Check your connection."
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
        }
    }

    private fun setLoading(loading: Boolean) {
        binding.loginProgress.visibility = if (loading) View.VISIBLE else View.GONE
        binding.loginButton.isEnabled = !loading
        binding.errorText.text = ""
    }
}
