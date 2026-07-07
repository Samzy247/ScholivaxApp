package com.scholivax.app.ui.parent

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.scholivax.app.data.remote.ApiClient
import com.scholivax.app.databinding.ActivityParentHomeBinding
import com.scholivax.app.databinding.RowChildStatusBinding
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
                        addStatusRow("No linked students found.", marked = null)
                    }
                    for (child in children) {
                        addStatusRow(child.name, marked = child.marked)
                    }
                } else {
                    addStatusRow("Couldn't load attendance right now.", marked = null)
                }
            } catch (e: Exception) {
                addStatusRow("You're offline — attendance status needs a connection.", marked = null)
            }
        }
    }

    private fun addStatusRow(name: String, marked: Boolean?) {
        val row = RowChildStatusBinding.inflate(layoutInflater, binding.childrenContainer, false)
        row.childName.text = name
        when (marked) {
            true -> {
                row.childStatusChip.text = "Present ✓"
                row.childStatusChip.setBackgroundResource(com.scholivax.app.R.drawable.bg_pill_success)
                row.childStatusChip.setTextColor(getColor(com.scholivax.app.R.color.success))
            }
            false -> {
                row.childStatusChip.text = "Not marked yet"
                row.childStatusChip.setBackgroundResource(com.scholivax.app.R.drawable.bg_pill_error)
                row.childStatusChip.setTextColor(getColor(com.scholivax.app.R.color.error))
            }
            null -> {
                row.childStatusChip.text = ""
                row.childStatusChip.setBackgroundResource(com.scholivax.app.R.drawable.bg_pill_neutral)
            }
        }
        binding.childrenContainer.addView(row.root)
    }
}

