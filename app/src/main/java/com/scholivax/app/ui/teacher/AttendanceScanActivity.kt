package com.scholivax.app.ui.teacher

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.scholivax.app.data.local.AppDatabase
import com.scholivax.app.data.local.PendingAttendance
import com.scholivax.app.data.remote.ApiClient
import com.scholivax.app.databinding.ActivityAttendanceScanBinding
import com.scholivax.app.sync.SyncWorker
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors

class AttendanceScanActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAttendanceScanBinding
    private val cameraExecutor = Executors.newSingleThreadExecutor()
    private var lastScannedRoll: String? = null
    private var lastScanTimeMillis = 0L
    private val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    private val permissionLauncher = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startCamera() else {
            binding.resultText.text = "Camera permission is required to scan attendance."
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAttendanceScanBinding.inflate(layoutInflater)
        setContentView(binding.root)

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            startCamera()
        } else {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(binding.previewView.surfaceProvider)
            }

            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also { it.setAnalyzer(cameraExecutor, ::analyzeFrame) }

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    this, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis
                )
            } catch (e: Exception) {
                binding.resultText.text = "Couldn't start the camera: ${e.message}"
            }
        }, ContextCompat.getMainExecutor(this))
    }

    @androidx.camera.core.ExperimentalGetImage
    private fun analyzeFrame(imageProxy: androidx.camera.core.ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage == null) { imageProxy.close(); return }

        val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
        val scanner = BarcodeScanning.getClient()

        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                val roll = barcodes.firstOrNull { it.valueType == Barcode.TYPE_TEXT || it.rawValue != null }?.rawValue
                if (!roll.isNullOrBlank()) {
                    handleScannedRoll(roll.trim())
                }
            }
            .addOnCompleteListener { imageProxy.close() }
    }

    private fun handleScannedRoll(roll: String) {
        val now = System.currentTimeMillis()
        // Debounce: ignore the same barcode held in view for less than 3s.
        if (roll == lastScannedRoll && now - lastScanTimeMillis < 3000) return
        lastScannedRoll = roll
        lastScanTimeMillis = now

        lifecycleScope.launch {
            runOnUiThread { binding.resultText.text = "Scanned: $roll — checking..." }

            try {
                // Try live first — gives the teacher an immediate, accurate result.
                val api = ApiClient.create(this@AttendanceScanActivity)
                val response = api.markAttendance(roll = roll, studentId = null, date = today)
                val body = response.body()

                if (response.isSuccessful && body?.status == "success") {
                    val message = if (body.already_marked == true) {
                        "${body.name} already marked present today."
                    } else {
                        "${body.name} marked present ✓"
                    }
                    runOnUiThread {
                        binding.resultText.text = message
                        binding.offlineBadge.visibility = android.view.View.GONE
                    }
                } else {
                    queueOffline(roll)
                }
            } catch (e: Exception) {
                // No connectivity (or server unreachable) — queue it, don't lose the scan.
                queueOffline(roll)
            }
        }
    }

    private suspend fun queueOffline(roll: String) {
        val db = AppDatabase.getInstance(this@AttendanceScanActivity)
        db.pendingAttendanceDao().insert(
            PendingAttendance(roll = roll, date = today, scannedAtMillis = System.currentTimeMillis())
        )
        val cachedStudent = db.studentDao().findByRoll(roll)

        SyncWorker.scheduleOneOff(this@AttendanceScanActivity)

        runOnUiThread {
            val label = cachedStudent?.name ?: roll
            binding.resultText.text = "$label queued — will sync when back online."
            binding.offlineBadge.visibility = android.view.View.VISIBLE
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
    }
}
