package com.example.pigeon_demo_plugin

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin

class PigeonDemoPlugin : FlutterPlugin, NativeDemoApi {
  private var context: Context? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    NativeDemoApi.setUp(binding.binaryMessenger, this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    NativeDemoApi.setUp(binding.binaryMessenger, null)
    context = null
  }

  override fun getDeviceInfo(request: DeviceInfoRequest): DeviceInfoReply {
    val prefix = request.prefix ?: "Flutter"
    val packageName = context?.packageName ?: "unknown package"
    return DeviceInfoReply(
      platform = "Android",
      osVersion = Build.VERSION.RELEASE ?: "unknown",
      model = "${Build.MANUFACTURER} ${Build.MODEL}",
      message = "$prefix from Kotlin via Pigeon in $packageName",
    )
  }

  override fun increment(request: CounterRequest): CounterReply {
    val nextValue = (request.value ?: 0L) + 1L
    return CounterReply(
      value = nextValue,
      message = "Kotlin calculated $nextValue",
    )
  }
}
