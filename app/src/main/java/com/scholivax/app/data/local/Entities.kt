package com.scholivax.app.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

// Cached student roster — lets attendance scanning and marks entry work
// with zero network calls once a teacher has synced once while online.
@Entity(tableName = "cached_students")
data class CachedStudent(
    @PrimaryKey val studentId: Int,
    val name: String,
    val roll: String?,
    val classId: Int?,
    val sectionId: Int?
)

// A barcode/roll scan that happened while offline (or just to be safe,
// always queued then flushed) — synced to the server as soon as we have
// connectivity, then deleted.
@Entity(tableName = "pending_attendance")
data class PendingAttendance(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val roll: String,
    val date: String, // yyyy-MM-dd
    val scannedAtMillis: Long,
    val synced: Boolean = false
)

// One student's score for one exam/subject, entered offline, queued for sync.
@Entity(tableName = "pending_marks")
data class PendingMark(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val examId: Int,
    val classId: Int,
    val subjectId: Int,
    val studentId: Int,
    val examScore: String,
    val comment: String?,
    val synced: Boolean = false
)

// Cached "score sheet" for one exam/class/subject combination, so a
// teacher can open Marks Entry with no signal after having loaded it once
// while online. Local edits are tracked in PendingMark; this table just
// holds the roster + last-known scores for display.
@Entity(tableName = "cached_mark_rows", primaryKeys = ["examId", "classId", "subjectId", "studentId"])
data class CachedMarkRow(
    val examId: Int,
    val classId: Int,
    val subjectId: Int,
    val studentId: Int,
    val name: String,
    val roll: String?,
    val lastKnownScore: String?,
    val lastKnownComment: String?
)

// Cached circulars so the circulars list/screen works fully offline.
@Entity(tableName = "cached_circulars")
data class CachedCircular(
    @PrimaryKey val circularId: Int,
    val title: String?,
    val reference: String?,
    val content: String?,
    val date: String?
)
