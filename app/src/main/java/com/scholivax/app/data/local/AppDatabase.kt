package com.scholivax.app.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [CachedStudent::class, PendingAttendance::class, PendingMark::class, CachedCircular::class, CachedMarkRow::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun studentDao(): StudentDao
    abstract fun pendingAttendanceDao(): PendingAttendanceDao
    abstract fun pendingMarkDao(): PendingMarkDao
    abstract fun cachedMarkRowDao(): CachedMarkRowDao
    abstract fun circularDao(): CircularDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "scholivax.db"
                ).build().also { INSTANCE = it }
            }
    }
}
