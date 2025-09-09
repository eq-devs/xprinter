package com.eq.xprinter


import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** XPrinterFlutterPlugin */
class XPrinterFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var printer: XPrinter? = null


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.eq.xprinter")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    printer = XPrinter.getInstance(context)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> {
        val success = printer?.initialize() ?: false
        result.success(success)
      }
      "hasBluetoothPermissions" -> {
        val hasPermissions = printer?.hasBluetoothPermissions() ?: false
        result.success(hasPermissions)
      }
      "requestBluetoothPermissions" -> {
        if (activity == null) {
          result.error("NO_ACTIVITY", "Activity is not available", null)
          return
        }
        val success = printer?.requestBluetoothPermissions(activity!!) ?: false
        result.success(success)
      }
      "getBluetoothDevices" -> {
        val devices = printer?.getBluetoothDevices()
        if (devices == null) {
          result.success(emptyList<Map<String, String>>())
          return
        }

        val devicesMap = devices.map { device ->
          mapOf("name" to device.name, "address" to device.address)
        }
        result.success(devicesMap)
      }
      "isPrinterConnected" -> {
        val isConnected = printer?.isPrinterConnected() ?: false
        result.success(isConnected)
      }
      "connectToPrinter" -> {
        val macAddress = call.argument<String>("macAddress")
        if (macAddress == null) {
          result.error("INVALID_ARGUMENT", "MAC address is required", null)
          return
        }

        printer?.connectToPrinter(macAddress, object : XPrinter.PrinterCallback {
          override fun onSuccess() {
            result.success(true)
          }

          override fun onError(errorMessage: String) {
            result.error("CONNECTION_ERROR", errorMessage, null)
          }
        }) ?: result.error("PRINTER_NOT_INITIALIZED", "Printer not initialized", null)
      }
      "reconnectLastPrinter" -> {
        val success = printer?.reconnectLastPrinter(object : XPrinter.PrinterCallback {
          override fun onSuccess() {
            result.success(true)
          }

          override fun onError(errorMessage: String) {
            result.error("RECONNECTION_ERROR", errorMessage, null)
          }
        }) ?: false

        if (!success) {
          result.error("NO_PREVIOUS_CONNECTION", "No previous connection found", null)
        }
      }
      "printBitmap" -> {
        val filePath = call.argument<String>("filePath")
        if (filePath == null) {
          result.error("INVALID_ARGUMENT", "File path is required", null)
          return
        }

        printer?.printBitmap(filePath, object : XPrinter.PrinterCallback {
          override fun onSuccess() {
            result.success(true)
          }

          override fun onError(errorMessage: String) {
            result.error("PRINT_ERROR", errorMessage, null)
          }
        }) ?: result.error("PRINTER_NOT_INITIALIZED", "Printer not initialized", null)
      }
      // In XPrinterFlutterPlugin.kt - update the "printImage" case
      "printImage" -> {
        val base64Encoded = call.argument<String>("base64Encoded")
        val width = (call.argument<Double>("width") ?: 460.0).toInt()
        val x = (call.argument<Double>("x") ?: 0.0).toInt()
        val y = (call.argument<Double>("y") ?: 0.0).toInt()

        if (base64Encoded == null) {
          result.error("INVALID_ARGUMENT", "Base64 encoded string is required", null)
          return
        }

        printer?.printImage(base64Encoded, width, x, y, object : XPrinter.PrinterCallback {
          override fun onSuccess() {
            result.success(true)
          }

          override fun onError(errorMessage: String) {
            result.error("PRINT_ERROR", errorMessage, null)
          }
        }) ?: result.error("PRINTER_NOT_INITIALIZED", "Printer not initialized", null)
      }
//      "printImage" -> {
//        val base64Encoded = call.argument<String>("base64Encoded")
//        val widthDouble = call.argument<Double>("width") ?: 460.0
//        val width = widthDouble.toInt()
//
//        if (base64Encoded == null) {
//          result.error("INVALID_ARGUMENT", "Base64 encoded string is required", null)
//          return
//        }
//
//        printer?.printImage(base64Encoded, width, object : XPrinter.PrinterCallback {
//          override fun onSuccess() {
//            result.success(true)
//          }
//
//          override fun onError(errorMessage: String) {
//            result.error("PRINT_ERROR", errorMessage, null)
//          }
//        }) ?: result.error("PRINTER_NOT_INITIALIZED", "Printer not initialized", null)
//      }
      "configurePrinter" -> {
        val density = call.argument<Int>("density") ?: 8
        val speed = call.argument<Double>("speed") ?: 4.0
        val paperWidth = call.argument<Double>("paperWidth") ?: 2.0
        val paperHeight = call.argument<Double>("paperHeight") ?: 1.0

        val config = XPrinter.PrinterConfig(density, speed, paperWidth, paperHeight)

        printer?.configurePrinter(config, object : XPrinter.PrinterCallback {
          override fun onSuccess() {
            result.success(true)
          }

          override fun onError(errorMessage: String) {
            result.error("CONFIG_ERROR", errorMessage, null)
          }
        }) ?: result.error("PRINTER_NOT_INITIALIZED", "Printer not initialized", null)
      }
      "close" -> {
        printer?.close()
        result.success(null)
      }
      "exitSdk" -> {
        printer?.exitSdk()
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity

    // Set up connection listener
    printer?.setConnectionListener(object : XPrinter.PrinterConnectionListener {
      override fun onStateChanged(state: XPrinter.PrinterState, message: String) {
        val stateMap = mapOf(
          "state" to state.name,
          "message" to message
        )
        activity?.runOnUiThread {
          channel.invokeMethod("onPrinterStateChanged", stateMap)
        }
      }
    })
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}