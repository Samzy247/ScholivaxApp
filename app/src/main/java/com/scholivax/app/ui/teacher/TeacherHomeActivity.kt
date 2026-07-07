package com.scholivax.app.ui.teacher

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.scholivax.app.data.local.AppDatabase
import com.scholivax.app.databinding.ActivityTeacherHomeBinding
import com.scholivax.app.ui.common.CircularsActivity
import com.scholivax.app.util.SessionManager
import kotlinx.coroutines.launch

class TeacherHomeActivity : AppCompatActivity() {

    private lateinit var binding: ActivityTeacherHomeBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTeacherHomeBinding.inflate(layoutInflater)
        setContentView(binding.root)

        lifecycleScope.launch {
            val name = SessionManager(this@TeacherHomeActivity).getName()
            binding.welcomeText.text = if (!name.isNullOrEmpty()) "Welcome, $name" else "Welcome"
        }

        binding.scanAttendanceBtn.setOnClickListener {
            startActivity(Intent(this, AttendanceScanActivity::class.java))
        }
        binding.enterMarksBtn.setOnClickListener {
            startActivity(Intent(this, MarksEntryActivity::class.java))
        }
        binding.circularsBtn.setOnClickListener {
            startActivity(Intent(this, CircularsActivity::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        refreshPendingCount()
    }

    private fun refreshPendingCount() {
        lifecycleScope.launch {
            val db = AppDatabase.getInstance(this@TeacherHomeActivity)
            val attendanceCount = db.pendingAttendanceDao().unsyncedCount()
            val marksCount = db.pendingMarkDao().unsyncedCount()
            val total = attendanceCount + marksCount
            binding.pendingSyncText.text = if (total > 0) {
                "$total item(s) waiting to sync once you're back online."
            } else {
                "Everything is synced."
            }
        }
    }
}
