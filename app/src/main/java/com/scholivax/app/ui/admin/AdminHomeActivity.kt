package com.scholivax.app.ui.admin

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.scholivax.app.databinding.ActivitySimpleHomeBinding
import com.scholivax.app.ui.common.CircularsActivity
import com.scholivax.app.util.SessionManager
import kotlinx.coroutines.launch

class AdminHomeActivity : AppCompatActivity() {
    private lateinit var binding: ActivitySimpleHomeBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySimpleHomeBinding.inflate(layoutInflater)
        setContentView(binding.root)

        lifecycleScope.launch {
            val name = SessionManager(this@AdminHomeActivity).getName()
            binding.welcomeText.text = if (!name.isNullOrEmpty()) "Welcome, $name" else "Welcome"
        }

        binding.circularsBtn.setOnClickListener {
            startActivity(Intent(this, CircularsActivity::class.java))
        }
    }
}
