package com.scholivax.app.ui.teacher

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.scholivax.app.data.local.AppDatabase
import com.scholivax.app.data.local.CachedMarkRow
import com.scholivax.app.data.local.PendingMark
import com.scholivax.app.data.remote.ApiClient
import com.scholivax.app.databinding.ActivityMarksEntryBinding
import com.scholivax.app.databinding.RowStudentScoreBinding
import com.scholivax.app.sync.SyncWorker
import kotlinx.coroutines.launch

class MarksEntryActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMarksEntryBinding
    private val rowBindings = mutableListOf<Pair<Int, RowStudentScoreBinding>>() // studentId -> row

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMarksEntryBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.loadRosterBtn.setOnClickListener { loadSheet() }
        binding.saveAllBtn.setOnClickListener { saveAll() }
    }

    private fun loadSheet() {
        val examId = binding.examIdInput.text?.toString()?.toIntOrNull()
        val classId = binding.classIdInput.text?.toString()?.toIntOrNull()
        val subjectId = binding.subjectIdInput.text?.toString()?.toIntOrNull()

        if (examId == null || classId == null || subjectId == null) {
            binding.statusText.text = "Enter exam, class and subject IDs first."
            return
        }

        lifecycleScope.launch {
            val db = AppDatabase.getInstance(this@MarksEntryActivity)

            var rows: List<CachedMarkRow> = emptyList()
            try {
                val api = ApiClient.create(this@MarksEntryActivity)
                val response = api.getMarksRoster(examId, classId, subjectId)
                val students = response.body()?.students
                if (response.isSuccessful && students != null) {
                    val cached = students.map {
                        CachedMarkRow(
                            examId = examId, classId = classId, subjectId = subjectId,
                            studentId = it.student_id, name = it.name, roll = it.roll,
                            lastKnownScore = it.exam_score, lastKnownComment = it.comment
                        )
                    }
                    db.cachedMarkRowDao().insertAll(cached)
                    rows = cached
                    binding.statusText.text = "Loaded live from server."
                } else {
                    rows = db.cachedMarkRowDao().getSheet(examId, classId, subjectId)
                    binding.statusText.text = "Loaded from offline cache."
                }
            } catch (e: Exception) {
                rows = db.cachedMarkRowDao().getSheet(examId, classId, subjectId)
                binding.statusText.text = if (rows.isEmpty()) {
                    "No connection and no cached sheet yet — connect once first."
                } else {
                    "No connection — loaded from offline cache."
                }
            }

            // Overlay any not-yet-synced local edits on top of the loaded rows.
            val queuedEdits = db.pendingMarkDao().getForSheet(examId, classId, subjectId)
                .associateBy { it.studentId }

            renderRows(rows, queuedEdits)
        }
    }

    private fun renderRows(rows: List<CachedMarkRow>, queuedEdits: Map<Int, PendingMark>) {
        binding.studentRowsContainer.removeAllViews()
        rowBindings.clear()

        for (row in rows) {
            val rowBinding = RowStudentScoreBinding.inflate(layoutInflater, binding.studentRowsContainer, false)
            rowBinding.rowStudentName.text = "${row.name}${row.roll?.let { " ($it)" } ?: ""}"
            val queued = queuedEdits[row.studentId]
            rowBinding.rowScoreInput.setText(queued?.examScore ?: row.lastKnownScore ?: "")
            binding.studentRowsContainer.addView(rowBinding.root)
            rowBindings.add(row.studentId to rowBinding)
        }
    }

    private fun saveAll() {
        val examId = binding.examIdInput.text?.toString()?.toIntOrNull() ?: return
        val classId = binding.classIdInput.text?.toString()?.toIntOrNull() ?: return
        val subjectId = binding.subjectIdInput.text?.toString()?.toIntOrNull() ?: return

        lifecycleScope.launch {
            val db = AppDatabase.getInstance(this@MarksEntryActivity)

            // Always queue locally first — guarantees nothing is lost even
            // if the app is closed mid-sync, then try to flush right away.
            for ((studentId, rowBinding) in rowBindings) {
                val score = rowBinding.rowScoreInput.text?.toString()?.trim().orEmpty()
                if (score.isEmpty()) continue
                db.pendingMarkDao().insert(
                    PendingMark(
                        examId = examId, classId = classId, subjectId = subjectId,
                        studentId = studentId, examScore = score, comment = null
                    )
                )
            }

            SyncWorker.scheduleOneOff(this@MarksEntryActivity)
            binding.statusText.text = "Saved locally — syncing to server now."
        }
    }
}
