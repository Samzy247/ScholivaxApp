package com.scholivax.app.ui.parent

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.scholivax.app.data.remote.ApiClient
import com.scholivax.app.databinding.ActivityParentHomeBinding
import com.scholivax.app.ui.common.CircularsActivity
import com.scholivax.app.util.SessionManager
import kotlinx.coroutines.launch

class ParentHomeActivity : AppCompatActivity() {

    private lateinit var binding: ActivityParentHomeBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityParentHomeBinding.inflate(layoutInflater)
        setContentView(binding.root)

        lifecycleScope.launch {
            val name = SessionManager(this@ParentHomeActivity).getName()
            binding.welcomeText.text = if (!name.isNullOrEmpty()) "Welcome, $name" else "Welcome"
        }

        binding.circularsBtn.setOnClickListener {
            startActivity(Intent(this, CircularsActivity::class.java))
        }

        loadChildrenStatus()
    }

    override fun onResume() {
        super.onResume()
        // Refresh every time the parent opens this screen or taps back into
        // it from a notification, so it reflects the latest scan.
        loadChildrenStatus()
    }

    private fun loadChildrenStatus() {
        lifecycleScope.launch {
            binding.childrenContainer.removeAllViews()
            try {
                val api = ApiClient.create(this@ParentHomeActivity)
                val response = api.getChildStatus()
                val children = response.body()?.children

                if (response.isSuccessful && children != null) {
                    if (children.isEmpty()) {
                        addLine("No linked students found.")
                    }
                    for (child in children) {
                        val status = if (child.marked) "Marked present ✓" else "Not marked yet"
                        addLine("${child.name}: $status")
                    }
                } else {
                    addLine("Couldn't load attendance right now.")
                }
            } catch (e: Exception) {
                addLine("You're offline — attendance status needs a connection.")
            }
        }
    }

    private fun addLine(text: String) {
        val tv = TextView(this)
        tv.text = text
        tv.setPadding(0, 8, 0, 8)
        binding.childrenContainer.addView(tv)
    }
}
