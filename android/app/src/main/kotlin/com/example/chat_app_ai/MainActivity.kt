package com.example.chat_app_ai

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "aura/local_attachment_opener",
        ).setMethodCallHandler { call, result ->
            if (call.method != "openFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val mimeType = call.argument<String>("mimeType") ?: "*/*"
            if (path.isNullOrBlank()) {
                result.error("INVALID_PATH", "Attachment path is required.", null)
                return@setMethodCallHandler
            }

            val file = File(path)
            if (!file.isFile) {
                result.error("FILE_NOT_FOUND", "Attachment file does not exist.", null)
                return@setMethodCallHandler
            }

            try {
                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.aura_file_provider",
                    file,
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mimeType)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                result.success(null)
            } catch (error: ActivityNotFoundException) {
                result.error("NO_VIEWER", error.message, null)
            } catch (error: Exception) {
                result.error("OPEN_FAILED", error.message, null)
            }
        }
    }
}
