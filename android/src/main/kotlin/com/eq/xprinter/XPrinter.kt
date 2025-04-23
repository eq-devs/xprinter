package com.eq.xprinter

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import net.posprinter.IDeviceConnection
import net.posprinter.POSConnect
import net.posprinter.TSPLConst
import net.posprinter.TSPLPrinter
import net.posprinter.model.AlgorithmType
import java.io.File
import java.lang.ref.WeakReference


/**
 * XPrinter - A streamlined wrapper for Bluetooth TSPL printer operations
 * Optimized for Flutter integration
 */
class XPrinter private constructor(private val context: Context) {

    companion object {
        private const val TAG = "XPrinter"
        private const val BLUETOOTH_PERMISSIONS_REQUEST = 2001

        @Volatile
        private var weakInstance: WeakReference<XPrinter>? = null

        private val BLUETOOTH_PERMISSIONS = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
        } else {

            arrayOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        }

        fun getInstance(context: Context): XPrinter {
            val applicationContext = context.applicationContext
            val cachedInstance = weakInstance?.get()

            if (cachedInstance != null && cachedInstance.context === applicationContext) {
                return cachedInstance
            }

            return synchronized(this) {
                val newInstance = XPrinter(applicationContext)
                weakInstance = WeakReference(newInstance)
                newInstance
            }
        }
    }

    private var deviceConnection: IDeviceConnection? = null
    private var printer: TSPLPrinter? = null
    private var lastConnectedMacAddress: String? = null
    private var connectionListener: PrinterConnectionListener? = null
    private var printerState = PrinterState.DISCONNECTED
    private val coroutineScope = CoroutineScope(Dispatchers.IO)

    /**
     * Enum representing different printer states
     */
    enum class PrinterState {


        DISCONNECTED, CONNECTING, CONNECTED, PRINTING, ERROR
    }

    /**
     * Data class representing a Bluetooth printer device
     */
    data class BluetoothPrinterDevice(
        val name: String, val address: String
    )

    /**
     * Callback interface for printer state changes
     */
    interface PrinterConnectionListener {
        fun onStateChanged(state: PrinterState, message: String = "")
    }

    /**
     * Callback for printer operation results
     */
    interface PrinterCallback {


        fun onSuccess()
        fun onError(errorMessage: String)
    }

    /**
     * Set connection listener to receive printer state updates
     */
    fun setConnectionListener(listener: PrinterConnectionListener) {
        connectionListener = listener
    }

    /**
     * Initialize the printer SDK
     * @return true if initialization was successful
     */
    fun initialize(): Boolean {

        printer?.cls()
        return try {
            POSConnect.init(context)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing POSConnect SDK: ${e.message}", e)
            false
        }
    }

    /**
     * Check if all required Bluetooth permissions are granted
     * @return true if all permissions are granted
     */
    fun hasBluetoothPermissions(): Boolean {
        return BLUETOOTH_PERMISSIONS.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Request Bluetooth permissions
     * @param activity The activity to request permissions from
     * @return true if permissions are already granted
     */
    fun requestBluetoothPermissions(activity: Activity): Boolean {
        if (hasBluetoothPermissions()) {
            return true
        }

        ActivityCompat.requestPermissions(
            activity, BLUETOOTH_PERMISSIONS, BLUETOOTH_PERMISSIONS_REQUEST
        )
        return false
    }

    /**
     * Get list of paired Bluetooth devices
     * @return List of paired Bluetooth devices or null if error
     */
    fun getBluetoothDevices(): List<BluetoothPrinterDevice>? {
        // Explicitly check permissions before proceeding
        if (!hasBluetoothPermissions()) {
            Log.w(TAG, "Bluetooth permissions not granted")
            return null
        }

        try {
            val bluetoothManager =
                context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                    ?: return null

            val bluetoothAdapter: BluetoothAdapter = bluetoothManager.adapter ?: return null

            if (!bluetoothAdapter.isEnabled) {
                return null
            }

            // Check permission again before accessing bondedDevices to handle potential SecurityException
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(
                        context, Manifest.permission.BLUETOOTH_CONNECT
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    Log.w(TAG, "BLUETOOTH_CONNECT permission not granted")
                    return null
                }
            } else if (ContextCompat.checkSelfPermission(
                    context, Manifest.permission.BLUETOOTH
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                Log.w(TAG, "BLUETOOTH permission not granted")
                return null
            }

            // Safely access bondedDevices with permission check
            val bondedDevices = try {
                bluetoothAdapter.bondedDevices
            } catch (e: SecurityException) {
                Log.e(TAG, "SecurityException accessing bondedDevices: ${e.message}", e)
                return null
            }

            return bondedDevices.map {
                BluetoothPrinterDevice(
                    name = try {
                        it.name ?: "Unknown Device"
                    } catch (e: SecurityException) {
                        "Unknown Device"
                    }, address = it.address
                )
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception getting Bluetooth devices: ${e.message}", e)
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting Bluetooth devices: ${e.message}", e)
            return null
        }
    }

    /**
     * Check if printer is currently connected
     * @return true if connected, false otherwise
     */
    fun isPrinterConnected(): Boolean {
        return printer != null && deviceConnection != null
    }

    /**
     * Connect to a specific printer by MAC address
     * @param macAddress The MAC address of the printer
     * @param callback Callback to be invoked when connection completes
     */
    fun connectToPrinter(macAddress: String, callback: PrinterCallback? = null) {
        // Explicitly check permissions before proceeding
        if (!hasBluetoothPermissions()) {
            updateState(PrinterState.ERROR, "Bluetooth permissions not granted")
            callback?.onError("Bluetooth permissions not granted")
            return
        }

        try {
            // Double-check BLUETOOTH_CONNECT permission specifically for Android 12+ (S)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(
                        context, Manifest.permission.BLUETOOTH_CONNECT
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    updateState(PrinterState.ERROR, "BLUETOOTH_CONNECT permission not granted")
                    callback?.onError("BLUETOOTH_CONNECT permission not granted")
                    return
                }
            }

            updateState(PrinterState.CONNECTING)

            // Close previous connection if exists
            close()

            // Create Bluetooth device connection
            deviceConnection = POSConnect.createDevice(POSConnect.DEVICE_TYPE_BLUETOOTH)
            deviceConnection?.connectSync(macAddress) { code, _, msg ->
                when (code) {
                    POSConnect.CONNECT_SUCCESS -> {
                        // Create printer instance
                        printer = TSPLPrinter(deviceConnection!!)
                        lastConnectedMacAddress = macAddress
                        updateState(PrinterState.CONNECTED)
                        callback?.onSuccess()
                    }

                    else -> {
                        deviceConnection = null
                        updateState(PrinterState.ERROR, "Connection failed: $msg")
                        callback?.onError("Failed to connect: $msg")
                    }
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception connecting to printer: ${e.message}", e)
            updateState(PrinterState.ERROR, "Permission error: ${e.message}")
            callback?.onError("Permission error: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to printer: ${e.message}", e)
            updateState(PrinterState.ERROR, "Error: ${e.message}")
            callback?.onError("Error: ${e.message}")
        }
    }

    /**
     * Reconnect to last used printer
     * @param callback Callback to be invoked when reconnection completes
     * @return true if reconnection was initiated, false if no previous connection
     */
    fun reconnectLastPrinter(callback: PrinterCallback? = null): Boolean {
        val targetMac = lastConnectedMacAddress ?: return false
        connectToPrinter(targetMac, callback)
        return true
    }

    /**
     * Print a bitmap file
     * @param filePath Path to the bitmap file
     * @param callback Callback to be invoked when printing completes
     */
    fun printBitmap(filePath: String, callback: PrinterCallback? = null) {
        // Check permissions first
        if (!hasBluetoothPermissions()) {
            updateState(PrinterState.ERROR, "Bluetooth permissions not granted")
            callback?.onError("Bluetooth permissions not granted")
            return
        }

        coroutineScope.launch {
            try {
                // Check printer connection
                if (!isPrinterConnected()) {
                    val targetMac = lastConnectedMacAddress
                    if (targetMac != null) {
                        // Double-check BLUETOOTH_CONNECT permission for Android 12+
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (ContextCompat.checkSelfPermission(
                                    context, Manifest.permission.BLUETOOTH_CONNECT
                                ) != PackageManager.PERMISSION_GRANTED
                            ) {
                                updateState(
                                    PrinterState.ERROR, "BLUETOOTH_CONNECT permission not granted"
                                )
                                callback?.onError("BLUETOOTH_CONNECT permission not granted")
                                return@launch
                            }
                        }

                        connectToPrinter(targetMac)
                        // Wait briefly for connection to establish
                        delay(500)
                    }
                }

                // If still not connected after attempt, show error and return
                if (!isPrinterConnected()) {
                    updateState(PrinterState.ERROR, "Printer not connected")
                    callback?.onError("Printer not connected")
                    return@launch
                }

                val file = File(filePath)
                // Check if file exists
                if (!file.exists()) {
                    updateState(PrinterState.ERROR, "File not found")
                    callback?.onError("File not found: ${file.path}")
                    return@launch
                }

                // Update loading message for printing
                updateState(PrinterState.PRINTING)

                // Print the file
                try {

                    val bitmap = BitmapFactory.decodeFile(filePath)

                    printer?.apply {
                        cls()
                        bitmap(0, 0, TSPLConst.BMP_MODE_OVERWRITE, 600, bitmap, AlgorithmType.Threshold)
                        print(1)
                    }

                    // Mark as success
                    updateState(PrinterState.CONNECTED)
                    callback?.onSuccess()
                } catch (e: SecurityException) {
                    updateState(PrinterState.ERROR, "Permission error: ${e.message}")
                    callback?.onError("Permission error: ${e.message}")
                } catch (e: Exception) {
                    updateState(PrinterState.ERROR, "Printing error: ${e.message}")
                    callback?.onError("Printing error: ${e.message}")
                }
            } catch (e: SecurityException) {
                updateState(PrinterState.ERROR, "Permission error: ${e.message}")
                callback?.onError("Permission error: ${e.message}")
            } catch (e: Exception) {
                updateState(PrinterState.ERROR, "Printing error: ${e.message}")
                callback?.onError("Printing error: ${e.message}")
            }
        }
    }

    /**
     * Close printer connection
     */
    fun close() {
        try {
            deviceConnection?.close()
            deviceConnection = null
            printer = null
            updateState(PrinterState.DISCONNECTED)
        } catch (e: Exception) {
            Log.e(TAG, "Error closing printer connection: ${e.message}", e)
        }
    }

    /**
     * Exit SDK and release resources
     */
    fun exitSdk() {
        close()
        try {
            POSConnect.exit()
        } catch (e: Exception) {
            Log.e(TAG, "Error exiting POSConnect SDK: ${e.message}", e)
        }
    }

    /**
     * Update printer state and notify listeners
     */
    private fun updateState(state: PrinterState, message: String = "") {
        printerState = state
        Handler(Looper.getMainLooper()).post {
            connectionListener?.onStateChanged(state, message)
        }
    }
}