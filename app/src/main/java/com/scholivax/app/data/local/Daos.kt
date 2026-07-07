package com.scholivax.app.data.local

import androidx.room.*

@Dao
interface StudentDao {
    @Query("SELECT * FROM cached_students WHERE classId = :classId ORDER BY name")
    suspend fun getByClass(classId: Int): List<CachedStudent>

    @Query("SELECT * FROM cached_students WHERE roll = :roll LIMIT 1")
    suspend fun findByRoll(roll: String): CachedStudent?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(students: List<CachedStudent>)

    @Query("DELETE FROM cached_students WHERE classId = :classId")
    suspend fun clearClass(classId: Int)
}

@Dao
interface PendingAttendanceDao {
    @Insert
    suspend fun insert(record: PendingAttendance): Long

    @Query("SELECT * FROM pending_attendance WHERE synced = 0 ORDER BY scannedAtMillis")
    suspend fun getUnsynced(): List<PendingAttendance>

    @Query("UPDATE pending_attendance SET synced = 1 WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<Int>)

    @Query("SELECT COUNT(*) FROM pending_attendance WHERE synced = 0")
    suspend fun unsyncedCount(): Int

    @Query("DELETE FROM pending_attendance WHERE synced = 1")
    suspend fun clearSynced()
}

@Dao
interface PendingMarkDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(record: PendingMark): Long

    @Query("SELECT * FROM pending_marks WHERE examId = :examId AND classId = :classId AND subjectId = :subjectId")
    suspend fun getForSheet(examId: Int, classId: Int, subjectId: Int): List<PendingMark>

    @Query("SELECT * FROM pending_marks WHERE synced = 0")
    suspend fun getUnsynced(): List<PendingMark>

    @Query("UPDATE pending_marks SET synced = 1 WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<Int>)

    @Query("SELECT COUNT(*) FROM pending_marks WHERE synced = 0")
    suspend fun unsyncedCount(): Int
}

@Dao
interface CachedMarkRowDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(rows: List<CachedMarkRow>)

    @Query("SELECT * FROM cached_mark_rows WHERE examId = :examId AND classId = :classId AND subjectId = :subjectId ORDER BY name")
    suspend fun getSheet(examId: Int, classId: Int, subjectId: Int): List<CachedMarkRow>
}

@Dao
interface CircularDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(circulars: List<CachedCircular>)

    @Query("SELECT * FROM cached_circulars ORDER BY circularId DESC")
    suspend fun getAll(): List<CachedCircular>

    @Query("SELECT MAX(circularId) FROM cached_circulars")
    suspend fun getLatestId(): Int?
}
