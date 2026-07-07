package com.scholivax.app.sync

import android.content.Context
import androidx.work.*
import com.google.gson.Gson
import com.scholivax.app.data.local.AppDatabase
import com.scholivax.app.data.remote.ApiClient
import java.util.concurrent.TimeUnit

/**
 * Runs whenever the device regains network connectivity (see the
 * constraints below) and flushes anything a teacher queued while offline:
 * scanned attendance + entered scores. Both are safe to retry — the
 * backend's "already_marked" / upsert-by-mark_id logic makes this idempotent.
 */
class SyncWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val db = AppDatabase.getInstance(applicationContext)
        val api = ApiClient.create(applicationContext)
        val gson = Gson()

        return try {
            // --- Flush queued attendance scans ---
            val pendingAttendance = db.pendingAttendanceDao().getUnsynced()
            if (pendingAttendance.isNotEmpty()) {
                val recordsJson = gson.toJson(pendingAttendance.map {
                    mapOf("roll" to it.roll, "date" to it.date)
                })
                val response = api.markAttendanceBatch(recordsJson)
                if (response.isSuccessful) {
                    db.pendingAttendanceDao().markSynced(pendingAttendance.map { it.id })
                    db.pendingAttendanceDao().clearSynced()
                }
            }

            // --- Flush queued marks, grouped by exam/class/subject ---
            val pendingMarks = db.pendingMarkDao().getUnsynced()
            pendingMarks.groupBy { Triple(it.examId, it.classId, it.subjectId) }.forEach { (key, group) ->
                val (examId, classId, subjectId) = key
                val entriesJson = gson.toJson(group.map {
                    mapOf("student_id" to it.studentId, "exam_score" to it.examScore, "comment" to (it.comment ?: ""))
                })
                val response = api.submitMarks(examId, classId, subjectId, entriesJson)
                if (response.isSuccessful) {
                    db.pendingMarkDao().markSynced(group.map { it.id })
                }
            }

            Result.success()
        } catch (e: Exception) {
            // No connectivity or server hiccup — WorkManager will retry per the backoff policy.
            Result.retry()
        }
    }

    companion object {
        private const val UNIQUE_WORK_NAME = "scholivax_sync"

        // Call this after queuing an offline scan/score, and also from a
        // network-change receiver / app-resume, so nothing sits queued longer
        // than necessary.
        fun scheduleOneOff(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = OneTimeWorkRequestBuilder<SyncWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()

            WorkManager.getInstance(context)
                .enqueueUniqueWork(UNIQUE_WORK_NAME, ExistingWorkPolicy.REPLACE, request)
        }

        // Also keep a periodic safety-net sync every 15 minutes while the
        // app is installed, in case the one-off trigger was missed.
        fun schedulePeriodic(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                    "${UNIQUE_WORK_NAME}_periodic",
                    ExistingPeriodicWorkPolicy.KEEP,
                    request
                )
        }
    }
}
