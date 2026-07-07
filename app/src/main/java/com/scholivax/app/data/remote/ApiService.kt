package com.scholivax.app.data.remote

import retrofit2.Response
import retrofit2.http.*

data class LoginResponse(
    val status: String,
    val token: String?,
    val user_type: String?,
    val user_id: Int?,
    val name: String?,
    val message: String?
)

data class StudentDto(
    val student_id: Int,
    val name: String,
    val roll: String?,
    val class_id: Int?,
    val section_id: Int?
)

data class RosterResponse(val status: String, val students: List<StudentDto>?)

data class MarkAttendanceResponse(
    val status: String,
    val already_marked: Boolean?,
    val name: String?,
    val student_id: Int?,
    val message: String?
)

data class ExamDto(val exam_id: Int, val name: String?)
data class ExamsResponse(val status: String, val exams: List<ExamDto>?)

data class MarkStudentDto(
    val student_id: Int,
    val name: String,
    val roll: String?,
    val mark_id: Int?,
    val exam_score: String?,
    val comment: String?
)
data class MarksRosterResponse(val status: String, val students: List<MarkStudentDto>?)

data class CircularDto(
    val circular_id: Int,
    val title: String?,
    val reference: String?,
    val content: String?,
    val date: String?
)
data class CircularsResponse(val status: String, val circulars: List<CircularDto>?)

data class ChildStatusDto(val student_id: Int, val name: String, val marked: Boolean, val status: Int?)
data class ChildStatusResponse(val status: String, val date: String?, val children: List<ChildStatusDto>?)

data class SimpleResponse(val status: String, val message: String?)

interface ApiService {

    @FormUrlEncoded
    @POST("api/auth/login")
    suspend fun login(
        @Field("email") email: String,
        @Field("password") password: String
    ): Response<LoginResponse>

    @POST("api/auth/logout")
    suspend fun logout(): Response<SimpleResponse>

    @GET("api/attendance/roster")
    suspend fun getRoster(
        @Query("class_id") classId: Int? = null,
        @Query("section_id") sectionId: Int? = null
    ): Response<RosterResponse>

    @FormUrlEncoded
    @POST("api/attendance/mark")
    suspend fun markAttendance(
        @Field("roll") roll: String?,
        @Field("student_id") studentId: Int?,
        @Field("date") date: String
    ): Response<MarkAttendanceResponse>

    @FormUrlEncoded
    @POST("api/attendance/mark_batch")
    suspend fun markAttendanceBatch(
        @Field("records") recordsJson: String
    ): Response<SimpleResponse>

    @GET("api/attendance/child_status")
    suspend fun getChildStatus(@Query("date") date: String? = null): Response<ChildStatusResponse>

    @GET("api/marks/exams")
    suspend fun getExams(): Response<ExamsResponse>

    @GET("api/marks/roster")
    suspend fun getMarksRoster(
        @Query("exam_id") examId: Int,
        @Query("class_id") classId: Int,
        @Query("subject_id") subjectId: Int
    ): Response<MarksRosterResponse>

    @FormUrlEncoded
    @POST("api/marks/submit")
    suspend fun submitMarks(
        @Field("exam_id") examId: Int,
        @Field("class_id") classId: Int,
        @Field("subject_id") subjectId: Int,
        @Field("entries") entriesJson: String
    ): Response<SimpleResponse>

    @GET("api/circulars/list")
    suspend fun getCirculars(@Query("since_id") sinceId: Int = 0): Response<CircularsResponse>

    @FormUrlEncoded
    @POST("api/device/register")
    suspend fun registerDevice(@Field("fcm_token") fcmToken: String): Response<SimpleResponse>

    @FormUrlEncoded
    @POST("api/device/unregister")
    suspend fun unregisterDevice(@Field("fcm_token") fcmToken: String): Response<SimpleResponse>
}
